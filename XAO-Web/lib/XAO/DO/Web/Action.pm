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
($VERSION)=(q$Id: Action.pm,v 1.3 2002/02/06 21:52:07 am Exp $ =~ /(\d+\.\d+)/);

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

Copyright (c) 2000-2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
