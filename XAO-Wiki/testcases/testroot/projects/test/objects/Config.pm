package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::SimpleHash;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Config', baseobj => 1);

sub init {
    my $self=shift;

    $self->embedded('hash')->put(base_url => 'http://xao.com');

    my %d;
    open(F,'.config') ||
        throw XAO::E::DO::Config "init - no .config found, run 'perl Makefile.PL'";
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
    $@ && throw XAO::E::DO::Config "init - error in .config file: $@";

    my $fsconfig=XAO::Objects->new(
        objname => 'FS::Config',
        odb_args => {
            dsn             => $d{'test_dsn'},
            user            => $d{'test_user'},
            password        => $d{'test_password'},
            empty_database  => 'confirm',
        },
    );

    $self->embed(
        fs => $fsconfig,
    );
}

1;
