package testcases::base;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(Test::Unit::TestCase);

sub set_up {
    my $self=shift;

    ##
    # Reading configuration
    #
    my %d;
    if(open(F,'.config')) {
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }
    $self->assert($d{test_dsn},
                  "No test configuration available (no .config)");

    $self->{odb} = XAO::Objects->new(
                       objname => 'FS::Glue',
                       dsn => $d{test_dsn},
                       user => $d{test_user},
                       password => $d{test_password},
                       empty_database => 'confirm',
                   );
    $self->assert($self->{odb}, "Can't connect to the FS database");

    $self->{odb_args}={
        dsn => $d{test_dsn},
        user => $d{test_user},
        password => $d{test_password},
    };

    my $global=$self->{odb}->fetch('/');
    $self->assert($global, "Can't fetch Global from FS database");

    my %global_structure=(
        Products => {
                type        => 'list',
                class       => 'Data::Product',
                key         => 'id',
            structure       => { 
                name => {
                    type        => 'text',
                    maxlength   => 50,
                },
                source_image_url=> {
                    type        => 'text',
                    maxlength   => 100,
                },
                dest_image_url  => {
                    type        => 'text',
                    maxlength   => 100,
                },
                source_thumbnail_url=> {
                    type        => 'text',
                    maxlength   => 100,
                },
                dest_thumbnail_url  => {
                    type        => 'text',
                    maxlength   => 100,
                },
            },
        }
    );

    $global->build_structure(\%global_structure);

    my $plist=$self->{odb}->fetch('/Products');
    $self->assert($plist, "Can't fetch /Products from FS database");

    my $product=$plist->get_new();
    $self->assert(ref($product), "Can't create new Product");
    
    $product->put(name => "Test product 1");
    $product->put(source_image_url => "http://apache.org/icons/apache_pb.gif");
    $product->put(dest_image_url => "");
    $plist->put(p1 => $product);

    mkdir('tmp');
    mkdir('tmp/cache');
    mkdir('tmp/cache/source');
    mkdir('tmp/cache/images');
    mkdir('tmp/cache/thumbnails');
}

sub tear_down {
    my $self=shift;
    $self->{odb}=undef;
}

sub get_odb {
    my $self=shift;
    my $odb=$self->{odb};
    $self->assert(defined($odb) && ref($odb), 'No object database handler');
    $odb;
}

sub timestamp ($$) {
    my $self=shift;
    time;
}

sub timediff ($$$) {
    my $self=shift;
    my $t1=shift;
    my $t2=shift;
    $t1-$t2;
}

1;
