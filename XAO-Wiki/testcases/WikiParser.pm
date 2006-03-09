package testcases::WikiParser;
use strict;
use XAO::Utils;
use XAO::Objects;
use Data::Dumper;

use base qw(testcases::base);

sub run_tests ($$$);

###############################################################################

sub test_override {
    my $self=shift;

    my $wiki=XAO::Objects->new(objname => 'Wiki::Parser::Test');
    $self->assert($wiki->isa('XAO::DO::Wiki::Parser'),
                  "Expected Wiki::Parser::Test to be based on Wiki::Parser");
}

###############################################################################

sub test_isbndb_original {
    my $self=shift;

    my $wiki=XAO::Objects->new(objname => 'Wiki::Parser');
    $self->assert($wiki->isa('XAO::DO::Wiki::Parser'),
                  "Expected Wiki::Parser::Test to be based on Wiki::Parser");

    my %tests=(
        t001        => {
            template    => "blah\n==some header==\nafter",
            expect      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t002        => {
            template    => "blah\n==  some header  ==\nafter",
            expect      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t003        => {
            template    => "blah\n===some header==\nafter",
            expect_not      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t004        => {
            template    => "blah\n==some header== xxx\nafter",
            expect_not      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t010        => {
            template    => "blah\n===    some   subheader===  \nafter",
            expect      => [
                {   type        => 'header',
                    level       => 3,
                    content     => 'some   subheader',
                },
            ],
        },
        t011        => {
            template    => "blah\nxxx ===    some   subheader===  \nafter",
            expect_not      => [
                {   type        => 'subheader',
                    content     => 'some   subheader',
                },
            ],
        },
    );

    $self->run_tests($wiki,\%tests);
}

###############################################################################

sub test_parse {
    my $self=shift;

    eval 'use Data::Compare';
    if($@) {
        print STDERR "\n" .
                     "Perl extension Data::Compare is not available,\n" .
                     "skipping XAO::PageSupport::parse tests\n";
        return;
    }

    my %matrix=(
        '' => [
        ],
        '0' => [
            {   type    =>  'text',
                content => "<p>0\n</p>\n",
            },
        ],
        '==         Head00   ==' => [
            {   type    => 'header',
                level   =>  '2',
                content =>  'Head00',
            },
            {   type    =>  'text',
                content => "\n",
            },
        ],
        "Hello!\n====     {{foo}}    Head00   ======" => [
            {   type    => 'text',
                content =>  "<p>Hello!\n</p>\n",
            },
            {   type    => 'header',
                level   =>  '4',
                content =>  '{{foo}}    Head00',
            },
            {   type    => 'text',
                content =>  "==\n",
            },
        ],
        "Hello!==== {{ foo | bar }} Head00 ======" => [
            {   type    => 'text',
                content =>  "<p>Hello!==== ",
            },
            {   type    => 'curly',
                content =>  'foo | bar',
            },
            {   type    => 'text',
                content =>  " Head00 ======\n</p>\n",
            },
        ],
        "Hello!==== [[ foo | bar ]] '''''bolditalic''bold'''''italic'' xx" => [
            {   type    => 'text',
                content =>  "<p>Hello!==== ",
            },
            {   type    => 'link',
                content =>  'foo | bar',
            },
            {   type    => 'text',
                content =>  " <b><i>bolditalic</i>bold</b><i>italic</i> xx\n</p>\n",
            },
        ],
        "Is it IsBn 123-123-55 ?" => [
            {   type    => 'text',
                content =>  "<p>Is it ",
            },
            {   type    => 'isbn',
                content =>  '12312355',
            },
            {   type    => 'text',
                content =>  " ?\n</p>\n",
            },
        ],
        "Some text is <b>bold but not <b>bolder</b></b>" => [
            {   type    => 'text',
                content =>  "<p>Some text is <b>bold but not bolder</b>\n</p>\n",
            },
        ],
        "Stray </i> or </b> will be deleted" => [
            {   type    => 'text',
                content =>  "<p>Stray  or  will be deleted\n</p>\n",
            },
        ],
        "Simple '''bold'''" => [
            {   type    => 'text',
                content =>  "<p>Simple <b>bold</b>\n</p>\n",
            },
        ],
        "And ''italic''" => [
            {   type    => 'text',
                content =>  "<p>And <i>italic</i>\n</p>\n",
            },
        ],
        "Bang!\n--- Tearline is outside of paragraph" => [
            {   type    => 'text',
                content =>  "<p>Bang!\n</p>\n<hr /> Tearline is outside of paragraph\n",
            },
        ],
        "Paragraph\n\nbreak" => [
            {   type    => 'text',
                content =>  "<p>Paragraph\n</p>\n<p>break\n</p>\n",
            },
        ],
        " nowrap block" => [
            {   type    => 'text',
                content =>  "<pre>nowrap block\n</pre>\n",
            },
        ],
        "zz\n; term : definition" => [
            {   type    => 'text',
                content =>  "<p>zz\n</p>\n<dl><dt> term </dt><dd> definition</dd></dl>\n",
            },
        ],
        "zz\n: indented" => [
            {   type    => 'text',
                content =>  "<p>zz\n</p>\n<dl><dd> indented</dd></dl>\n",
            },
        ],
        "## Numbered list" => [
            {   type    => 'text',
                content =>  "<ol><li><ol><li> Numbered list\n</li></ol>\n</li></ol>\n",
            },
        ],
        "* Unnumbered list\n* 2-nd item" => [
            {   type    => 'text',
                content =>  "<ul><li> Unnumbered list\n</li><li> 2-nd item\n</li></ul>\n",
            },
        ],
        "And <nowiki>'''Nothing''' {{translated}} include <this></nowiki>!" => [
            {   type    => 'text',
                content =>  "<p>And ",
            },
            {   type    => 'rawtext',
                content =>  "'''Nothing''' {{translated}} include <this>",
            },
            {   type    => 'text',
                content =>  "!\n</p>\n",
            },
        ],
        "Comment can.<!-- hide \n\n some text -->.." => [
            {   type    => 'text',
                content =>  "<p>Comment can...\n</p>\n",
            },
        ],
        "Break <br somethingcrazy> work" => [
            {   type    => 'text',
                content =>  "<p>Break <br /> work\n</p>\n",
            },
        ],
        "Center tags <center>aa\nbb\ncc</center> is ok" => [
            {   type    => 'text',
                content =>  "<p>Center tags <center>aa\nbb\ncc</center> is ok\n</p>\n",
            },
        ],
        "In common tags like <abc> is forbidden" => [
            {   type    => 'text',
                content =>  "<p>In common tags like &lt;abc&gt; is forbidden\n</p>\n",
            },
        ],
        
    );

    my $wiki=XAO::Objects->new(objname => 'Wiki::Parser');
    foreach my $template (keys %matrix) {
        my $parsed=$wiki->parse($template);
        my $expect=$matrix{$template};
        my $rc=ref($expect) ? Compare($expect,$parsed) : !ref($parsed);
        $rc ||
            print "========== Expect:",Dumper($expect),
                   "========== Got:",Dumper($parsed);
        $self->assert($rc,
                      "Wrong result for '$template'");
    }
}

###############################################################################

sub run_tests ($$$) {
    my ($self,$wiki,$tests)=@_;

    ##
    # For each test checking that we get _at least_ the blocks listed in
    # 'expect' in the same order. There may be other blocks in parser
    # response too.
    #
    foreach my $tid (sort keys %$tests) {
        my $tdata=$tests->{$tid};
        my $got=$wiki->parse($tdata->{'template'});
        my $got_pos=0;
        my $expect=$tdata->{'expect'} || [ ];
        for(my $i=0; $i<@$expect; ++$i) {
            my $eblock=$expect->[$i];
            my $found;
            for(my $j=$got_pos; $j<@$got; ++$j) {
                $found=1;
                foreach my $k (keys %$eblock) {
                    if(!defined $got->[$j]->{$k} || $got->[$j]->{$k} ne $eblock->{$k}) {
                        $found=0;
                        last;
                    }
                }
                if($found) {
                    $got_pos=$j;
                    last;
                }
            }
            if(!$found) {
                print STDERR Dumper($got);
                $self->assert($found,
                              "Can't find expected block (#=$i, type='$eblock->{'type'}', content='$eblock->{'content'}') for test $tid");
            }
        }

        my $exnot=$tdata->{'expect_not'} || [ ];
        for(my $i=0; $i<@$exnot; ++$i) {
            my $eblock=$exnot->[$i];
            my $found;
            for(my $j=0; $j<@$got; ++$j) {
                $found=1;
                foreach my $k (keys %$eblock) {
                    if(!defined $got->[$j]->{$k} || $got->[$j]->{$k} ne $eblock->{$k}) {
                        $found=0;
                        last;
                    }
                }
                if($found) {
                    print STDERR Dumper($got);
                    $self->assert(!$found,
                                  "Found unexpected block (#=$i, type='$eblock->{'type'}', content='$eblock->{'content'}') for test $tid");
                }
            }
        }
    }
}

###############################################################################

1;
