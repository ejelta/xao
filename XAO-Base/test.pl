#!/usr/bin/perl

eval "use XAO::UnitTest";
if($@) { die "Can't find XAO::Base - call as ``perl -Mblib $0'' ($@)\n" }

if(@ARGV) {
    XAO::UnitTest::xao_test(@ARGV);
}
else {
    XAO::UnitTest::xao_test_all('testcases');
}
