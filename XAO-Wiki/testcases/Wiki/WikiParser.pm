package testcases::Wiki::WikiParser;
use strict;
use XAO::Utils;
use XAO::Objects;
use base qw(XAO::testcases::Web::base);

use Data::Dumper;

###############################################################################

# Low level parser tests for XAO::WikiParser

sub test_parse {
    my $self=shift;

    eval 'use Data::Compare';
    if($@) {
        print STDERR "\n" .
                     "Perl extension Data::Compare is not available,\n" .
                     "skipping XAO::PageSupport::parse tests\n";
        return;
    }

    eval 'use XAO::WikiParser';
    $self->assert(!$@,
           "Failed to load XAO::WikiParser ($@)");

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
                content => '| bar',
                opcode  => 'foo',
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
        "Paragraph\r\n\r\nbreak" => [
            {   type    => 'text',
                content =>  "<p>Paragraph\n</p>\n<p>break\n</p>\n",
            },
        ],
        "Paragraph\n\r\n\rbreak" => [
            {   type    => 'text',
                content =>  "<p>Paragraph\n</p>\n<p>break\n</p>\n",
            },
        ],
        "Paragraph\r\rbreak" => [
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
        # TODO: see http://ejelta.updatelog.com/projects/469520/todos/list/976132
        #"Some [[multi-line\n|link\n]] text." => [
        #    {   type    => 'text',
        #        content => '<p>Some ',
        #    },
        #    {   type    => 'link',
        #        content => "multi-line\n|link",
        #    },
        #    {   type    => 'text',
        #        content => " text.</p>\n",
        #    }
        #],
    );

    foreach my $template (keys %matrix) {
        my $parsed=XAO::WikiParser::parse($template);
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

1;
