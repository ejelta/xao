=head1 NAME

XAO::Templates - templates caching and retrieving module

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

Templates retriever. Uses persistent cache to store once retrieved
templates.  Cache top level keys are site names, for system templates
'/' is used as a site name.

=cut

###############################################################################
package XAO::Templates;
use strict;
use XAO::Base qw($homedir $projectsdir);
use XAO::Utils;
use XAO::Projects qw(get_current_project_name);

use vars qw($VERSION);
($VERSION)=('$Id: Templates.pm,v 1.6 2003/06/26 03:13:53 am Exp $' =~ /(\d+\.\d+)/);

##
# Cache for templates.
#
use vars qw(%cache);

##
# Getting the text of given template.
#
sub get (%) {
    my %args=@_;
    my $path=$args{path};
    my $sitename=get_current_project_name();
    if($path =~ /\.\.\//) {
        eprint "Bad template path -- sitename=",$sitename,", path=$path";
        return undef;
    }

    ##
    # Checking in the memory cache
    #
    return $cache{$sitename}->{$path} if exists($cache{$sitename}) && exists($cache{$sitename}->{$path});
    return $cache{'/'}->{$path} if exists($cache{'/'}) && exists($cache{'/'}->{$path});

    ##
    # Retrieving from disk.
    #
    my $system;
    my $tpath;
    if(defined $sitename) {
        $tpath="$projectsdir/$sitename/templates/$path";
        $system=0;
    }
    if(! $tpath || ! -r $tpath) {
        $tpath="$homedir/templates/$path";
        $system=1;
    }
    local *F;
    return undef unless open(F,$tpath);
    local $/;
    my $text=<F>;
    close(F);

    ##
    # Storing into cache.
    #
    $cache{$system ? '/' : $sitename}->{$path}=$text if length($text)<50000;
    $text;
}

=item filename ($;$)

Checks if given path (first argument) exists and returns template's
filename if it does and 'undef' if there is no template. Optional second
argument refers to a sitename (project name), by default the current
active project name is used.

=cut

sub filename ($;$) {
    my ($path,$sitename)=@_;

    $sitename||=get_current_project_name();

    if($path =~ /\.\.\//) {
        eprint "Bad template path -- sitename=",$sitename,", path=$path";
        return 0;
    }

    return undef if !defined($path) || $path eq '';

    if(defined $sitename) {
        my $tn="$projectsdir/$sitename/templates/$path";
        return $tn if -f $tn && -r _;
    }

    my $tn="$homedir/templates/$path";
    return $tn if -f $tn && -r _;

    return undef;
}

###############################################################################

=item check (%)

Deprecated method, do not use.

=cut

sub check (%) {
    my %args=@_;
    dprint "XAO::Templates::check - deprecated, use filename() instead";
    return filename($args{path}) ? 1 : 0;
}

###############################################################################

# Complete list of all available templates in random order.
#
# Returns list in array context and array reference in scalar context.

sub list (%) {
    eprint "XAO::Templates::list - is not supported any more";
    my %args=@_;
    my $tpath;
    my $sitename=get_current_project_name();
    if(defined $sitename) {
        $tpath="$projectsdir/$sitename/templates/";
    }
    if(! $tpath || ! -r $tpath) {
        $tpath="$homedir/templates/";
    }
    if(! $tpath || ! -r $tpath) {
        eprint "Templates::list - can't get list";
        return wantarray ? () : undef;
    }
    local *F;
    if(!open(F,"/usr/bin/find $tpath -type f |")) {
        eprint "Templates::list - can't get list: $!\n";
        return wantarray ? () : undef;
    }
    my @list=map { chomp; s/^$tpath//; $_ } <F>;
    close(F);
    wantarray ? @list : (@list ? \@list : undef);
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2000-2003 XAO Inc.

The author is Andrew Maltsev <am@xao.com>
