#XXX - make test for XAO::Web

package XAO::Web;
use strict;
use XAO::Utils;
use XAO::Projects;
use XAO::Objects;
use XAO::SimpleHash;
use XAO::PageSupport;
use XAO::Templates;
use XAO::Errors qw(XAO::Web);

###############################################################################
# XAO::Web version number. Hand changed with every release!
#
use vars qw($VERSION);
$VERSION='1.0';

###############################################################################

=head1 NAME

XAO::Web - XAO Web Developer, dynamic content building suite

=head1 SYNOPSIS

 use XAO::Web;

 my $web=XAO::Web->new(sitename => 'test');

 $web->execute(cgi => $cgi,
               path => '/index.html');

 my $config=$web->config;

 $config->clipboard->put(foo => 'bar');

=head1 DESCRIPTION

Please read L<XAO::Web::Intro> for general overview and setup
instructions.

XAO::Web module provides a frameworks for loading site configuration and
executing objects and templates in the site context. It is used in
scripts and in Apache web server handler to generate actual web pages
content.

Normally a developer does not need to use XAO::Web directly.

=head1 SITE INITIALIZATION

When XAO::Web creates a new site (for mod_perl that happens only once
during each instance on Apache lifetime) it first loads new 'Config'
object using XAO::Objects' new() method and site name it knows. If site
overrides Config - it loads site specific Config, if not - the systme
one.

After the object is created XAO::Web embeds two standard additional
configuration objects into it:

=over

=item hash

Hash object is primarily used to keep site configuration parameters. It
is just a XAO::SimpleHash object and most of its methods get embedded -
get, put, getref, delete, defined, exists, keys, values, contains.

=item web

Web configuration embeds methods that allow cookie, clipboard and
cgi manipulations -- add_cookie, cgi, clipboard, cookies, header,
header_args.

=back

After that XAO::Web calls init() method on the Config object which
is supposed to finish configuration set up and usually stuffs some
parameters into 'hash', then connects to a database and embeds database
configuration object into the Config object as well. Refer to
L<XAO::Web::Intro> for an example of site specific Config object and
init() method.

When object initialization is completed the Config object is placed into
XAO::Projects registry and is retrieved from there on next access to the
same site in case of mod_perl.

=head1 METHODS

Methods of XAO::Web objects include:

=over

=cut

###############################################################################

sub analyze ($@);
sub config ($);
sub execute ($%);
sub new ($%);
sub set_current ($);
sub sitename ($);

###############################################################################

=item analize (@)

Checks how to display the given path. Always returns valid results or
throws an error if that can't be accomplished.

Returns hash reference:

 prefix   => longest matching prefix (directory in case of template found)
 path     => path to the page after the prefix
 fullpath => full path from original query
 objname  => object name that will serve this path
 objargs  => object args hash (may be empty)

=cut
 
sub analyze ($@) {
    my $self=shift;
    my $siteconfig=$self->config;
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
            if(ref($od)) {
                $objname=$od->[0];
                if(scalar(@{$od})%2 == 1) {
                    %args=@{$od}[1..$#{$od}];
                }
                else {
                    eprint "Odd number of arguments in mapping table, dir=$dir, objname=$objname";
                }
            }
            else {
                $objname=$od;
            }
            return {
                objname => $objname,
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
    if(XAO::Templates::check(path => $path)) {
        return {
            objname => ($table && $table->{'/'}) ? $table->{'/'} : 'Page',
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


###############################################################################

=item config ()

Returns site configuration object reference.

=cut

sub config ($) {
    my $self=shift;
    $self->{siteconfig} || throw XAO::E::Web "config - no configuration object";
}

###############################################################################

=item execute (%)

Executes given `path' using given `cgi' environment. Prints results to
standard output and uses CGI object methods to send header.

B<Note:> Execute() is not re-entry safe currently! Meaning that if you
create a XAO::Web object in any method called inside of execute() loop
and then call execute() on that newly created XAO::Web object the system
will fail and no useful results will be produced.

=cut

sub execute ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $cgi=$args->{cgi} || throw XAO::E::Web "execute - no 'cgi' given";
    my $siteconfig=$self->config;
    my $sitename=$self->sitename;

    ##
    # Making sure path starts from a slash
    #
    my $path=$args->{path} || throw XAO::E::Web "execute - no 'path' given";
    $path='/' . $path;
    $path=~s/\/{2,}/\//g;

    ##
    # Setting the current project context to our site.
    #
    $self->set_current();

    ##
    # Resetting page text stack in case it was terminated abnormally
    # before and we're in the same process/memory.
    #
    XAO::PageSupport::reset();

    ##
    # Checking if we have base_url. Guessing it if not.
    # Ensuring that URL does not end with '/'.
    #
    if(! $siteconfig->defined("base_url")) {

        ##
        # Base URL should be full path to the start point -
        # http://host.com in case of rewrite and something like
        # http://host.com/cgi-bin/symphero.pl/sitename in case of
        # plain CGI usage.
        #
        my $url=$cgi->url(-full => 1, -path_info => 0);
        $url=$1 if $url=~/^(.*)($path)$/;

        ##
        # Trying to understand if rewrite module was used or not. If not
        # - adding sitename to the end of guessed URL.
        #
        if($url =~ /cgi-bin/ || $url =~ /xao-[\w-]+\.pl/) {
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
        my $url=$siteconfig->get('base_url');
        $url=~/^http:/i ||
            throw XAO::E::Web "Bad base_url ($url) for sitename=$sitename";
        my $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url => $nu) if $nu ne $url;

        $url=$siteconfig->get('base_url_secure');
        if(!$url) {
            $url=$siteconfig->get('base_url');
            $url=~s/^http:/https:/i;
        }
        $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url_secure => $nu) if $nu ne $url;
    }
  
    ##
    # Checking if we're running under mod_perl
    #
    my $mod_perl=$ENV{MOD_PERL} ? 1 : 0;
    $siteconfig->clipboard->put(mod_perl => $mod_perl);

    ##
    # Putting CGI object into site configuration
    #
    $siteconfig->embedded('web')->enable_special_access;
    $siteconfig->cgi($cgi);
    $siteconfig->embedded('web')->disable_special_access;

    ##
    # Checking for directory index url without trailing slash and
    # redirecting with appended slash if this is the case.
    #
    my @path=split(/\//,$path);
    push(@path,"index.html") if $cgi->path_info =~ /\/$/;
    if($path[-1] !~ /\.\w+$/) {
        my $pd=$self->analyze(@path,'index.html');
        if($pd->{objname} ne 'Default') {
            my $newpath=$cgi->url(-full => 1, -path_info => 1)."/";
            print $cgi->redirect(-url => $newpath),
                  "Document is really <A HREF=\"$newpath\">here</A>.\n";
            return;
        }
    }

    ##
    # Checking existence of the page.
    #
    my $pd=$self->analyze(@path);

    ##
    # Separator for error_log :)
    #
    my @d=localtime;
    my $date=sprintf("%02u:%02u:%02u %u/%02u/%04u",$d[2],$d[1],$d[0],$d[4]+1,$d[3],$d[5]+1900);
    undef(@d);
    dprint "============ date=$date, mod_perl=$mod_perl",
                      ", path='",join('/',@path),"', translated='",$pd->{path},"'";

    ##
    # Putting path decription into the site clipboard
    #
    $siteconfig->clipboard->put(pagedesc => $pd);

    ##
    # We accumulate page content here
    #
    my $pagetext;

    ##
    # Do we need to run any objects before executing? Authorization
    # usually goes here.
    #
    my $autolist=$siteconfig->get('auto_before');
    if($autolist) {
        foreach my $objname (keys %{$autolist}) {
            my $obj=Symphero::Objects->new(objname => $objname);
            $pagetext.=$obj->expand($autolist->{$objname});
        }
    }

    ##
    # Loading page displaying object and executing it.
    #
    my $obj=XAO::Objects->new(objname => 'Web::' . $pd->{objname});
    my %objargs=( path => $pd->{path}
                , fullpath => $pd->{fullpath}
                , prefix => $pd->{prefix}
                );
    @objargs{keys %{$pd->{objargs}}}=values %{$pd->{objargs}} if $pd->{objargs};
    $pagetext.=$obj->expand(\%objargs);

    ##
    # If siteconfig returns us header then it was not printed before and we are
    # expected to print out the page. This is almost always true except when
    # page included something like Redirect object.
    #
    my $header=$siteconfig->header;
    if(defined($header)) {
        print $header,
              $pagetext;
    }

    $siteconfig->cleanup;
}

###############################################################################

=item new (%)

Creates or loads a context for the named site. The only required
argument is 'sitename' which provides the name of the site.

Additionally `cgi' argument can point to a CGI object -- this is useful
mostly in test cases when one does not want to use execute(), but new()
comes handy.

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    ##
    # Getting site name
    #
    my $sitename=$args->{sitename} ||
        throw XAO::E::Web "new - required parameter missing (sitename)";

    ##
    # Loading or creating site configuration object.
    #
    my $siteconfig=XAO::Projects::get_project($sitename);
    if($siteconfig) {
        $siteconfig->cleanup;
    }
    else {
        ##
        # Creating configuration.
        #
        $siteconfig=XAO::Objects->new(sitename => $sitename,
                                      objname => 'Config');

        ##
        # Always embedding at least web config and a hash
        #
        $siteconfig->embed(web => new XAO::Objects objname => 'Web::Config');
        $siteconfig->embed(hash => new XAO::SimpleHash);

        ##
        # Running initialization, this is where parameters are inserted and
        # normally FS::Config gets embedded.
        #
        $siteconfig->init();

        ##
        # Creating an entry in in-memory projects repository
        #
        XAO::Projects::create_project(name => $sitename,
                                      object => $siteconfig,
                                     );
    }

    ##
    # If we are given a CGI reference then putting it into the
    # configuration.
    #
    if($args->{cgi}) {
        $siteconfig->embedded('web')->enable_special_access;
        $siteconfig->cgi($args->{cgi});
        $siteconfig->embedded('web')->disable_special_access;
    }

    ##
    # Done
    #
    bless {
        sitename => $sitename,
        siteconfig => $siteconfig,
    }, ref($proto) || $proto;
}

###############################################################################

=item set_current ()

Sets the current site as the current project in the sense of XAO::Projects.

=cut

sub set_current ($) {
    my $self=shift;
    XAO::Projects::set_current_project($self->sitename);
}

###############################################################################

=item sitename ()

Returns site name.

=cut

sub sitename ($) {
    my $self=shift;
    $self->{sitename} || throw XAO::E::Web "sitename - no site name";
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2001 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Objects>,
L<XAO::Projects>,
L<XAO::DO::Config>.
