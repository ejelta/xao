=head1 NAME

XAO::DO::Web::FS - XAO::Web front end object for XAO::FS

=head1 SYNOPSIS

<%FS uri="/Categories/123/description" path="/bits/cat-text"%>

=head1 DESCRIPTION

Web::FS allows web site developer to directly access XAO Foundation
Server from templates without implementing specific objects.

=cut

###############################################################################
package XAO::DO::Web::FS;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
($VERSION)=(q$Id: FS.pm,v 1.2 2001/12/10 05:16:15 am Exp $ =~ /(\d+\.\d+)/);

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'show-property';

    if($mode eq 'show-property') {
        $self->show_property($args);
    }
    else {
        $self->throw("check_mode - unknown mode '$mode'");
    }
}

sub show_property ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $uri=$args->{uri} ||
        $self->throw('property - no Foundation Server URI');

    my $value;

    my $cache;
    if($args->{cache}) {
        $cache=$self->siteconfig->get('fs_cache');
        if($cache) {
            if(exists $cache->{$uri}) {
                $value=$cache->{$uri};
            }
        } else {
            $self->siteconfig->put('fs_cache' => { });
        }
    }

    $value=$self->odb->fetch($uri) unless defined $value;
    $value=$args->{default} unless defined $value;
    $value='' unless defined $value;

    $cache->{$uri}=$value if $cache;

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
