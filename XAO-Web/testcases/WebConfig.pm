package testcases::WebConfig;
use strict;
use XAO::Projects;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $config=XAO::Projects::get_current_project();
    $config->clipboard->put('test' => 'foo');
    $self->assert($config->clipboard->get('test') eq 'foo',
                  "Clipboard does not work");

    $config->cleanup();
    $self->assert(!defined($config->clipboard->get('test')),
                  "Cleanup does not work");
}

1;
