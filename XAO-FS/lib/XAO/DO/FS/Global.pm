=head1 NAME

XAO::DO::FS::Global - root node of objects tree

=head1 SYNOPSIS

 use XAO::Objects;

 my $global=XAO::Objects->new(objname => 'FS::Global');
 $global->connect($dbh);

=head1 DESCRIPTION

FS::Global is a XAO dynamicaly overridable object that serves as
a root node in objects tree. It is not recommended to override it for
specific site unless you're positive there is no way to avoid that and
you know enough about object server internalities.

=cut

###############################################################################
package XAO::DO::FS::Global;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Hash');

use vars qw($VERSION);
($VERSION)=(q$Id: Global.pm,v 1.3 2002/11/09 02:04:11 am Exp $ =~ /(\d+\.\d+)/);

sub new ($%) {
    my $class=shift;
    my $self=$class->SUPER::new(@_);
    $$self->{unique_id}=1;
    $$self->{detached}=0;
    $self;
}

###############################################################################
1;
__END__

=head1 AUTHORS

XAO, Inc. (c) 2001

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).
