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

### use Data::Dumper;

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

    my ($coll,$coll_ids)=$self->get_collection($args);

    my $ignore_limit=$self->ignore_limit($args);

    ##
    # Getting keyword data
    #
    dprint "Analyzing data..";
    my %kw_data;
    my $total=scalar(@$coll_ids);
    my $count=0;
    foreach my $coll_id (@$coll_ids) {
        dprint "..$count/$total" if (++$count%5000)==0;
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
    $index_object->glue->transact_begin;
    my $data_list=$index_object->get('Data');
    my $nd=$data_list->get_new;
    my $ignore_list=$index_object->get('Ignore');
    my $ni=$ignore_list->get_new;

    my $now=time;
    $ni->put(create_time => $now);
    $nd->put(create_time => $now);

    my %o_prepare;
    my %o_finish;

    my @keywords=keys %{$kw_data{keywords}};
    $total=scalar(@keywords);
    $count=0;
    foreach my $kw (keys %{$kw_data{keywords}}) {
        my $kwd=$kw_data{keywords}->{$kw};

        dprint "..$count/$total" if (++$count%5000)==0;

        my $kwmd5=md5_base64($kw);
        $kwmd5=~s/\W/_/g;

        if($kw_data{ignore}->{$kw}) {
            #dprint "Ignoring $kw ($kwmd5)";
            $ni->put(
                keyword => $kw,
                count   => $kw_data{counts}->{$kw},
            );
            $ignore_list->put($kwmd5 => $ni);
            next;
        }

        #dprint "Storing $kw ($kwmd5)";

        my $o_hash=$self->get_orderings;

        foreach my $o_name (keys %$o_hash) {
            if(!exists($o_prepare{$o_name})) {
                $o_prepare{$o_name}=$o_hash->{$o_name}->{sortprepare};
                $o_finish{$o_name}=$o_hash->{$o_name}->{sortfinish};

                if($o_prepare{$o_name}) {
                    &{$o_prepare{$o_name}}($self,$index_object,\%kw_data);
                }
            }

            my $o_sub=$o_hash->{$o_name}->{sortsub};

            my $o_seq=$o_hash->{$o_name}->{seq} ||
                throw $self "update - no ordering sequence number for '$o_name'";

            my $iddata='';
            my $posdata='';

            ##
            # Posdata format
            #
            # |UID|FN|POS|POS|POS|0|FN|POS|POS|0|0|UID|FN|POS|
            #
            foreach my $id (sort { &{$o_sub}(\%kw_data,$a,$b) } keys %$kwd) {
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

            $nd->put(
                "id_$o_seq"    => $iddata,
                "idpos_$o_seq" => $posdata,
            );
        }

        $nd->put(
            keyword         => $kw,
            count           => $kw_data{counts}->{$kw},
        );

        $data_list->put($kwmd5 => $nd);
    }

    ##
    # Finishing sorting (freeing memory and so on)
    #
    foreach my $o_name (keys %o_finish) {
        next unless $o_finish{$o_name};
        &{$o_finish{$o_name}}($self,$index_object,\%kw_data);
    }

    ##
    # Deleting outdated records
    #
    dprint "Deleting older records..";
    my $sr=$data_list->search('create_time','ne',$now);
    foreach my $id (@$sr) {
        $data_list->delete($id);
    }
    $sr=$ignore_list->search('create_time','ne',$now);
    foreach my $id (@$sr) {
        $ignore_list->delete($id);
    }

    ##
    # Committing changes into the database
    #
    dprint "Done";
    $index_object->glue->transact_commit;
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
1;
