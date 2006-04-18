package XAO::testcases::FS::charsets;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

sub test_charsets {
    my $self=shift;

    eval 'use Encode';
    if($@) {
        print STDERR "Encode not available, support for charset is probably broken, not testing\n";
        return;
    }

    my $odb=$self->get_odb();

    my $global=$odb->fetch('/');
    $self->assert(ref($global), "Failure getting / reference");

    my @charset_list=qw(binary utf8 latin1);
    #TODO: my @charset_list=$odb->charset_list;

    foreach my $charset (@charset_list) {
        $global->add_placeholder(
            name        => 'text',
            type        => 'text',
            maxlength   => 50,
            charset     => $charset,
        );

        my $text="Smile - \x{263a} - \x80\x81\x82\x83";
        $global->put(text => $text);
        my $got=$global->get('text');
        dprint 1111;
        my $expect=$charset eq 'binary' ? Encode::encode('utf8',$text) : Encode::encode($charset,$text);
        dprint "text='$text' got='$got' expect='$expect'";

        $global->drop_placeholder('text');
    }
}

1;
