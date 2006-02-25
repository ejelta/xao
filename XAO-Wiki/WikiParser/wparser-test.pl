use strict;
use blib;
use WikiParser;

my ($h,$i);
my $out=XAO::Wiki::WikiParser::parse("xxxx<b>bold</b>zzzz\na<v>aaa\n\nnewpar");
foreach $h (@$out) {
  print "{";
  foreach $i (keys %$h) {
    print " $i => '";
    print $h->{$i};
    print "',";
  }
  print "},\n";
}

#print STDERR ">>>>>\n";
#print STDERR WParser::parse("xxxx<b>bold</b>zzzz\naaaa\n\nnewpar");
#print STDERR "<<<<<\n";
