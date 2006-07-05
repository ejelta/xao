package XAO::DO::Wiki::Foo;
use strict;
use warnings;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Wiki::Base');

###############################################################################

sub parse ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $rc=$self->SUPER::parse($args);

    return $rc if $rc->{'error'};

    my $data=$rc->{'data'};

    foreach my $wd (@$data) {
        if($wd->{'type' eq 'curly'} && $wd->{'opcode'} eq 'fubar') {
            $wd->{'type'}='fubar';
        }
    }

    return $data;
}

###############################################################################
1;
