package XAO::DO::Wiki::Parser::Test;
use strict;
use warnings;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Wiki::Parser');

sub parse ($$) {
    my ($self,$template)=@_;

    my $wd=$self->SUPER::parse($template);
    dprint "Test::parse - got ".scalar(@$wd)." parsed records";

    return $wd;
}

1;
