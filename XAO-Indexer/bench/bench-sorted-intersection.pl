#!/usr/bin/perl -w
use strict;
use blib;
use XAO::Objects;
use XAO::Utils;
use XAO::IndexerSupport;
use Benchmark;
use Getopt::Long;

my @saved_argv=@ARGV;

my $full_count=10000;
my $part_count=5000;
my $word_count=5;
my $run_count=100;
my $no_sysinfo;
my $with_perl;
GetOptions(
    'debug'             => sub { XAO::Utils::set_debug(1) },
    'full-count=i'      => \$full_count,
    'part-count=i'      => \$part_count,
    'run-count=i'       => \$run_count,
    'word-count=i'      => \$word_count,
    'no-system-info'    => \$no_sysinfo,
    'with-perl'         => \$with_perl,
);
if(@ARGV<1 || $ARGV[0] ne 'yes') {
    print <<EOT;
Usage: $0 \\
    [--debug] \\
    [--full-count $full_count] \\
    [--part-count $part_count] \\
    [--word-count $word_count] \\
    [--run-count $run_count] \\
    [--no-system-info] \\
    [--with-perl] \\
    yes

Benchmarks XAO::IndexerSupport sorted list intersection implementation.

EOT
    exit 1;
}

srand(24680);

if(!$no_sysinfo) {
    dprint "Printing system info";
    print "============= /proc/cpuinfo\n";
    system '/bin/cat /proc/cpuinfo';
    print "============= uname -a\n";
    system '/bin/uname -a';
    print "============= args\n";
    print "$0 ",join(' ',@saved_argv),"\n";
    print "full-count $full_count\n";
    print "part-count $part_count\n";
    print "word-count $word_count\n";
    print "run-count $run_count\n";
    print "============= date\n";
    print scalar(localtime),"\n";
    print "============= preparing\n";
}

##
# Partial subset is always a subset of the full set, it is guaranteed.
#
dprint "Building full dataset ($full_count)";
my @full_data=(0..$full_count-1);
for(my $i=0; $i<$full_count; ++$i) {
    my $n=int(rand($full_count));
    next if $n==$i;
    ($full_data[$i],$full_data[$n])=($full_data[$n],$full_data[$i]);
}
### dprint "FULL   : ",join(',',@full_data);
dprint "Building word sets ($word_count/$part_count)";
my @wsets;
XAO::IndexerSupport::template_sort_prepare(\@full_data);
for(my $i=0; $i<$word_count; ++$i) {
    my %part_hash;
    my @part_data;
    my $part_num=int($part_count-rand(1)*rand(1)*rand($part_count*0.8));
    while(scalar(@part_data) < $part_num) {
        my $n=$full_data[int(rand($full_count))];
        next if $part_hash{$n};
        $part_hash{$n}=1;
        push(@part_data,$n);
    }
    my $part_sorted=XAO::IndexerSupport::template_sort(\@part_data);
    ### dprint "PART($i): ".join(',',@$part_sorted);
    push(@wsets,$part_sorted);
}
XAO::IndexerSupport::template_sort_free();

my $final=XAO::IndexerSupport::sorted_intersection(@wsets);
my $final_num=@$final;
print "Final set includes $final_num elements (c)\n";
$final=XAO::IndexerSupport::sorted_intersection_perl(@wsets);
$final_num=@$final;
print "Final set includes $final_num elements (perl)\n";

print "============= benchmarking\n";
my %results;
$results{normal}=timethis($run_count,\&do_c);
if($with_perl) {
    my $prc=int($run_count/10);
    $prc=10 if $prc<10;
    $results{perl}=timethis($prc,\&do_perl);
}
Benchmark::cmpthese(\%results);
exit 0;

###############################################################################

sub do_null {
    [ 1 ];
}

sub do_perl {
   XAO::IndexerSupport::sorted_intersection_perl(@wsets);
   return undef;
}

sub do_c {
   XAO::IndexerSupport::sorted_intersection(@wsets);
   return undef;
}
