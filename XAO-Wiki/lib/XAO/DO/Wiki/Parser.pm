package XAO::DO::Wiki::Parser;
use strict;
use XAO::WikiParser;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

###############################################################################

sub parse ($$) {
    my ($self,$template)=@_;
    return XAO::WikiParser::parse($template);
}

###############################################################################
1;
