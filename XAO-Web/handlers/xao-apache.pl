#!/usr/bin/perl -w
#
# Finds out what project it was called for. Switches operational
# parameters to this projects and then loads and displays requested
# Page.
#
# Site name must be the first name in path. Rewrite module should put it
# there if it's not set as part of path already.
#
use strict;
use Error qw(:try);
use CGI;
use XAO::Utils;
use XAO::Web;
use XAO::Errors qw(XAO::E::Handler);

##
# Global debugging output. It's better to set that in site's config.
#
### XAO::Utils::set_debug(1);

##
# Some global variables.
#
my $cgi=new CGI;
my $siteconfig;

##
# Trying this whole block and catching errors later.
#
try {

    ##
    # Getting CGI object and path
    #
    my $path_info=$cgi->path_info;
    my @path=split('/+','/'.$path_info);
    shift @path;
    my $sitename=shift @path;
    $sitename || throw XAO::E::Handler "No site name given!";
    push @path,'' if $path_info=~/\/$/;

    ##
    # This is not very good way to check it here, should be more
    # flexible I guess.
    #
    throw XAO::E::Handler "Bad file path" if grep(/^bits$/,@path);

    ##
    # Loading or creating site object.
    #
    my $site=XAO::Web->new(sitename => $sitename);
  
    ##
    # Executing.
    #
    my $path=join('/','/',@path);
    $site->execute(path => $path,
                   cgi => $cgi);
}

##
# Catching errors. Some specific actions could be here, but for now we
# just print out simple page with error.
#
otherwise {
    my $e=shift;
    print $cgi->header(-status => "500 System Error"),
          $cgi->start_html("System error"),
          $cgi->h1("System error"),
          $cgi->strong(XAO::Utils::t2ht($e->text)),
          "<P>\n",
          "Please inform web server administrator about the error.\n",
          $cgi->h1("Stack Trace"),
          "<PRE>\n",
          XAO::Utils::t2ht($e->stacktrace),
          "</PRE>\n",
          $cgi->end_html;
    eprint $e->text;
}

##
# Cleaning up all session specific data.
#
# Closing semicolon for the "try" at the top of the script strongly
# required!
#
finally {
    $siteconfig->cleanup if $siteconfig;
};

##
# That's it!
#
exit 0;
