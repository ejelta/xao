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

    my $elements=$rc->{'elements'};

    for(my $i=1; $i<@$elements; ++$i) {
        my $elt=$elements->[$i];
        if($elt->{'type'} eq 'curly' && $elt->{'opcode'} eq 'fubar') {
            $elt->{'type'}='fubar';
        }
        elsif($elt->{'type'} eq 'curly' && $elt->{'opcode'} eq 'last') {
            $self->parse_move_elt($elements,$i,-2);
        }
        elsif($elt->{'type'} eq 'curly' && $elt->{'opcode'} eq 'verylast') {
            $self->parse_move_elt($elements,$i,-1);
        }
        elsif($elt->{'type'} eq 'curly' && $elt->{'opcode'} eq 'first') {
            $self->parse_move_elt($elements,$i,0);
        }
    }

    $self->parse_move_finalize($elements);

    return $rc;
}

###############################################################################
1;
