package testcases::WebPodView;
use strict;
use XAO::Utils;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    $self->catch_stdout();
    $self->{web}->execute(path => '/test.html', cgi => CGI->new(''));
    my $text=$self->get_stdout();

    my $ok=<<'EOT';
<DIV><FONT SIZE="+2" FACE="Verdana,Arial,Helvetica">TEST</FONT><P>
<FONT SIZE="+1" FACE="Verdana,Arial,Helvetica">MISC TEST</FONT><P>
some paragraph
on <B>multiple</B> lines
that includes <I>italic text</I> and a link: <A HREF="http://testhost.xao.com/test.html?module=IO::File">the IO::File manpage</A>.

<P>
Code sample:<P>
<PRE>
 # Like that
 #
 my $test=1;

 # Line after break
</PRE>
<FONT SIZE="+1" FACE="Verdana,Arial,Helvetica">LIST TEST</FONT><P>
Paragraph of text on the top.<P>
<DL>
<DT>aaaa
<DD>
Item a is very strange.<P>
<UL>
<LI>
fubar<P>
<OL>
<LI>
one-one-one<P>
<LI>
two-two-two<P>
</OL>
That was enumerated list in bullet list in definitions list.<P>
Another paragraph here with a <A HREF="http://xao.com/">link</A>.<P>
And yet another one.<P>
<LI>
buraf<P>
</UL>
<DT>bbbb
<DD>
Item b is kind of weird.<P>
<OL>
<LI>
one<P>
<LI>
two<P>
</OL>
That's an enumerated list.<P>
<DT>cccc
<DD>
Item c is from the moon.<P>
<DL>
<DT>first item of inner list
<DD>
some text<P>
<DT>second item with no text
<DD>
<DT>third item with a lot of text
<DD>
aaaaaaaaaaaaaa bbbbbbbbbbbbbbbb ccccccccccc ddddddddddddddd eeeeeee
fffffffff ggggggggggg hhhhhhhhhhhhhhhh iiiiiiiiiiiiiiiiii jjjjjjjjjj
kkkkkkkkkkkkk llllllllllllll mmmmmmmmmmmmmmm nnnnnnnnnnnnn oooooooo
ppppppppppppp.

<P>
</DL>
</DL>
<FONT SIZE="+2" FACE="Verdana,Arial,Helvetica">STOP</FONT><P>
Last '<CODE>code</CODE>' paragraph &copy; 2001 &reg;.<P>
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
