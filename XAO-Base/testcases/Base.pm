package testcases::Base;
use strict;
use XAO::Utils;

use base qw(testcases::base);

sub test_set_root {
    my $self=shift;

    use XAO::Base;

    my $homedir=$XAO::Base::homedir;

    XAO::Base::set_root('/tmp');
    $self->assert($XAO::Base::homedir eq '/tmp',
                  "Error setting up root using set_root, got '$XAO::Base::homedir' (1)");

    $self->assert($XAO::Base::projectsdir eq '/tmp/projects',
                  "Error setting up root using set_root, got '$XAO::Base::projectsdir' (2)");

    XAO::Base::set_root($homedir);
    $self->assert($XAO::Base::homedir eq $homedir,
                  "Error setting up root using set_root, got '$XAO::Base::homedir' (3)");
}

sub test_import {
    my $self=shift;

    use XAO::Base qw($homedir $projectsdir);

    $self->assert(defined $homedir,
                  "Imported homedir is not defined");

    $self->assert(($homedir =~ /testcases\/testroot/) ? 1 : 0,
                  "Imported homedir is wrong");
}

1;
