#!/usr/bin/perl
use XAO::TestUtils;

eval "use XAO::ImageCache";
if($@) { die "Can't find XAO::Base - call as ``perl -Mblib $0'' ($@)\n" }

if(@ARGV) {
    XAO::TestUtils::xao_test(@ARGV);
}
else {
    XAO::TestUtils::xao_test_all('testcases');
}
