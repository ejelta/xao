package XAO::DO::CGI;
use strict;
use Encode;
use XAO::Utils;
use XAO::Objects;
use base qw(CGI);

###############################################################################

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    if($args->{'query'}) {
        return $proto->SUPER::new($args->{'query'});
    }
    elsif($args->{'no_cgi'}) {
        return $proto->SUPER::new('foo=bar');
    }
    else {
        return $proto->SUPER::new();
    }
}

###############################################################################

sub set_param_charset($$) {
    my ($self,$charset)=@_;

    my $old=$self->{'xao_param_charset'};
    $self->{'xao_param_charset'}=$charset;

    return $old;
}

###############################################################################

sub get_param_charset($$) {
    my $self=shift;
    return $self->{'xao_param_charset'};
}

###############################################################################

sub param ($;$) {
    my $self=shift;

    my $charset=$self->{'xao_param_charset'};

    return $self->SUPER::param(@_) unless $charset;

    if(wantarray) {
        return map {
            Encode::decode($charset,$_)
        } $self->SUPER::param(@_);
    }
    else {
        my $value=$self->SUPER::param(@_);
        return Encode::decode($charset,$value);
    }
}

###############################################################################
1;
