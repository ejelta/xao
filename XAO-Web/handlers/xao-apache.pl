#!/usr/bin/perl
#
# Finds out what project it was called for. Switches operational
# parameters to this projects and then loads and displays requested
# Page.
#
# Site name must be first name in path. Rewrite module should put it
# there if it's not set as part of path already.
#
use strict;
use Error qw(:try);
use CGI;
#
use Symphero::Web;
use Symphero::Defaults qw($homedir $projectsdir);
use Symphero::Utils;
use Symphero::SiteConfig ();
use Symphero::Objects;
use Symphero::Templates;
use Symphero::PageSupport;

##
# Prototypes
#
sub analyze (@);

##
# Some global variables.
#
my $cgi=CGI->new();
use vars qw($siteconfig);
$siteconfig=undef;

##
# Resetting page text stack in case it was terminated abnormally before
# and we're in the same process/memory.
#
Symphero::PageSupport::reset();

##
# Trying this whole block and catching errors later.
#
try {

    ##
    # Getting CGI object and path
    #
    my @path=split("/+","/".$cgi->path_info);
    shift @path;
    my $sitename=shift @path;
    $sitename || throw Symphero::Errors::Handler "No site name given!";

    ##
    # This is not very good way to check it here, should be more
    # flexible I guess.
    #
    throw Symphero::Errors::Handler "Bad file Path" if grep(/^bits$/,@path);

    ##
    # Executing site configurator and creating site configuration object.
    #
    $siteconfig=Symphero::SiteConfig->find($sitename);
    if($siteconfig) {
        $siteconfig->cleanup;
    }
    else {

        my $sitedir="$projectsdir/$sitename";
        -d $sitedir ||
            throw Symphero::Errors::Handler "No such directory $sitedir";

        ##
        # Checking that such site exists. We used to store configuration
        # file under 'modules/Config.pm', but it is now deprecated.
        #
        if(-r "$sitedir/objects/Config.pm") {
            $siteconfig=Symphero::Objects->new(objname => 'Config',
                                               sitename => $sitename);
        }
        elsif(-r "$sitedir/modules/Config.pm") {
            eprint "Placing Config.pm into modules/ is obsolete, move it to objects/";

            ##
            # Sucking its configuration in
            #
            eval { require "$projectsdir/$sitename/modules/Config.pm" };
            throw Symphero::Errors::Handler "System error: $@" if $@;
  
            ##
            # Getting configuration object
            #
            $siteconfig=eval "Symphero::Objects::${sitename}::Config->new(\$sitename)";
            throw Symphero::Errors::Handler "System error: $@" if $@ || !$siteconfig;

        }

        ##
        # Checking if we have base_url. Guessing it if not.
        # Ensuring that URL does not end with '/'.
        #
        if(! $siteconfig->defined("base_url")) {

            ## my $url=$cgi->https() ? "https://" : "http://";
            ## $url.=$cgi->virtual_host();

            ##
            # Base URL should full path to the start point - http://host.com
            # in case of rewrite and something like
            # http://host.com/cgi-bin/symphero.pl/sitename in case of plain
            # CGI usage.
            #
            my $url=$cgi->url(-full => 1, -path_info => 0);

            ##
            # Trying to understand if rewrite module was used or not. If not
            # - adding sitename to the end of guessed URL.
            #
            if($url =~ /cgi-bin/ || $url =~ /symphero\.pl/) {
                $url.="/$sitename";
            }

            ##
            # Eating extra slashes
            #
            chop($url) while $url =~ /\/$/;
            $url=~s/(?<!:)\/\//\//g;

            ##
            # Storing
            #
            $siteconfig->put(base_url => $url);
            $siteconfig->put(base_url_secure => $url);
            dprint "No base_url defined, sitename=$sitename; assuming base_url=$url";
        }
        else {
            my $urlref=$siteconfig->getref("base_url");
            chop($$urlref) while $$urlref =~ /\/$/;
        }
    }
  
  ##
  # Setting this site configuration as default for the rest of this session.
  #
  $siteconfig->set_current;

  ##
  # Checking if we're running under mod_perl
  #
  $siteconfig->session_specific(qw(mod_perl));
  $siteconfig->put(mod_perl => $ENV{MOD_PERL} ? 1 : 0);

  ##
  # Putting CGI object into site configuration
  #
  $siteconfig->enable_special_access;
  $siteconfig->cgi($cgi);
  $siteconfig->disable_special_access;

  ##
  # Checking for directory index url without trailing slash and
  # redirecing with appended slash if this is the case.
  #
  push(@path,"index.html") if $cgi->path_info =~ /\/$/;
  if($path[-1] !~ /\.\w+$/)
   { my $pd=analyze(@path,'index.html');
     if($pd->{objname} ne 'Default')
      { my $newpath=$cgi->url(-full => 1, -path_info => 1)."/";
        print $cgi->redirect(-url => $newpath),
              "Document is really <A HREF=\"$newpath\">here</A>.\n";
        exit 0;
      }
   }

  ##
  # Checking existence of the page.
  #
  my $pd=analyze(@path);
  my @d=localtime;
  my $date=sprintf("%02u:%02u:%02u %u/%02u/%04u",$d[2],$d[1],$d[0],$d[4]+1,$d[3],$d[5]+1900);
  undef(@d);
  dprint "============ date=$date, mod_perl=",$siteconfig->get('mod_perl'),
                    ", path='",join('/',@path),"', translated='",$pd->{path},"'";

  ##
  # Putting path into site configuration
  #
  $siteconfig->session_specific(qw(pagedesc));
  $siteconfig->put(pagedesc => $pd);

  ##
  # We accumulate page content here
  #
  my $pagetext;

  ##
  # Do we need to run any objects before executing? Authorization
  # usually goes here.
  #
  if($siteconfig->get('auto_before'))
   { my $list=$siteconfig->get('auto_before');
     foreach my $objname (keys %{$list})
      { my $obj=Symphero::Objects->new(objname => $objname);
        $pagetext.=$obj->expand($list->{$objname});
      }
   }

  ##
  # Loading page displaying object and executing it.
  #
  my $obj=Symphero::Objects->new(objname => $pd->{objname});
  my %objargs=( path => $pd->{path}
              , fullpath => $pd->{fullpath}
              , prefix => $pd->{prefix}
              );
  @objargs{keys %{$pd->{objargs}}}=values %{$pd->{objargs}} if $pd->{objargs};
  $pagetext.=$obj->expand(\%objargs);

  ##
  # If siteconfig returns us header then it was not printed before and we
  # expected to print out the page. This is almost always true except when
  # page included something like Redirect object.
  #
  my $header=$siteconfig->header;
  if(defined($header))
   { print $header,
           $pagetext;
   }
}

##
# Catching errors. Some specific actions could be here, but for now we
# just print out simple page with error.
#
otherwise
 { my $e=shift;
   print $cgi->header(-status => "500 System Error"),
         $cgi->start_html("System error"),
         $cgi->h1("System error"),
         $cgi->strong(t2ht($e->text)),
         "<P>\n",
         "Please inform web server administrator about the error.\n",
         $cgi->h1("Stack Trace"),
         "<PRE>\n",
         t2ht($e->stacktrace),
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
finally
 { $siteconfig->cleanup if $siteconfig;
 };

##
# That's it!
#
exit 0;

###############################################################################

##
# Checking how to display given path. Always returns valid results or
# throws an error if it can't be accomplished.
# 
# Return hash reference:
#  { prefix => longest matching prefix (directory in case of template found)
#  , path => path to the page after the prefix
#  , fullpath => full path from original query
#  , objname => object name that will serve this path
#  , objargs => object args hash (may be empty)
#  }
#
sub analyze (@) {
    my @path=@_;
    my $path=join('/',@path);
    my $table=$siteconfig->get('path_mapping_table');

    ##
    # Looking for the object matching the path.
    #
    if($table) {
        for(my $i=@path; $i>=0; $i--) {
            my $dir=$i ? join('/',@path[0..$i-1]) : '';
            my $od=$table->{$dir} || $table->{'/'.$dir} || $table->{$dir.'/'} || $table->{'/'.$dir.'/'};
            next unless $od;
            my $objname;
            my %args;
            if(ref($od))
             { $objname=$od->[0];
               if(scalar(@{$od})%2 == 1)
                { %args=@{$od}[1..$#{$od}];
                }
               else
                { eprint "Odd number of arguments in mapping table, dir=$dir, objname=$objname";
                }
             }
            else
             { $objname=$od;
             }
            return { objname => $objname,
                     objargs => \%args,
                     path => join('/',@path[$i..$#path]),
                     prefix => $dir,
                     fullpath => $path
                   };
          }
       }

    ##
    # Now looking for exactly matching template. If it matches and
    # we have some object defined for '/' - then this is our default
    # object. Otherwise - Page is.
    #
    if(Symphero::Templates::check(path => $path))
     { return { objname => ($table && $table->{'/'}) ? $table->{'/'} : 'Page',
                path => $path,
                fullpath => $path,
                prefix => join('/',@path[0..($#path-1)])
              };
     }

    ##
    # Nothing was found, returning Default object
    #
    return {
        objname => ($table && $table->{'/'}) ? $table->{'/'} : 'Default',
        path => $path,
        fullpath => $path,
        prefix => ''
    };
}
