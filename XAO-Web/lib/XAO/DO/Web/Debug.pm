=head1 NAME

XAO::DO::Web::Debug - debug helper object

=head1 SYNOPSIS

 <%Debug text="Got here :)"%>

 <%Debug set="show-path"%>
 <%Page path="/bits/some-complex-template-that-fails"%>
 <%Debug clear="show-path"%>

=head1 DESCRIPTION

Allows to to spit debug messages into error_log and/or turn on or off
various debug parameters in Page.

=cut

###############################################################################
package XAO::DO::Web::Debug;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Debug.pm,v 1.2 2002/02/04 07:58:45 am Exp $ =~ /(\d+\.\d+)/);

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    if($args->{set}) {
        my %set=map { $_ => 1 } split(/[,;\s]/,$args->{set});
        $self->debug_set(\%set);
        dprint "Debug set='",join(',',keys %set),"'";
    }

    if($args->{clear}) {
        my %set=map { $_ => 0 } split(/[,;\s]/,$args->{clear});
        $self->debug_set(\%set);
        dprint "Debug clear='",join(',',keys %set),"'";
    }

    if(defined($args->{text}) || defined($args->{template}) || $args->{path}) {
        my $text=$args->{text} ||
                 $self->object->expand($args);
        dprint $self->{objname}," - $text";
    }
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2001-2002 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.