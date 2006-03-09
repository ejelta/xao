package XAO::DO::Wiki::Parser::Test;
use strict;
use warnings;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Wiki::Parser');

sub parse ($$) {
    my ($self,$template)=@_;

    my $wdlist=$self->SUPER::parse($template);
    dprint "Test::parse - got ".scalar(@$wdlist)." parsed records";

    foreach my $wd (@$wdlist) {
        next unless $wd->{'type'} eq 'curly';

        #...
    }

    return $wdlist;
}

1;
