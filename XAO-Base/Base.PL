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
###### THIS IS AUTOMATICALLY GENERATED FILE -- DO NOT EDIT IT ######
############ RE-INSTALL XAO::BASE PACKAGE TO UPDATE IT #############
####################################################################
package XAO::Base;
use strict;
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

###############################################################################
1;
