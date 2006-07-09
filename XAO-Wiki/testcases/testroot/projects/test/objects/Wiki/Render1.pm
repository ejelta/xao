package XAO::DO::Wiki::Render1;
use strict;
use warnings;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Wiki::Base');

###############################################################################

sub render_html_methods_map ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    return merge_refs($self->SUPER::render_html_methods_map($args),{
        link        => sub { return '<LINK>' },
        curly       => 'render_html_curly',
        text        => 'IGNORE',
    });
}

###############################################################################

sub render_html_curly ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    $args->{'element'} ||
        throw $self "render_html_curly - no 'element'";

    ref($args->{'element'}) eq 'HASH' ||
        throw $self "render_html_curly - 'element' is not a hashref ($args->{'element'})";

    return '<CURLY>';
}

###############################################################################

sub render_html_header ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $element=$args->{'element'} ||
        throw $self "render_html_header - no 'element'";

    ref($element) eq 'HASH' ||
        throw $self "render_html_header - 'element' is not a hashref ($element)";

    my $level=$element->{'level'} ||
        throw $self "render_html_header - no level in the element";

    return '<HEADER-'.$level.'>';
}

###############################################################################
1;
