package testcases::base;
use strict;
use CGI;
use IO::File;
use XAO::Utils;
use XAO::Base;
use XAO::Objects;
use XAO::Projects qw(:all);

use base qw(Test::Unit::TestCase);

sub set_up {
    my $self=shift;

    chomp(my $root=`pwd`);
    $root.='/testcases/testroot';
    XAO::Base::set_root($root);

    my $config=XAO::Objects->new(objname => 'Config',
                                 sitename => 'test');
    create_project(name => 'test',
                   object => $config,
                   set_current => 1);
    $config->init();

    my $cgi=CGI->new('foo=bar&test=1');

    $config->embedded('web')->enable_special_access();
    $config->cgi($cgi);
    $config->embedded('web')->disable_special_access();

    push @INC,$root;
}

sub tear_down {
    my $self=shift;
    $self->get_stdout();
    drop_project('test');
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

sub catch_stdout ($) {
    my $self=shift;
    $self->assert(!$self->{tempfile},
                  "Already catching STDOUT");

    open(TEMPSTDOUT,">&STDOUT") || die;
    my $tempstdout=IO::File->new_from_fd(fileno(TEMPSTDOUT),"w") || die;
    $self->assert($tempstdout,
                  "Can't make a copy of STDOUT");
    $self->{tempstdout}=$tempstdout;

    $self->{tempfile}=IO::File->new_tmpfile();
    $self->assert($self->{tempfile},
                  "Can't create temporary file");

    open(STDOUT,'>&' . $self->{tempfile}->fileno);
}

sub get_stdout ($) {
    my $self=shift;

    my $file=$self->{tempfile};
    return undef unless $file;

    open(STDOUT,'>&' . $self->{tempstdout}->fileno);
    $self->{tempstdout}->close();

    $file->seek(0,0);
    my $text=join('',$file->getlines);
    $file->close;

    delete $self->{tempfile};
    delete $self->{tempstdout};

    return $text;
}

1;
