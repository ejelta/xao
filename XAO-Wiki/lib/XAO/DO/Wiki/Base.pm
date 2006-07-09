package XAO::DO::Wiki::Base;
use strict;
use XAO::Utils qw(:args :debug :html);
use XAO::WikiParser;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

###############################################################################

=item build_structure ()

Creates the required data structure in /Wiki container. Should be called from
the project's build_structure like this:

 $self->helper('Wiki::Base')->build_structure;

If member IDs are not text/30, then it can be called like this:

 $self->helper('Wiki::Base')->build_structure(
    member_structure    => {
        type        => 'integer',
        minvalue    => 0,
        index       => 1,
    }
 );

=cut

sub build_structure ($@) {
    my $self=shift;
    $self->siteconfig->odb->fetch('/')->build_structure($self->data_structure(@_));
}


###############################################################################

=item data_structure ()

Returns the data structure block suitable for use in projects'
build_structure() method to build /Wiki structure.

=cut

sub data_structure ($) {
    my $self=shift;
    my $args=get_args(\@_);

    my $member_structure=$args->{'member_structure'} || {
        type        => 'text',
        maxlength   => 30,
        index       => 1,
    };

    my @wiki_content=(
        edit_time => {
            type        => 'integer',
            minvalue    => 0,
            index       => 1,
        },
        edit_member_id => $member_structure,
        edit_comment => {
            type        => 'text',
            charset     => 'utf8',
            maxlength   => $args->{'comment_maxlength'} || 200,
        },
        #
        content => {
            type        => 'text',
            charset     => 'utf8',
            maxlength   => $args->{'content_maxlength'} || 100000,
        },
    );
    
    return (
        Wiki => {
            type        => 'list',
            class       => 'Data::Wiki',
            key         => 'wiki_id',
            key_format  => '<$AUTOINC$>',
            structure   => {
                Revisions => {
                    type        => 'list',
                    class       => 'Data::WikiRevision',
                    key         => 'revision_id',
                    structure   => {
                        @wiki_content,
                    },
                },
                create_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 1,
                },
                create_member_id => $member_structure,
                #
                @wiki_content,
            },
        },
    );
}

###############################################################################

sub parse ($$) {
    my $self=shift;
    my $args=get_args(\@_);
    
    ##
    # Getting the content
    #
    my $content;
    if($args->{'content_clipboard_uri'}) {
        $content=$self->clipboard->get($args->{'content_clipboard_uri'});
    }
    elsif(defined $args->{'content'}) {
        $content=$args->{'content'};
    }
    else {
        $content=$self->retrieve($args,{
            fields  => $args->{'fields'} || [ 'content' ],
        });
    }

    ##
    # Core parser
    #
    my $elements=XAO::WikiParser::parse($content || '');

    ##
    # Adding a params block as the zeroth element to make life easier
    # for derived parsers.
    #
    $self->parse_params_hash(
        elements    => $elements,
    );

    ##
    # TODO: This should be integrated into the core parser
    #
    foreach my $elt (@$elements) {
        if($elt->{'type'} eq 'link') {
            my $content=$elt->{'content'} || '';
            my $link;
            my $label;
            if($content=~/^\s*(.*?)\s*(?:\|\s*(.*?)\s*)?$/s) {
                $link=$1;
                $label=$2 || $1;
            }
            else {  # should not happen
                $link=$label=$content;
            }
            $elt->{'link'}=$link;
            $elt->{'label'}=$label;
        }
    }

    ##
    # Default parser never returns any errors
    #
    return {
        error       => undef,
        errstr      => '',
        elements    => $elements,
    };
}

###############################################################################

sub parse_params_hash ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $elements=$args->{'elements'} || throw $self "parse_params_hash - no 'elements'";

    my $pblock=$elements->[0];
    if($pblock->{'type'} ne 'params') {
        $pblock={
            type        => 'params',
            params      => { },
        };
        unshift(@$elements,$pblock);
    }

    return $pblock->{'params'};
}

###############################################################################

=item parse_params_update

Merges given params into the zeroth block of the parsed results, which
is used for storing various special data. For instance a place puts
geographic coordinates in there to be later taken out and stored into the
database.

=cut

sub parse_params_update ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $phash=$self->parse_params_hash($args);

    my $params=$args->{'params'};

    return $phash unless $params;

    @$phash{keys %$params}=values %$params;

    return $phash;
}

###############################################################################

sub store ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    $self->siteconfig->odb->transact_active ||
        throw $self "wiki_edit_store - expected to run inside a transaction";

    my $member_id=$args->{'edit_member_id'} || throw $self "store - no edit_member_id";

    my $content=$args->{'content'} || '';
    my $edit_comment=$args->{'edit_comment'};

    my $wiki_id=$args->{'wiki_id'};

    my $wiki_list=$args->{'wiki_list'} || $self->siteconfig->odb->fetch('/Wiki');

    my $wiki_obj;
    my $edit_time=$args->{'edit_time'} || time;
    if($wiki_id) {
        $wiki_obj=$wiki_list->get($wiki_id);

        my ($old_content,$old_edit_comment,$old_edit_member_id,$old_edit_time)=
            $wiki_obj->get(qw(content edit_comment edit_member_id edit_time));

        if($content eq $old_content) {
            return $wiki_id;
        }

        my $rev_list=$wiki_obj->get('Revisions');
        my $rev_obj=$rev_list->get_new;
        $rev_obj->put(
            edit_time       => $old_edit_time,
            edit_member_id  => $old_edit_member_id,
            edit_comment    => $old_edit_comment,
            content         => $old_content,
        );
        $rev_list->put($rev_obj);
    }
    else {
        $wiki_obj=$wiki_list->get_new;
        $wiki_obj->put(
            create_time     => $edit_time,
            create_member_id=> $member_id,
        );
    }

    $wiki_obj->put(
        edit_time       => $edit_time,
        edit_member_id  => $member_id,
        edit_comment    => $edit_comment,
        content         => $content,
    );

    if(!$wiki_obj->container_key) {
        $wiki_id=$wiki_list->put($wiki_obj);
    }

    return $wiki_id;
}

###############################################################################

=item render_html

Renders wiki into HTML. Accepts either a pre-parsed 'elements' block or
'content' or 'wiki_id'/'revision_id'.

=cut

sub render_html ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $page=XAO::Objects->new(objname => 'Web::Page');

    ##
    # Parsing or getting pre-parsed elements
    #
    my $elements;
    if($args->{'elements_clipboard_uri'}) {
        $elements=$self->clipboard->get($args->{'elements_clipboard_uri'}) ||
            throw $self "render_html - nothing in the clipboard at '$args->{'elements_clipboard_uri'}'";
    }
    else {
        my $rc=$self->parse($args);
        if($rc->{'error'}) {
            return $page->expand(
                path        => '/bits/wiki/html/error-parsing',
                ERRSTR      => $rc->{'errstr'} || 'Wiki parsing error',
            );
        }
        $elements=$rc->{'elements'};
    }

    ##
    # If so asked passing along data parameters accumulated in parsing
    #
    if($args->{'params'}) {
        my $phash=$self->parse_params_hash(elements => $elements);
        @{$args->{'params'}}{map { uc } keys %$phash}=values %$phash;
    }

    ##
    # Rendering
    #
    my $html='';
    my $methods_map=$self->render_html_methods_map($args);
    foreach my $elt (@$elements) {
        my $type=$elt->{'type'} || 'unknown';
        my $method=$methods_map->{$type};
        if(!defined $method) {
            dprint "No method to render type='$type'";
            next;
        }
        elsif($method eq 'IGNORE') {
            next;
        }
        elsif(!ref($method)) {
            my $code=$self->can($method);
            if($code) {
                $html.=$code->($self,$args,{
                    element     => $elt,
                    page        => $page,
                });
            }
            else {
                dprint "No support for method '$method' in '".ref($self)." (required for type '$type')";
            }
            next;
        }
        elsif(ref($method) eq 'CODE') {
            $html.=$method->($self,$args,{
                element     => $elt,
                page        => $page,
            });
        }
        else {
            throw $self "render_html - don't know what to do with method '$method', type '$type'";
        }
    }

    return $html;
}

###############################################################################

sub render_html_methods_map ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    return {
        curly       => 'IGNORE',
        params      => 'IGNORE',
        #
        header      => 'render_html_header',
        link        => 'render_html_link',
        text        => 'render_html_text',
    };
}

###############################################################################

sub render_html_header ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $element=$args->{'element'} ||
        throw $self "render_html_header - no 'element'";

    my $level=$element->{'level'} ||
        throw $self "render_html_header - no 'level' in the element";

    return $args->{'page'}->expand($args,{
        path        => '/bits/wiki/html/header',
        LEVEL       => $level,
        TAG         => sprintf('H%u',$level),
        CONTENT     => $element->{'content'} || '',
    });
}

###############################################################################

=item render_html_link

Renders a link into HTML. By default supports only http:// links. The
typical override is structured like this:

 sub render_html_link ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $element=$args->{'element'} ||
        throw $self "render_html_link - no 'element'";

    my $link=$element->{'link'} || '';

    if($link =~ /some condition/) {
        ...
    }
    else {
        return $self->SUPER::render_html_link($args);
    }
 }

=cut

sub render_html_link ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $element=$args->{'element'} ||
        throw $self "render_html_link - no 'element'";

    my $link=$element->{'link'} || '';

    if($link=~/^https?:\/\//i) {
        return $args->{'page'}->expand($args,{
            path        => '/bits/wiki/html/link-http',
            URL         => $link,
            LABEL       => $element->{'label'},
        });
    }
    else {
        eprint ref($self)."render_html_link - unsupported link ($link)";
        return $args->{'page'}->expand($args,{
            path        => '/bits/wiki/html/link-unsupported',
            URL         => $link,
            LABEL       => $element->{'label'},
        });
    }
}

###############################################################################

sub render_html_text ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $element=$args->{'element'} ||
        throw $self "render_html_header - no 'element'";

    return $element->{'content'};
}

###############################################################################

=item retrieve

Retrieves data from the existing Wiki, either main record or a specific
revision if a revision_id is given. If fields array ref is given then
returns a list of fields in the specified order.

=cut

sub retrieve ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $wiki_id=$args->{'wiki_id'} ||
        throw $self "retrieve - no wiki_id given";

    my $wiki_list=$args->{'wiki_list'} || $self->siteconfig->odb->fetch('/Wiki');

    my $wiki_obj=$wiki_list->get($wiki_id);

    my $revision_id=$args->{'revision_id'};
    if($revision_id) {
        $wiki_obj=$wiki_obj->get('Revisions')->get($revision_id);
    }

    my $fields=$args->{'fields'} || [ 'content' ];
    if(!ref($fields)) {
        if($fields eq '*') {
            $fields=[ qw(content edit_time edit_member_id edit_comment) ];
        }
        else {
            $fields=[ split(/\W/,$fields) ];
        }
    }

    my @values=$wiki_obj->get(@$fields);

    if(my $params=$args->{'params'}) {
        $params->{'WIKI_ID'}=$wiki_id;
        $params->{'REVISION_ID'}=$revision_id || '';
        @$params{map { uc } @$fields}=@values;
    }

    return wantarray ? @values : $values[0];
}

###############################################################################

=item revisions

Returns an array or arrays with the data about revisions. Takes a
wiki_id and an optional list of fields (default is to return revision_id
only). An optional 'condition' and 'options' arguments are passed into
the search if given.

=cut

sub revisions ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $wiki_id=$args->{'wiki_id'} ||
        throw $self "revisions - no wiki_id given";

    my $wiki_list=$args->{'wiki_list'} || $self->siteconfig->odb->fetch('/Wiki');

    my $rev_list=$wiki_list->get($wiki_id)->get('Revisions');

    my $fields=$args->{'fields'} || [ 'revision_id' ];
    if(!ref($fields)) {
        $fields=[ split(/\W/,$fields) ];
    }

    return $rev_list->search(
        $args->{'condition'} ? (@{$args->{'condition'}}) : (),
        merge_refs($args->{'options'},{ result => $fields }),
    );
}

###############################################################################

=item clipboard ()

Convenience shortcut to site configuration's clipboard() method.

=cut

sub clipboard (@) {
    my $self=shift;
    $self->siteconfig->clipboard(@_);
}

###############################################################################

=item siteconfig ()

Convenience shortcut to the current site configuration.

=cut

sub siteconfig ($) {
    my $self=shift;
    return XAO::Projects::get_current_project();
}

###############################################################################
1;
