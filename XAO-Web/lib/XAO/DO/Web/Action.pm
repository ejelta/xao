=head1 NAME

XAO::DO::Web::Action - base for mode-dependant displayable objects

=head1 SYNOPSIS

 package XAO::DO::Web::Fubar;
 use strict;
 use XAO::Objects;
 use XAO::Errors qw(XAO::DO::Web::Fubar);
 use base XAO::Objects->load(objname => 'Web::Action');

 sub check_mode ($$) {
     my $self=shift;
     my $args=get_args(\@_);
     my $mode=$args->{mode};
     if($mode eq "foo") {
         $self->foo($args);
     }
     elsif($mode eq "kick") {
         $self->kick($args);
     }
     else {
         $self->SUPER::check_mode($args);
     }
 }

=head1 DESCRIPTION

Very simple object with overridable check_mode method.
Simplifies implementation of objects with arguments like:

 <%Fubar mode="kick" target="ass"%>

Default check_mode() method does not have any functionality and always
simply throws an error with the content of 'mode':

 throw $self "check_mode - unknown mode ($mode)";

Remember that using "throw $self" you actually throw an error that
depends on the namespace of your object and therefor can be caught
separately if required.

=cut

###############################################################################
package XAO::DO::Web::Action;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Action.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);
    return $self->check_mode($args) if $self->can('check_mode');
    $self->SUPER::display($args);
}

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $mode=$args->{mode} || '<UNDEF>';
    throw $self "check_mode - unknown mode ($mode)";
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
