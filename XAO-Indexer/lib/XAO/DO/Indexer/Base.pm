=head1 NAME

XAO::DO::Indexer::Base -- base class for all indexers

=head1 SYNOPSIS

 package XAO::DO::Indexer::Foo;
 use strict;
 use XAO::Utils;
 use XAO::Objects;
 use base XAO::Objects->load(objname => 'Indexer::Base');

 sub analyze_object ($%) {
    my $self=shift;
    ....

=head1 DESCRIPTION

Provides indexer functionality that can (and for some methods MUST) be
overriden by objects derived from it.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::Indexer::Base;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use Digest::MD5 qw(md5_base64);
use base XAO::Objects->load(objname => 'Atom');

use Data::Dumper;

###############################################################################

use vars qw($VERSION);
$VERSION='1.0';

###############################################################################

=item analyze_text ($@)

Splits given text strings into keywords and stores them into kw_data
hash (first argument) using unique id from the second argument.

=cut

sub analyze_text ($$$@) {
    my $self=shift;
    my $kw_data=shift;
    my $unique_id=0+shift;

    $kw_data->{keywords}||={};
    my $kw_info=$kw_data->{keywords};

    my $field_num=0;
    foreach my $text (@_) {
        my $kwlist=$self->analyze_text_split($field_num+1,$text);
        my $pos=1;
        foreach my $kw (@$kwlist) {
            $kw_data->{count_uid}->{$unique_id}->{$kw}++;
            if(! exists $kw_data->{ignore}->{$kw}) {
                my $kwt=$kw_info->{lc($kw)}->{$unique_id};
                if(! $kwt->[$field_num]) {
                    $kw_info->{lc($kw)}->{$unique_id}->[$field_num]=[ $pos ];
                }
                elsif(scalar(@{$kwt->[$field_num]}) < 15) {
                    push(@{$kwt->[$field_num]},$pos);
                }
                else {
                    ### dprint "Only first 15 same keywords in a field get counted ($kw, $field_num, $pos)";
                }
            }
            $pos++;
        }
        $field_num++;
    }
}

###############################################################################

sub analyze_text_split ($$$) {
    my ($self,$field_num,$text)=@_;
    my @a=split(/\W+/,lc($text));
    shift @a if @a && !$a[0];
    return \@a;
}

###############################################################################

sub ignore_limit ($) {
    my $config=get_current_project();
    my $limit;
    if($config) {
        my $self=shift;
        my $args=get_args(\@_);
        if($args->{index_object}) {
            my $index_id=$args->{index_object}->container_key;
            $limit=$config->get("/indexer/$index_id/ignore_limit");
        }
        $limit||=$config->get('/indexer/default/ignore_limit');
    }

    return $limit || 500;
}

###############################################################################

sub init ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "init - no 'index_object'";

    dprint ref($self)."::init - XXX, nothing's in here yet....";
}

###############################################################################

sub search ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "search - no 'index_object'";

    my $str=$args->{search_string};
    $str='' unless defined $str;
    $str=~s/^\s*(.*?)\s*$/$1/sg;
    if(!length($str)) {
        dprint ref($self)."::search - empty search string";
        return [ ];
    }

    my $ordering=$args->{ordering} ||
        throw $self "search - no 'ordering'";
    my $ordering_seq=$self->get_orderings->{$ordering}->{seq} ||
        throw $self "search - no sequence in '$ordering' ordering";

    ##
    # Optional hash reference to be filled with statistics
    #
    my $rcdata=$args->{rcdata};
    $rcdata->{ignored_words}={ } if $rcdata;

    dprint "Searching for '$str' (ordering=$ordering, seq=$ordering_seq)";

    ##
    # We cache ignored words. Cache returns a hash reference with
    # ignored words.
    #
    my $i_cache=get_current_project()->cache(
        name        => 'indexer_ignored',
        coords      => [ 'index_id' ],
        expire      => 3,
        retrieve    => sub {
            my $index_list=shift;
            my $args=get_args(\@_);
            my $index_id=$args->{index_id};
            dprint "CACHE: retrieving ignored words for index $index_id";
            my $ign_list=$index_list->get($index_id)->get('Ignore');
            my %ignored=map {
                $ign_list->get($_)->get('keyword','count');
            } $ign_list->keys;
            return \%ignored;
        },
    );
    my $ignored=$i_cache->get($index_object->container_object, {
        index_id    => $index_object->container_key,
    });

    ##
    # Building multi-word sequences. If some words are in the
    # ignore-list we skip them, but assume that there is a word in
    # between in word sequences. For instance 'wag the dog' would become
    # { wag => 1, dog => 3 }, providing that 'the' is ignored.
    #
    my @mdata;
    $str=~s/"(.*?)"/push(@mdata,$1);" "/sge;
    my @multi;
    my @simple;
    foreach my $elt (@mdata) {
        my $s=$self->analyze_text_split(0,$elt);
        next unless @$s;
        if(@$s==1) {
            push(@simple,$s->[0]);
        }
        else {
            my @t=map {
                if(exists $ignored->{$_}) {
                    if($rcdata) {
                        $rcdata->{ignored_words}->{$_}=$ignored->{$_};
                    }
                    undef;
                }
                else {
                    $_;
                }
            } @$s;
            shift(@t) while @t && !defined($t[0]);
            pop(@t) while @t && !defined($t[$#t]);
            if(@t==1) {
                push(@simple,$t[0]);
            }
            else {
                push(@multi,\@t);
            }
        }
    }
    undef @mdata;

    ##
    # Simple words
    #
    push(@simple,map {
        if(exists $ignored->{$_}) {
            if($rcdata) {
                $rcdata->{ignored_words}->{$_}=$ignored->{$_};
            }
            ();
        }
        else {
            $_;
        }
    } @{$self->analyze_text_split(0,$str)});
    
    #dprint Dumper(\@multi),Dumper(\@simple);

    ##
    # First we search for multi-words sequences in the assumption that
    # they will provide smaller result sets or no results at all.
    #
    my @results;
    my $data_list=$index_object->get('Data');
    foreach my $marr (sort { scalar(@$b) <=> scalar(@$a) } @multi) {
        my $res=$self->search_multi($data_list,$ordering_seq,$marr);
        #dprint "Multi Results: ",Dumper($marr),Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Searching for simple words, position independent. Longer words first.
    #
    foreach my $kw (sort { length($b) <=> length($a) } @simple) {
        my $res=$self->search_simple($data_list,$ordering_seq,$kw);
        #dprint "Simple Results: '$kw' ",Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Joining all results together
    #
    my $base;
    ($base,@results)=sort { scalar(@$a) <=> scalar(@$b) } @results;
    my @cursors;
    my @final;
    BASE_ID:
    foreach my $id (@$base) {
        RESULT:
        for(my $i=0; $i<@results; $i++) {
            my $rdata=$results[$i];
            my $j=$cursors[$i] || 0;
            for(; $j<@$rdata; $j++) {
                if($id == $rdata->[$j]) {
                    $cursors[$i]=$j;
                    next RESULT;
                }
            }
            next BASE_ID;
        }
        push(@final,$id);
    }

    return \@final;
}

###############################################################################

sub search_multi ($$$$) {
    my ($self,$data_list,$oseq,$marr)=@_;

    ##
    # Converting array into a hash for easier access
    #
    my $i=0;
    my %mhash=map { $i++; defined($_) ? ($i => $_) : () } @$marr;

    ##
    # Getting results. On null results exit immediately.
    #
    my %reshash;
    my $short_data;
    my $short_wnum;
    foreach my $wnum (sort { length($mhash{$b}) <=> length($mhash{$a}) } keys %mhash) {
        my $kw=$mhash{$wnum};
        my $sr=$data_list->search('keyword','eq',$kw);
        return [ ] unless @$sr;
        my $posdata=$data_list->get($sr->[0])->get("idpos_$oseq");
        my $posdec=$self->decode_posdata($posdata);
        if(!$short_data || scalar(@$short_data)>scalar(@$posdec)) {
            $short_data=$posdec;
            $short_wnum=$wnum;
        }
        $reshash{$wnum}=$posdec;
    }

    ##
    # Joining results using word position data
    #
    my %cursors;
    my @final;

    SHORT_ID:
    foreach my $short_iddata (@$short_data) {
        my ($short_id,$short_posdata)=@$short_iddata;

        ##
        # First we find IDs where all words at least exist in some
        # positions
        #
        my %found;
        foreach my $wnum (keys %reshash) {
            next if $wnum == $short_wnum;
            my $data=$reshash{$wnum};

            my ($id,$posdata);
            my $i=$cursors{$wnum} || 0;
            for(; $i<@$data; $i++) {
                ($id,$posdata)=@{$data->[$i]};
                last if $id == $short_id;
            }
            if($i>=@$data) {
                next SHORT_ID;
            }
            $cursors{$wnum}=$i+1;
            $found{$wnum}=$posdata;
        }

        ##
        # Now, we check if there are any correct sequences of these
        # words in the same source field.
        #
        # Finding a field that is present in all found references.
        #
        SHORT_FNUM:
        foreach my $fnum (keys %$short_posdata) {
            my $short_fdata=$short_posdata->{$fnum};

            my %fdhash;
            foreach my $wnum (keys %found) {
                my $posdata=$found{$wnum};
                my $fdata=$posdata->{$fnum};
                next SHORT_FNUM unless $fdata;
                $fdhash{$wnum}=$fdata;
            }

            SHORT_POS:
            foreach my $short_pos (@$short_fdata) {
                foreach my $wnum (keys %fdhash) {
                    my $reqpos=$short_pos+$wnum-$short_wnum;
                    next SHORT_POS if $reqpos<=0;
                    if(! grep { $_ == $reqpos } @{$fdhash{$wnum}}) {
                        next SHORT_POS;
                    }
                }
                push(@final,$short_id);
                next SHORT_ID;
            }
        }
    }

    return \@final;
}

###############################################################################

sub search_simple ($$$$) {
    my ($self,$data_list,$oseq,$keyword)=@_;

    my $sr=$data_list->search('keyword','eq',$keyword);
    return [ ] unless @$sr;

    my $iddata=$data_list->get($sr->[0])->get("id_$oseq");
    return [ unpack('w*',$iddata) ];
}

###############################################################################

sub update ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "update - no 'index_object'";

    ##
    # For compatibility reasons we need to call it in scalar context.
    #
    my @carr=$self->get_collection($args);
    my $cinfo;
    if(@carr==2) {
        $cinfo={
            collection  => $carr[0],
            ids         => $carr[1],
        };
    }
    else {
        $cinfo=$carr[0];
    }

    ##
    # Maximum number of matches for a word for it to be completely
    # ignored.
    #
    my $ignore_limit=$self->ignore_limit($args);

    ##
    # If that's a partial update and we don't have any IDs to update
    # we return immediately. Otherwise proceed even with empty set to
    # remove records from the index.
    #
    my $is_partial=$cinfo->{partial};
    my $coll_ids=$cinfo->{ids};
    my $coll_ids_total=scalar(@$coll_ids);
    if($is_partial && !$coll_ids_total) {
        return 0;
    }
    my $coll=$cinfo->{collection};

    ##
    # For partial indexes we pre-load ignored words. Otherwise, as the
    # data entry gets removed for ignored words, they will start from
    # zero and become non-ignored again.
    #
    # It is possible, that ignore_limit is different now, so we only
    # take in those that really exceed it.
    #
    my $ignore_list=$index_object->get('Ignore');
    my %kw_data;
    if($is_partial) {
        dprint "Loading ignored keywords for partial update";
        foreach my $kwmd5 ($ignore_list->keys) {
            my ($kw,$count)=$ignore_list->get($kwmd5)->get('keyword','count');
            if($count>$ignore_limit) {
                $kw_data{ignore}->{$kw}=1;
            }
        }
    }

    ##
    # Getting keyword data
    #
    dprint "Analyzing data..";
    my $count=0;
    foreach my $coll_id (@$coll_ids) {
        dprint "..$count/$coll_ids_total" if (++$count%1000)==0;
        my $coll_obj=$coll->get($coll_id);
        $self->analyze_object(
            collection      => $coll,
            object          => $coll_obj,
            object_id       => $coll_id,
            kw_data         => \%kw_data,
        );

        ##
        # Checking if it's time to ignore some keywords
        #
        my $count_uid=$kw_data{count_uid}->{$coll_id};
        foreach my $kw (keys %$count_uid) {
            if(++$kw_data{counts}->{$kw} > $ignore_limit) {
                $kw_data{ignore}->{$kw}=1;
            }
        }
        delete $kw_data{count_uid}->{$coll_id};
    }

    ##
    # Sorting and storing
    #
    dprint "Sorting and storing..";

=pod

I think the best idea is to create sorted lists of uniqueids for each
ordering (complete lists of ids, not partial). And then have a C routine
sort a subset using that master list. We should probably cache lists in
case another partial index update is coming our way.

-------

Another idea is to try and place the partial list of ids into the fully
sorted list. That is, for each keyword we retrieve existing IDs anyway,
so we sort our subset, take first -- take one in the middle and
determine if it's above or below. And so on. If we do that taking ids
from bottom and from top it should be relatively speedy.

Depends on the fact, that the ordering is fully determined -- there is
no "equal" state possible. Two pairs are always "greater" or "lesser",
and consistently so.

-------------

Second variant will probably be easier on the database AND allows to
remove ids that do not exist any more from the database.

On the other hand, second requires more storage to compare strings
and/or some complicated caching solution. May be the first way is
better. Going with it.

=cut

    my $now=time;

    $index_object->glue->transact_begin;
    my $data_list=$index_object->get('Data');
    my $ni=$ignore_list->get_new;
    $ni->put(create_time => $now);

    my %o_prepare;
    my %o_finish;

    ##
    # As the list can potentially be huge, we go one ordering at a time,
    # thus probably re-doing the same record -- which is fine for large
    # datasets we're dealing with.
    #
    my @keywords=keys %{$kw_data{keywords}};
    my $kw_total=scalar(@keywords);
    my $o_hash=$self->get_orderings;
    my $o_first=1;
    foreach my $o_name (keys %$o_hash) {
        my $o_data=$o_hash->{$o_name};
        my $o_seq=$o_data->{seq} ||
            throw $self "update - no ordering sequence number for '$o_name'";
        dprint ".ordering '$o_name' ($o_seq)";

        ##
        # Indexer implementation can provide optimized routine to get
        # pre-sorted list of all IDs in the collection. Using it if it's
        # available. Otherwise going through items manually using comparison
        # routine.
        #
        my $sorted_ids;
        if($o_data->{sortall}) {
            $sorted_ids=&{$o_data->{sortall}}($cinfo);
        }
        else {
            if($is_partial) {
                throw $self "update - manual sorting is not implemented for partial updates";
            }
            else {
                dprint "Manual sorting is slow, please provide 'sortall' routine";
                my $sortsub=$o_data->{sortsub};
                if($o_data->{sortprepare}) {
                    &{$o_data->{sortprepare}}($self,$index_object,\%kw_data);
                }
                $sorted_ids=[ sort { &$sortsub(\%kw_data,$a,$b) } @$coll_ids ];
                if($o_data->{sortfinish}) {
                    &{$o_data->{sortfinish}}($self,$index_object,\%kw_data);
                }
            }
        }
        my $sorted_ids_total=scalar(@$sorted_ids);

        $count=0;
        my $tstamp_start=time;
        foreach my $kw (keys %{$kw_data{keywords}}) {
            my $kwd=$kw_data{keywords}->{$kw};

            ##
            # Estimate of when we're going to finish.
            #
            if((++$count%1000)==0) {
                my $tstamp=time;
                my $tstamp_end=$tstamp_start+int(($tstamp-$tstamp_start)/$count * $kw_total);
                dprint "..$count/$kw_total (".localtime($tstamp)." - ".localtime($tstamp_end).")";
            }

            ##
            # Using md5 based IDs
            #
            my $kwmd5=md5_base64($kw);
            $kwmd5=~s/\W/_/g;
            my $data_obj;
            if($data_list->exists($kwmd5)) {
                $data_obj=$data_list->get($kwmd5);
            }
            else {
                $data_obj=$data_list->get_new;
                $data_obj->put(keyword => $kw);
            }

            ##
            # To be ignored? When we go through first ordering it might
            # only be known after we merge data below, otherwise we know
            # instantly.
            #
            if($kw_data{ignore}->{$kw}) {
                $ni->put(
                    keyword => $kw,
                    count   => $kw_data{counts}->{$kw},
                );
                $ignore_list->put($kwmd5 => $ni);
                $data_list->delete($kwmd5) if $data_obj->container_key;
                next;
            }

            ##
            # For partial - joining with the existing data, otherwise --
            # replacing.
            #
            if($is_partial && $data_obj->container_key) {
                my $posdata=$data_obj->get("idpos_$o_seq");
                if(length($posdata)) {
                    my $kw_count=$kw_data{counts}->{$kw};
                    my $kwd_new=merge_refs($kwd);
                    my @dstr=unpack('w*',$posdata);
                    my $i=0;
                    while($i<@dstr) {
                        my $id=$dstr[$i++];
                        last unless $id;
                        my @wd;
                        while($i<@dstr) {
                            my $fnum=$dstr[$i++];
                            last unless $fnum;
                            my @poslist;
                            while($i<@dstr) {
                                my $pos=$dstr[$i++];
                                last unless $pos;
                                push(@poslist,$pos);
                            }
                            $wd[$fnum-1]=\@poslist;
                        }
                        if(!$kwd_new->{$id}) {
                            $kwd_new->{$id}=\@wd;
                            ++$kw_count;
                        }
                    }

                    if($o_first) {
                        $kw_data{counts}->{$kw}=$kw_count;
                        if($kw_count > $ignore_limit) {
                            $kw_data{ignore}->{$kw}=$kw_count;
                            $ni->put(
                                keyword => $kw,
                                count   => $kw_count,
                            );
                            $ignore_list->put($kwmd5 => $ni);
                            $data_list->delete($kwmd5);
                            next;
                        }
                    }

                    $kwd=$kwd_new;
                }
            }

            ##
            # Preparing sorted list of IDs
            #
            my $kwids=fast_sort($sorted_ids,[ keys %$kwd ]);

            ##
            # Posdata format
            #
            # |UID|FN|POS|POS|POS|0|FN|POS|POS|0|0|UID|FN|POS|
            #
            my $iddata='';
            my $posdata='';
            foreach my $id (@$kwids) {
                $iddata.=pack('w',$id);

                my $field_num=0;
                $posdata.=pack('ww',0,0) if length($posdata);
                $posdata.=
                    pack('w',$id) .
                    join(pack('w',0),
                        map {
                            ++$field_num;
                            defined($_) ? (pack('w',$field_num) . pack('w*',@$_))
                                        : ()
                        } @{$kwd->{$id}}
                    );
            }

            ##
            # Storing
            #
            my %data_hash=(
                "id_$o_seq"     => $iddata,
                "idpos_$o_seq"  => $posdata,
            );
            if($o_first) {
                $data_hash{create_time}=$now;
                $data_hash{count}=$kw_data{counts}->{$kw};
            }
            $data_obj->put(\%data_hash);
            $data_list->put($kwmd5 => $data_obj) unless $data_obj->container_key;
        }
    }
    continue {
        $o_first=0;
    }

    ##
    # Deleting outdated records
    #
    dprint "Deleting older records..";
    if($is_partial) {
        dprint "TODO - no deletion implementation yet for partials!";
    }
    else {
        my $sr=$data_list->search('create_time','ne',$now);
        foreach my $id (@$sr) {
            $data_list->delete($id);
        }
        $sr=$ignore_list->search('create_time','ne',$now);
        foreach my $id (@$sr) {
            $ignore_list->delete($id);
        }
    }

    ##
    # If indexer can we ask it to close the data set we were working
    # on. Essential for partial updates, so that we know what to update
    # next time.
    #
    dprint "Finishing collection";
    $self->finish_collection($args,{
        collection_info => $cinfo,
    });

    ##
    # Committing changes into the database
    #
    dprint "Done";
    $index_object->glue->transact_commit;

    return $coll_ids_total;
}

###############################################################################

sub analyze_object ($%) {
    my $self=shift;
    throw $self "analyze_object - pure virtual method called";
}

###############################################################################

sub decode_posdata ($$) {
    my ($self,$posdata)=@_;

    my @dstr=unpack('w*',$posdata);

    my @d;
    my $i=0;
    while($i<@dstr) {
        my $id=$dstr[$i++];
        last unless $id;
        my %wd;
        while($i<@dstr) {
            my $fnum=$dstr[$i++];
            last unless $fnum;
            my @poslist;
            while($i<@dstr) {
                my $pos=$dstr[$i++];
                last unless $pos;
                push(@poslist,$pos);
            }
            $wd{$fnum}=\@poslist;
        }
        push(@d,[ $id, \%wd ]);
    }

    return \@d;
}


###############################################################################

sub get_collection ($%) {
    my $self=shift;
    throw $self "get_collection - pure virtual method called";
}

###############################################################################

sub finish_collection ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $cinfo=$args->{collection_info} ||
        throw $self "finish_collection - no 'collection_info' given";

    ##
    # If it's partial and we're called -- we throw an exception to
    # indicate that this method must be overriden.
    #
    if($cinfo->{partial}) {
        throw $self "finish_collection - implementation required for partial collections";
    }
}

###############################################################################

sub fast_sort ($$) {
    my ($allids,$ids)=@_;

    my %t;
    @t{@$ids}=@$ids;

    return [ map { $t{$_} ? ($_) : () } @$allids ];
}

###############################################################################
1;
