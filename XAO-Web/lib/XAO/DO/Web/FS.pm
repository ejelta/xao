=head1 NAME

XAO::DO::Web::FS - XAO::Web front end object for XAO::FS

=head1 SYNOPSIS

 <%FS uri="/Categories/123/description"%>

 <%FS mode="show-list"
      base.clipboard="cached-list"
      base.database="/Foo/test/Bars"
      fields="*"
      header.path="/bits/foo-list-header"
      path="/bits/foo-list-row"
 %>

=head1 DESCRIPTION

Web::FS allows web site developer to directly access XAO Foundation
Server from templates without implementing specific objects.

=head1 METHODS

FS provides a useful base for other displayable object that work with
XAO::FS data.

=over

=cut

###############################################################################
package XAO::DO::Web::FS;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::FS);
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
($VERSION)=(q$Id: FS.pm,v 1.3 2001/12/13 04:58:18 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item get_object (%)

Returns an object retrieved from either clipboard or the database.
Accepts the following arguments:

 base.clipboard     clipboard uri
 base.database      XAO::FS object uri
 uri                XAO::FS object URI relative to `base' object
                    or root if no base.* is given

If both base.clipboard and base.database are set then first attempt is
made to get object from the clipboard and then from the database. If the
object is retrieved from the database then it is stored in clipboard.
Next call with the same arguments will get the object from clipboard.

=cut

sub get_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $object;

    my $cb_base=$args->{'base.clipboard'};
    my $db_base=$args->{'base.database'};

    $object=$self->clipboard->get($cb_base) if $cb_base;
    !$object || ref($object) ||
        throw XAO::E::DO::Web::FS "get_object - garbage in clipboard at '$cb_base'";
    my $got_from_cb=$object;
    $object=$self->odb->fetch($db_base) if $db_base && !$object;

    if($cb_base) {
        $db_base || $object ||
            throw XAO::E::DO::Web::FS "get_object - no object in clipboard and" .
                                      " no base.database to retrieve it";

        ##
        # Caching object in clipboard if we have both base.clipboard and
        # base.database.
        #
        if($object && !$got_from_cb) {
            $self->clipboard->put($cb_base => $object);
        }
    }

    my $uri=$args->{uri};
    if($object && $uri && $uri !~ /^\//) {
        
        ##
        # XXX - This should be done in FS
        #
        foreach my $name (split(/\/+/,$uri)) {
            $object=$object->get($name);
        }
    }
    elsif(defined($uri) && length($uri)) {
        $object=$self->odb->fetch($uri);
    }

    $cb_base || $db_base || $uri ||
        throw XAO::E::DO::Web::FS "get_object - at least one location parameter must present";

    $object;
}

###############################################################################

=back

Here is the list of accepted 'mode' arguments and corresponding method
names. The default mode is 'show-property'.

=over

=cut

###############################################################################

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'show-property';

    if($mode eq 'delete-property') {
        $self->delete_property($args);
    }
    elsif($mode eq 'show-hash') {
        $self->show_hash($args);
    }
    elsif($mode eq 'show-list') {
        $self->show_list($args);
    }
    elsif($mode eq 'show-property') {
        $self->show_property($args);
    }
    else {
        throw XAO::E::DO::Web::FS "check_mode - unknown mode '$mode'";
    }
}

###############################################################################

=item delete-property => delete_property (%)

Deletes an object or property pointed to by `name' argument.

Example of deleting an entry from Addresses list by ID:

 <%FS
   mode="delete-property"
   base.clipboard="/IdentifyUser/customer/object"
   uri="Addresses"
   name="<%ID/f%>"
 %>

=cut

sub delete_property ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{name} ||
        throw XAO::E::DO::Web::FS "delete_property - no 'name'";
    $self->odb->_check_name($name) ||
        throw XAO::E::DO::Web::FS "delete_property - bad name '$name'";

    my $object=$self->get_object($args);

    $object->delete($name);
}

###############################################################################

=item show-hash => show_hash (%)

Displays a XAO::FS hash derived object. Object location is the same as
described in get_object() method. Additional arguments are:

 fields             comma or space separated list of fields that are
                    to be retrieved from each object in the list and
                    passed to the template. Field names are converted
                    to all uppercase when passed to template. For
                    convenience '*' means to pass all
                    property names (lists be passed as empty strings).
 path               path that is displayed for each element of the list

=cut

sub show_hash ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $hash=$self->get_object($args);

    my @fields;
    if($args->{fields}) {
        if($args->{fields} eq '*') {
            @fields=$hash->keys;
        }
        else {
            @fields=split(/\W+/,$args->{fields});
            shift @fields unless length($fields[0]);
        }
    }

    my %data=(
        path        => $args->{path},
        ID          => $hash->container_key,
    );
    if(@fields) {
        my %t;
        @t{@fields}=$hash->get(@fields);
        foreach my $fn (@fields) {
            $data{uc($fn)}=defined($t{$fn}) ? $t{$fn} : '';
        }
    }
    $self->object->display(\%data);
}

###############################################################################

=item show-list => show_list (%)

Displays an index for XAO::FS list. List location is the same as
described in get_object() method. Additional arguments are:

 fields             comma or space separated list of fields that are
                    to be retrieved from each object in the list and
                    passed to the template. Field names are converted
                    to all uppercase when passed to template. For
                    convenience '*' means to pass all
                    property names (lists be passed as empty strings).
 header.path        header template path
 path               path that is displayed for each element of the list
 footer.path        footer template path

Show_list() supplies 'NUMBER' argument to header and footer containing
the number of elements in the list.

At least 'ID' and 'NUMBER' are supplied to the element template.
Additional arguments depend on 'field' content.

=cut

sub show_list ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $list=$self->get_object($args);
    $list->objname eq 'FS::List' ||
        throw XAO::E::DO::Web::FS "show_list - not a list";

    my @keys=$list->keys;
    my @fields;
    if($args->{fields}) {
        if($args->{fields} eq '*') {
            @fields=$list->get_new->keys;
        }
        else {
            @fields=split(/\W+/,$args->{fields});
            shift @fields unless length($fields[0]);
        }
    }

    my $page=$self->object;
    $page->display(
        path    => $args->{'header.path'},
        NUMBER  => scalar(@keys),
    ) if $args->{'header.path'};

    foreach my $id (@keys) {
        my %data=(
            path        => $args->{path},
            ID          => $id,
            NUMBER      => scalar(@keys),
        );
        if(@fields) {
            my %t;
            @t{@fields}=$list->get($id)->get(@fields);
            foreach my $fn (@fields) {
                $data{uc($fn)}=defined($t{$fn}) ? $t{$fn} : '';
            }
        }
        $page->display(\%data);
    }

    $page->display(
        path    => $args->{'footer.path'},
        NUMBER  => scalar(@keys),
    ) if $args->{'footer.path'};
}

###############################################################################

=item show-property => show_property (%)

Displays a property of the given object. Does not use any templates,
just displays the property using textout(). Example:

 <%FS uri="/project"%>

=cut

sub show_property ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $value=$self->get_object($args);
    $value=$args->{default} unless defined $value;
    $value='' unless defined $value;

    $self->textout($value);
}

###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2001 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
