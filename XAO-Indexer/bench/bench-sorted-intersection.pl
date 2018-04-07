#!/usr/bin/env perl
use warnings;
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
my $run_count=300;
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
    print "============= uptime\n";
    system '/usr/bin/uptime';
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

my %rdarr=(
    should  => [ 83,4,31,0,0,93,4,1,0,0,66,3,9,0,0,91,4,468,0,0,14,4,129,0,0,33,4,347,0,0,97,2,51,0,0,133,3,5,0,0,132,4,247,385,0,0,28,4,21,0,0,129,2,34,0,0,17,1,1,0,0,68,4,74,0,0,84,4,170,0,0,62,4,111,0,0,120,4,61,0,0,82,4,10,0,0,46,2,44,0,0,88,2,51,0,0,142,4,50,0,0,63,4,270,0,0,111,1,1 ],
    work    => [ 98,4,294,0,0,71,4,161,0,0,57,2,33,0,0,83,3,30,0,4,94,0,0,105,2,44,68,0,0,2,2,28,82,0,0,93,4,89,0,0,90,4,21,0,0,51,4,337,0,0,66,2,87,0,4,93,122,232,0,0,85,4,91,280,410,0,0,131,4,73,0,0,125,4,86,0,0,67,4,66,72,75,114,207,0,0,5,2,16,0,4,66,0,0,14,4,16,0,0,33,2,3,0,4,241,0,0,139,1,7,0,0,20,4,128,0,0,124,2,50,0,0,11,2,33,64,0,4,112,159,0,0,32,4,174,424,0,0,87,3,15,0,4,174,0,0,97,4,69,0,0,115,4,255,371,0,0,12,4,28,37,64,0,0,119,1,7,0,2,75,0,0,77,1,2,0,4,11,51,168,0,0,75,2,2,0,0,112,4,294,0,0,133,4,240,307,0,0,55,4,44,63,0,0,48,2,36,0,0,103,4,168,0,0,34,2,32,0,0,132,4,22,174,0,0,28,2,34,88,0,0,40,4,256,0,0,127,4,65,105,0,0,22,3,32,0,4,140,0,0,72,2,1,0,0,50,4,155,232,240,0,0,95,4,260,0,0,137,4,308,0,0,129,2,40,0,4,100,0,0,35,4,42,0,0,3,2,3,0,0,138,4,211,0,0,110,3,5,0,4,156,0,0,58,4,289,308,475,0,0,42,4,82,318,0,0,147,3,36,0,4,355,0,0,27,2,30,33,0,0,44,4,168,206,0,0,53,3,4,0,4,3,5,0,0,17,1,2,0,4,136,178,0,0,68,2,23,0,0,4,1,7,0,4,16,0,0,6,1,6,0,3,16,0,4,245,0,0,84,4,277,0,0,70,2,34,0,0,143,4,423,0,0,120,2,69,0,4,170,0,0,26,3,18,32,0,4,250,0,0,126,2,21,60,0,0,69,2,3,0,4,116,0,0,82,3,29,0,4,215,0,0,106,4,27,179,375,401,0,0,118,2,63,0,0,23,4,302,0,0,24,2,43,0,4,318,472,0,0,100,2,86,0,0,46,2,53,0,0,111,4,38,0,0,81,3,13,0,4,2,27,257,0,0,88,3,7,0,4,274,0,0,30,4,58,0,0,59,4,230,309,0,0,144,4,61,0,0,142,4,100,0,0,37,4,15,0,0,56,2,36,0,0,29,2,22,0,0,130,4,55,110,0,0,1,2,50,0,0,111,1,2 ],
    with    => [ 98,2,12,0,0,71,4,108,0,0,57,2,75,83,0,4,120,0,0,83,2,55,0,4,46,178,332,372,0,0,94,2,82,0,0,65,2,28,0,0,47,4,55,165,0,0,2,2,43,0,4,121,0,0,93,2,62,0,0,146,4,154,0,0,54,1,11,0,0,60,4,24,0,0,61,1,3,0,4,138,0,0,90,2,57,0,0,51,4,372,0,0,148,2,83,0,0,66,2,7,60,0,0,99,2,8,74,0,4,148,0,0,86,4,404,0,0,85,3,26,30,0,4,36,267,0,0,91,2,4,26,0,4,321,0,0,131,2,64,0,0,125,2,14,26,0,0,67,4,120,0,0,14,4,3,77,101,192,0,0,116,2,52,56,0,0,15,4,107,213,291,0,0,33,2,64,0,3,13,0,4,221,295,0,0,145,2,48,0,4,29,0,0,7,2,14,0,4,31,0,0,13,4,230,0,0,20,4,69,186,0,0,124,1,4,0,0,149,4,82,0,0,11,4,386,0,0,32,2,32,0,4,224,261,367,399,0,0,87,2,4,0,4,26,0,0,31,3,8,0,0,115,3,44,52,0,0,77,4,7,160,199,234,0,0,38,2,43,0,0,112,4,157,242,0,0,133,4,136,284,0,0,55,2,15,0,0,122,2,59,0,0,117,2,17,0,0,103,2,34,0,0,34,1,2,0,0,132,4,130,192,320,0,0,79,1,3,0,4,49,75,0,0,28,3,6,0,0,40,4,220,249,0,0,127,2,50,0,4,148,0,0,22,4,56,0,0,64,2,60,0,4,95,164,0,0,50,2,14,0,4,244,300,0,0,95,4,92,0,0,137,4,200,383,0,0,129,4,126,154,266,267,318,0,0,114,1,9,0,2,53,62,0,0,35,2,7,53,0,0,3,4,73,0,0,41,4,196,0,0,101,2,68,0,0,110,4,28,129,173,0,0,58,4,71,182,231,384,0,0,42,3,7,0,4,90,244,0,0,147,4,154,0,0,136,2,46,0,0,44,4,229,0,0,73,2,73,0,4,127,0,0,36,2,51,0,3,7,0,4,1,11,0,0,53,4,255,0,0,17,1,3,0,4,62,288,443,0,0,68,4,11,0,0,4,4,153,304,0,0,84,2,47,0,4,173,217,0,0,70,4,35,0,0,143,4,122,0,0,134,2,41,0,4,370,0,0,120,2,38,0,4,29,274,0,0,10,4,42,0,0,26,4,244,293,0,0,92,2,26,0,0,69,4,9,133,238,255,362,404,435,0,0,82,2,18,0,4,208,0,0,106,2,76,0,4,87,382,0,0,118,4,102,161,248,0,0,76,2,37,0,0,23,4,54,256,0,0,24,4,196,222,262,361,375,0,0,80,4,93,124,160,0,0,140,4,104,0,0,52,4,184,0,0,46,4,20,0,0,111,4,40,0,0,141,2,1,23,0,0,135,4,76,0,0,150,4,176,0,0,88,2,1,0,4,191,444,0,0,59,2,10,0,4,264,0,0,144,3,5,0,4,127,0,0,121,4,190,0,0,37,2,56,0,4,92,121,141,181,0,0,45,1,1,0,4,250,0,0,56,4,240,368,0,0,29,3,7,0,0,63,2,66,0,4,88,107,299,0,0,130,2,33,52,0,4,78,169,0,0,1,2,73,0,0,111,1,3 ],
    alien   => [ 98,4,83,193,252,449,0,0,71,4,256,0,0,57,4,70,0,0,108,2,37,0,4,38,0,0,94,2,71,0,0,93,4,281,0,0,61,2,87,0,0,90,4,55,242,0,0,51,4,30,200,331,0,0,66,4,110,126,212,0,0,86,4,142,0,0,91,4,370,469,0,0,131,4,142,0,0,67,2,13,0,0,14,4,31,318,0,0,33,4,143,234,0,0,43,2,58,0,0,7,4,62,71,0,0,107,2,36,0,0,20,4,248,0,0,8,2,3,0,3,3,0,0,149,2,26,0,4,135,0,0,11,2,37,0,4,214,0,0,32,2,43,0,0,87,4,333,356,436,0,0,115,4,157,0,0,77,2,23,0,0,112,4,57,73,383,0,0,133,3,38,0,4,305,0,0,122,2,38,0,0,117,4,14,0,0,103,4,88,222,0,0,79,4,18,87,0,0,28,3,2,0,0,127,4,82,154,0,0,22,4,133,0,0,50,4,317,0,0,95,2,24,0,0,137,4,70,146,216,363,0,0,129,2,29,0,0,114,2,48,0,0,35,4,31,237,0,0,3,2,7,0,4,135,0,0,101,2,63,0,0,138,4,57,81,419,0,0,42,4,47,219,0,0,16,2,50,0,0,36,4,29,0,0,53,3,15,0,4,197,0,0,17,1,4,5,0,0,4,2,12,0,4,29,0,0,6,4,69,231,0,0,62,4,446,0,0,70,4,255,0,0,21,2,58,0,0,120,4,41,0,0,10,4,21,410,0,0,69,4,8,61,132,436,0,0,118,2,46,0,4,228,0,0,24,4,239,0,0,80,2,54,81,0,4,8,0,0,52,4,163,0,0,46,4,31,116,0,0,81,4,72,0,0,88,4,228,0,0,30,4,295,0,0,59,2,32,0,3,39,0,4,285,0,0,144,2,92,0,0,45,4,135,0,0,56,3,32,0,0,29,4,62,168,0,0,128,3,12,0,0,130,2,60,0,4,151,0,0,111,1,4 ],
);
my %rawdata;
@rawdata{keys %rdarr}=map { pack('w*',@$_) } values %rdarr;
my @marr_full=('should','work','with','alien');
my @marr_undef=('should',undef,undef,'alien');

$final=XAO::IndexerSupport::sorted_intersection_pos(\@marr_full,\%rawdata);
dprint "Pos(normal,full): ".join(',',@$final);
$final=XAO::IndexerSupport::sorted_intersection_pos_perl(\@marr_full,\%rawdata);
dprint "Pos(perl,full): ".join(',',@$final);
$final=XAO::IndexerSupport::sorted_intersection_pos(\@marr_undef,\%rawdata);
dprint "Pos(normal,undef): ".join(',',@$final);
$final=XAO::IndexerSupport::sorted_intersection_pos_perl(\@marr_undef,\%rawdata);
dprint "Pos(perl,undef): ".join(',',@$final);

print "============= benchmarking\n";
my %results;
$results{id_c}=timethis($run_count,\&do_c);
if($with_perl) {
    my $prc=int($run_count/10);
    $prc=10 if $prc<10;
    $results{id_perl}=timethis($prc,\&do_perl);
}
$results{pos_c_1}=timethis($run_count,\&do_c_pos_full);
$results{pos_c_2}=timethis($run_count,\&do_c_pos_undef);
Benchmark::cmpthese(\%results);
exit 0;

###############################################################################

sub do_perl {
   XAO::IndexerSupport::sorted_intersection_perl(@wsets);
   return undef;
}

sub do_c {
   XAO::IndexerSupport::sorted_intersection(@wsets);
   return undef;
}

sub do_perl_pos_full {
   XAO::IndexerSupport::sorted_intersection_pos_perl(\@marr_full,\%rawdata);
   return undef;
}

sub do_c_pos_full {
   XAO::IndexerSupport::sorted_intersection_pos(\@marr_full,\%rawdata);
   return undef;
}

sub do_perl_pos_undef {
   XAO::IndexerSupport::sorted_intersection_pos_perl(\@marr_undef,\%rawdata);
   return undef;
}

sub do_c_pos_undef {
   XAO::IndexerSupport::sorted_intersection_pos(\@marr_undef,\%rawdata);
   return undef;
}
