# Test object for testcases/DOConfig.pm
#
package XAO::DO::LocalConf;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Test1');

sub embeddable_methods ($) {
    return 'fubar';
}

sub fubar ($$) {
    my $self=shift;
    'X' . $_[0] . 'X';
}

1;
