#!/usr/bin/perl -w
#
# Builds Base.pm according to the configuration in .config.
#
# XAO::Base package version should be updated manually in Makefile.PL
#
use strict;

##
# Reading configuration
#
my ($homedir,$version);
open(F,".config") || die "Can't open .config: $!\n";
while(<F>) {
    next unless /^(\w+)\s+(.*?)[\s\r\n]+$/s;
    my ($cmd,$value)=($1,$2);
    if($cmd eq 'homedir') {
        $homedir=$value;
    }
    elsif($cmd eq 'version') {
        $version=$value;
    }
 }
close(F);
$homedir && $version ||
    die "Bad .config data!\n";

##
# Beautifying homedir
#
$homedir=~s/\/{2,}/\//g;
$homedir=~s/^(.*)(\/+)$/$1/;
my $projectsdir=$homedir . '/projects';

##
# Generating output Defaults.pm file
#
my $outfile=shift(@ARGV);
die "No output file given!\n" unless $outfile;
open(F,"> $outfile") || die "Can't open $outfile: $!\n";
while(<DATA>) {
    s/<%VERSION%>/$version/;
    s/<%HOMEDIR%>/$homedir/;
    s/<%PROJECTSDIR%>/$projectsdir/;
    print F;
}
close(F);
exit(0);

###############################################################################
__DATA__
####################################################################
###### This is automatically generated file -- do not edit it ######
############ Re-install XAO::Base package to update it #############
####################################################################
package XAO::Base;
use strict;
use XAO::Errors qw(XAO::Errors::Base);
require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION
            $homedir $projectsdir $xao_base_version);

@ISA=qw(Exporter);
@EXPORT_OK=qw($homedir $projectsdir $xao_base_version);
@EXPORT=();

##
# XAO::Base package version
#
$xao_base_version='$version';
$VERSION='<%VERSION%>';

##
# Home directory of XAO
#
$homedir='<%HOMEDIR%>';

##
# Root directory for all projects
#
$projectsdir='<%PROJECTSDIR%>';

##
# Setting root to something else. Useful for tests and not recommended
# for use in normal lifecycle.
#
sub set_root ($) {
    my $dir=shift || '';
    $dir=~/^\// || 
        throw XAO::Errors::Base "set_root - $dir must be an absolute path";
    -d $dir ||
        throw XAO::Errors::Base "set_root - directory $dir does not exists";
    $homedir=$dir;
    $projectsdir=$homedir . '/projects';
}

###############################################################################
1;
