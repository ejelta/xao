=head1 NAME

XAO::DO::Web::Clipboard - clipboard value retrieval object.

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Clipboard object is based on Action object (see L<XAO::DO::Web::Action>)
and therefor what it does depends on the "mode" argument.

For each mode there is a separate method with usually very similar
name. The list below lists mode names and their method counterparts.

=over

=cut

###############################################################################
package XAO::DO::Web::Clipboard;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Clipboard);
use base XAO::Objects->load(objname => 'Web::Action');

sub check_mode ($$) {
    my $self = shift;
    my $args = get_args(\@_);
    my $mode = $args->{mode};

    if ($mode eq 'show') {
        $self->clipboard_show($args);
    }
    else {
        throw XAO::E::DO::Web::Clipboard "check_mode - unknown mode '$mode'";
    }
}

###############################################################################

=item 'show' => clipboard_show (%)

Displays clipboard parameter with the given "name". Example:

 <%Clipboard mode="show" name="username" default="aa@bb.com"%>

Would display whatever is set in the Clipboard for variable
"username" or "aa@bb.com" if it is not set.

=cut

sub clipboard_show ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $clipboard = $self->clipboard;
    $args->{name} ||
        throw XAO::E::DO::Web::Clipboard "clipboard_show - no 'name' given";

    my $value = $clipboard->get($args->{name});
    $value    = $args->{default} if !defined($value);

    $self->textout($value) if defined $value;
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>, Marcos Alves <alves@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
