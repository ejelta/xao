package XAO::DO::Web::MyAction;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'foo';
    if($mode eq 'foo') {
        $self->textout('Got FOO');
    }
    else {
        $self->SUPER::check_mode($args);
    }
}

1;
