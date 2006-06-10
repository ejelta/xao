package XAO::testcases::FS::charsets;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

###############################################################################

# as of 6/09/2006 we are supposed to get back perl Unicode strings for
# text fields in non-binary encodings.

sub test_native_utf8 {
    my $self=shift;

    eval 'use Encode';
    if($@) {
        print STDERR "Encode not available, support for charset is probably broken, not testing\n";
        return;
    }

    my $odb=$self->get_odb();

    my $global=$odb->fetch('/');
    $self->assert(ref($global), "Failure getting / reference");

    my %data=(
        latin1      => decode('latin1',"Latin1\xC4\xC5\xC6\xC7"),
        utf8        => "Smile - \x{263a} - omega - \x{03a9}",
    );
    if(Encode::resolve_alias('koi8r')) {
        $data{'koi8r'}="Russian - \x{0430}\x{0431}\x{0432}\x{0433}";
    }

    foreach my $charset (keys %data) {
        $global->add_placeholder(
            name        => 'text1',
            type        => 'text',
            maxlength   => 50,
            charset     => $charset,
        );
        $global->add_placeholder(
            name        => 'text2',
            type        => 'text',
            maxlength   => 50,
            charset     => $charset,
        );

        my $expect=$data{$charset};
        $global->put(text1 => $expect);
        my $got=$global->get('text1');

        $self->assert(Encode::is_utf8($got),
                      "Charset '$charset' - expected perl unicode ($got)");
        $self->assert($got eq $expect,
                      "Charset '$charset' - expected '$expect', got '$got'");

        $global->put(text1 => $expect, text2 => $expect);
        my ($got1,$got2)=$global->get(qw(text1 text2));

        $self->assert($got1 eq $got2,
                      "Charset '$charset' - expected equal results ($got1)<>($got2)");
        $self->assert(Encode::is_utf8($got2),
                      "Charset '$charset' - expected perl unicode ($got2)");
        $self->assert($got2 eq $expect,
                      "Charset '$charset' - expected '$expect', got '$got2'");

        $global->drop_placeholder('text1');
        $global->drop_placeholder('text2');
    }
}

###############################################################################

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

    my @charset_list=qw(latin1 utf8 binary);
    push(@charset_list,'koi8r') if Encode::resolve_alias('koi8r');

    #TODO: my @charset_list=$odb->charset_list;

    foreach my $charset (@charset_list) {
        $global->add_placeholder(
            name        => 'text',
            type        => 'text',
            maxlength   => 50,
            charset     => $charset,
        );

        my $text="Smile - \x{263a} - \xe1\xe2\xe3\xe4";
        my $expect=$charset eq 'binary' ? Encode::encode('utf8',$text)
                                        : Encode::encode($charset,$text);

        $global->put(text => $expect);
        my $got=$global->get('text');

        if($charset ne 'binary') {
            $got=Encode::encode($charset,$got);
        }

        $self->assert($got eq $expect,
                      "Charset '$charset' - expected '$expect', got '$got'");

        $global->drop_placeholder('text');
    }
}

###############################################################################
1;
