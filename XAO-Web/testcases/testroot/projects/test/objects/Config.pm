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

#    my $fsconfig=XAO::Objects->new(objname => 'FS::Config',
#                                   odb_dsn => 'OS:MySQL_DBI:test_os',
#                                   odb_user => 'am',
#                                   odb_password => '');


    $self->embed(web => $webconfig,
                 hash => $hash);

#    $self->embed(fs => $fsconfig);
}

1;
