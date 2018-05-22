package testcases::PodView::WebPodView;
use strict;
use XAO::Utils;

use base qw(testcases::PodView::base);

sub test_all {
    my $self=shift;

    $self->catch_stdout();
    $self->{web}->execute(path => '/test.html', cgi => CGI->new(''));
    my $text=$self->get_stdout();

    ### dprint "=====================\n$text\n=================";

    my $ok=<<'EOT';
<DIV><FONT SIZE="+2" FACE="Verdana,Arial,Helvetica">TEST</FONT><P>
<FONT SIZE="+1" FACE="Verdana,Arial,Helvetica">MISC TEST</FONT><P>
<p>some paragraph
on <strong>multiple</strong> lines
that includes <em>italic text</em> and a link: <a href="?module=IO::File">IO::File</a>.

</p>
<p>Code sample:</p>
<pre>
 # Like that
 #
 my $test=1;

 # Line after break
</pre>
<FONT SIZE="+1" FACE="Verdana,Arial,Helvetica">LIST TEST</FONT><P>
<p>Paragraph of text on the top.</p>
<DL>
<DT>aaaa
<DD>
<p>Item a is very strange.</p>
<UL>
<LI>
<p>fubar</p>
<OL>
<LI>
<p>one-one-one</p>
<LI>
<p>two-two-two</p>
</OL>
<p>That was enumerated list in bullet list in definitions list.</p>
<p>Another paragraph here with a <a href="http://xao.com/">link</a>.</p>
<p>And yet another one.</p>
<LI>
<p>buraf</p>
</UL>
<DT>bbbb
<DD>
<p>Item b is kind of weird.</p>
<OL>
<LI>
<p>one</p>
<LI>
<p>two</p>
</OL>
<p>That's an enumerated list.</p>
<DT>cccc
<DD>
<p>Item c is from the moon.</p>
<DL>
<DT>first item of inner list
<DD>
<p>some text</p>
<DT>second item with no text
<DD>
<DT>third item with a lot of text
<DD>
<p>aaaaaaaaaaaaaa bbbbbbbbbbbbbbbb ccccccccccc ddddddddddddddd eeeeeee
fffffffff ggggggggggg hhhhhhhhhhhhhhhh iiiiiiiiiiiiiiiiii jjjjjjjjjj
kkkkkkkkkkkkk llllllllllllll mmmmmmmmmmmmmmm nnnnnnnnnnnnn oooooooo
ppppppppppppp.

</p>
</DL>
</DL>
<FONT SIZE="+2" FACE="Verdana,Arial,Helvetica">STOP</FONT><P>
<p>Last '<code>code</code>' paragraph &copy; 2001 &reg;.</p>
</DIV>
EOT

    my $match;
    my $pos_text=index($text,substr($ok,0,10));
    my $pos_ok=0;
    my $line=0;
    while($pos_ok<length($ok) &&
          substr($ok,$pos_ok,1) eq substr($text,$pos_text,1)) {
        $pos_ok++;
        $pos_text++;
        $line++ if substr($ok,$pos_ok,1) eq "\n";
    }
    if($pos_ok<length($ok)) {
        dprint "Texts do not match in line $line:";
        my $ok_exc=substr($ok,$pos_ok-5,20);
        my $text_exc=substr($text,$pos_text-5,20);
        dprint "  Standard: ...$ok_exc...";
        dprint " Generated: ...$text_exc...";
        $self->assert(0,
                      "Translation is not correct in line $line" .
                      " ('$ok_exc' ne '$text_exc')");
    }
}

1;
