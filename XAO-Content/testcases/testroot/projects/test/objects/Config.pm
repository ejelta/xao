package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::SimpleHash;
use XAO::Objects;
use vars qw(@ISA);
@ISA=XAO::Objects->load(objname => 'Config', baseobj => 1);

sub init {
    my $self=shift;

    my $hash=XAO::SimpleHash->new();

    my $webconfig=XAO::Objects->new(objname => 'Web::Config');

    my %d;
    open(F,'.config') ||
        throw $self "init - no .config found, run 'perl Makefile.PL'";
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
    $@ && throw $self "init - error in .config file: $@";

    my $fsconfig=XAO::Objects->new(
        objname => 'FS::Config',
        odb_args => {
            dsn => $d{test_dsn},
            user => $d{test_user},
            password => $d{test_password},
            empty_database => 'confirm',
        },
    );

    $self->embed(
        web => $webconfig,
        fs => $fsconfig,
        hash => $hash,
    );
}

1;
