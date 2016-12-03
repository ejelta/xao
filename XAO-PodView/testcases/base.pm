package testcases::base;
use strict;
use CGI;
use IO::File;
use XAO::Utils;
use XAO::Base;
use XAO::Web;
use XAO::Projects qw(:all);

use base qw(Test::Unit::TestCase);

sub set_up {
    my $self=shift;

    chomp(my $root=`pwd`);
    $root.='/testcases/testroot';
    symlink('../../templates',"$root/templates");
    XAO::Base::set_root($root);

    my $web=XAO::Web->new(sitename  => 'test');
    $self->{web}=$web;

    $web->config->put('base_url' => 'http://localhost');

    set_current_project('test');
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
