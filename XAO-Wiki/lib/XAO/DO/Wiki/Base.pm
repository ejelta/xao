package XAO::DO::Wiki::Base;
use strict;
use XAO::Utils;
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
    
    my $content;
    if(defined $args->{'content'}) {
        $content=$args->{'content'};
    }
    else {
        $content=$self->retrieve($args,{
            fields  => 'content',
        });
    }

    my $data=XAO::WikiParser::parse($content);

    return {
        error       => undef,
        errstr      => '',
        data        => $data,
    };
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

    if(my $revision_id=$args->{'revision_id'}) {
        $wiki_obj=$wiki_obj->get('Revisions')->get($revision_id);
    }

    my $fields=$args->{'fields'} || [ 'content' ];
    if(!ref($fields)) {
        $fields=[ split(/\W/,$fields) ];
    }

    return $wiki_obj->get(@$fields);
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
