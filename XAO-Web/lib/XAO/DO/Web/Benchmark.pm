=head1 NAME

XAO::DO::Web::Benchmark - benchmarking helper

=head1 SYNOPSIS

  <%Benchmark mode='enter' tag='main'%>
  ....
  <%Benchmark mode='leave' tag='main'%>
  ...
  <%Benchmark mode='stats' tag='main'
    dprint
    template={'Count: <$COUNT$> Total: <$TIME_TOTAL$> Avg: <$TIME_AVERAGE$>'}
  %>
  ...
  <%Benchmark mode='stats'
    header.template='<ul>'
    template=       '<li>Tag: <$TAG/h$> Avg: <$TIME_AVERAGE/h$></li>'
    footer.template='</ul>'
  %>

=head1 DESCRIPTION

Remembers timing at the given points during template processing and
reports on them later. The tag is required for 'enter' and 'leave'
modes.

System-wide benchmarking can also be controlled with 'system-start'
and 'system-stop' modes. With that all sub-templates are individually
benchmarked.  The tags are automatically build based on their 'path' or
'template' arguments.

Results can be retrieved using 'stats' mode. With a 'dprint' parameter
it will dump results using the dprint() call to be seen in the server
log typically. Given a template or a path the results can be included in
the rendered page.

=cut

###############################################################################
package XAO::DO::Web::Benchmark;
use warnings;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Web::Action');

###############################################################################

sub display_enter ($@) {
    my $self = shift;
    my $args = get_args(\@_);
    my $tag=$args->{'tag'} || throw $self "- no tag";
    $self->benchmark_enter('tag');
}

###############################################################################

sub display_leave ($@) {
    my $self = shift;
    my $args = get_args(\@_);
    my $tag=$args->{'tag'} || throw $self "- no tag";
    $self->benchmark_leave('tag');
}

###############################################################################

sub display_system_start ($) {
    my $self = shift;
    $self->benchmark_start();
}

###############################################################################

sub display_system_stop ($) {
    my $self = shift;
    $self->benchmark_stop();
}

###############################################################################

sub data_stats ($@) {
    my $self = shift;
    my $args = get_args(\@_);
    my $tag=$args->{'tag'};
    throw $self "- not implemented"
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2013 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
