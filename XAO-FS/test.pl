#!/usr/bin/perl
use XAO::TestUtils;

if(@ARGV) {
    XAO::TestUtils::xao_test(@ARGV);
}
else {
    XAO::TestUtils::xao_test_all('XAO::testcases::FS');
}
