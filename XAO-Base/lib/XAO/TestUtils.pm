=head1 NAME

XAO::TestUtils - testing framework for XAO modules

=head1 SYNOPSIS

In your Makefile.PL:

 test::
        \$(PERL) -MXAO::TestUtils=xao_all_tests \\
                 -e'xao_all_tests("XAO::testcases::FS")'

=head1 DESCRIPTION

This module is intended for use only in testing of XAO modules and
modules based on XAO.

For instance XAO::FS installs a set of tests in system perl
directories. XAO::TestUtils and these tests can then be used for testing
third party database drivers against this standard set of tests.

Method details:

=over

=cut

###############################################################################
package XAO::TestUtils;
use strict;
use Test::Harness;
use XAO::Utils;
use File::Path;
use File::Basename;
use File::Copy;

require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);

@ISA=qw(Exporter);
@EXPORT_OK=qw(xao_test_all xao_test);
@EXPORT=();

($VERSION)=(q$Id: TestUtils.pm,v 1.4 2003/08/09 01:13:23 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item xao_test_all ($;@)

Runs all tests for a given list of namespaces in random order. As a
special case if first argument is an integer it turns debug output on
using XAO::Utils set_debug() method.

Can be called from command line:

 perl -MXAO::TestUtils=xao_test_all -e'xao_test_all(1,"testcases")'

Test execution is the same as for run_tests() method, see below.

=cut

sub xao_test_all ($;@) {
    XAO::Utils::set_debug(shift @_) if $_[0]=~/^\d+$/;

    my %tests;
    foreach my $namespace (@_) {
        ##
        # Scanning @INC to find directory holding these tests
        #
        (my $namedir=$namespace)=~s/::/\//g;
        foreach my $dir (@INC) {
            next unless -d "$dir/$namedir";
            opendir(D,"$dir/$namedir") || die "Can't open directory $dir: $!\n";
            while(my $file=readdir(D)) {
                next if $file eq 'base.pm';
                next unless $file =~ /^(.*)\.pm$/;
                $tests{$namespace . '::' . $1}=1;
            }
            closedir(D);
        }
    }

    ##
    # Randomizing tests list order to make sure that tests do not depend on
    # each other.
    #
    my @tests=keys %tests;
    for(my $i=0; $i!=@tests; $i++) {
        push(@tests,splice(@tests,rand(@tests),1));
    }

    dprint "Tests: ".join(',',@tests);
    xao_test(@tests);
}

###############################################################################

=item xao_test (@)

Runs given tests in the given sequence. Tests are given as corresponding
unit package names. Example:

 xao_test('testcases::basic','testcases::lists');

It will create 'ta' directory in the current directory and will
store two files for each test case in there - one suitable for 'make
test' with '.t' extension and one for manual checking with debug
output enabled and in different human-readable output mode with '.pl'
extension. At a later time these tests can be individually re-run
manually using simply 'perl ta/testname.pl' command.

Common prefix will be automatically removed from files.

=cut

sub xao_test (@) {
    my $testdir='ta';
    -d $testdir || mkdir "$testdir",0755 ||
        die "Can't create '$testdir' directory: $!\n";

    my $prefix_count;
    my $prefix;
    foreach my $test (@_) {
        dprint "test=$test";
        my @p=split(/::/,$test);
        if(defined $prefix) {
            while($prefix_count) {
                my $np=join('::',@p[0..$prefix_count]);
                last if length($np) <= length($prefix) &&
                        $np eq substr($prefix,0,length($np));
                $prefix_count--;
            }
        }
        else {
            $prefix_count=scalar(@p)-2;
        }
        last if $prefix_count<0;
        $prefix=join('::',@p[0..$prefix_count]);
        dprint "prefix=$prefix test=$test";
    }
    dprint "prefix=$prefix, prefix_count=$prefix_count";

    $prefix_count++;
    my %fnames;
    foreach my $test (@_) {
        my @p=split(/::/,$test);
        my $testfile=join('_',@p[$prefix_count..$#p]);
        $fnames{$test}=$testfile;
        dprint "Test: $test file=$testfile";
        open(F,"> $testdir/$testfile.t") || die "Can't create test script ($testdir/$test.t): $!\n";
        print F <<EOT;
#!$^X
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use Test::Unit::HarnessUnit;

my \$r=Test::Unit::HarnessUnit->new();
\$r->start('$test');
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
        close(F);

        open(F,"> $testdir/$testfile.pl") || die "Can't create test script ($testdir/$test.pl): $!\n";
        print F <<EOT;
#!$^X
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use blib;
use XAO::Utils;
use Test::Unit::TestRunner;

XAO::Utils::set_debug(1);

my \$r=Test::Unit::TestRunner->new();
\$r->start('$test');
print "\\n";
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
        close(F);
        chmod 0755, '$testdir/$testfile.pl';
    }

    ##
    # Executing tests
    #
    print STDERR <<'END_OF_WARNING';
===============================================================
Some of the tests may take up to a couple of minutes to run.
Please be patient.

If you see that a test failed, please run it as follows:

   perl -w ta/failed_test_name.pl

That will show you details about failure. Send the output to
the module author along with your perl version and short
description of what you think might be the reason.
===============================================================
END_OF_WARNING
    ### dprint join(",",(map { "$testdir/$fnames{$_}.t" } @_));
    runtests(map { "$testdir/$fnames{$_}.t" } @_);
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2003 XAO Inc.

The author is Andrew Maltsev <am@xao.com>.
