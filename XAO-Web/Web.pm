# Dummy module to allow using 'install XAO::Web' in CPAN shell, also
# contains package version and documentation.
###############################################################################
package XAO::Web;

##
# XAO::Web version number. Hand changed with every release!
#
use vars qw($VERSION);
$VERSION='0.9';

###############################################################################
1;
__END__

=head1 NAME

XAO::Web - web rendering part of XAO E-Commerce suite

=head1 SYNOPSIS

None, see the description below and individual manpages.

=head1 DESCRIPTION

XAO::Web is a part of XAO open source e-commerce suite. It can
also be used as a general purpose web templating system that allows you
to create arbitrary complex web pages and process them in rather optimal
way.

Most interesting features of XAO::Web are:

=over

=item *

Perl code is not mixed with templates. Templates can be normal HTML
files if no processing is required.

=item *

Site can replace or modify standard XAO::Web objects if required
by overriding or extending their methods. You do not need to
re-implement entire object to make a site specific change.

=item *

Site can create any extension objects or embed third-party extensions
as well.

=item *

One server can serve arbitrary number of XAO::Web sites each
with however extended functionality without creating any conflicts.

=item *

There are standard objects that support e-commerce functionality that
is enough to implement amazon-style e-commerce sites relatively
easy. That includes credit card authorization, strong cryptography,
users database, products database, orders database, shipping tracking
and so on.

=item *

Works with CGI or mod_perl (mod_perl is recommended for production
grade sites).

=item *

If used in mod_perl mode improves performance by using caching of
configuration, parsed templates, database handlers and so on.

=back

=head1 INSTALLATION

Install it in the usual way, just say:

  perl Makefile.PL
  make
  make test
  make install

Saying "install XAO::Web" from CPAN shell is a good way too.

When you run "perl Makefile.PL" you will be asked for XAO::Web home
directory. Feel free to point it somewhere inside your home directory
if you do not feel like modifying /usr/local/symphero (suggested
default). This is a directory where symphero.pl CGI and mod_perl handler
would be placed along with default site and default templates. That
means that entire path to that directory should be world-readable (or at
least web-server readable).

I<NOTE:> On FreeBSD 4.x (or probably with just some older version of
MakeMaker) there is a problem with installing to /usr/local/symphero -
somehow MakeMaker translates it to $(PREFIX)/symphero and PREFIX is
/usr. I do not yet have a solution for that other then installing it
somewhere outside /usr/local.

=head1 FIRST-TIME RUNNING AND TESTING

After you installed XAO::Web you can try it in web
environment. Configure your Apache server so that it would execute
(from now on I assume that XAO::Web was installed into
/usr/local/symphero) /usr/local/symphero/cgi-bin/symphero.pl when
someone types URL like http://company.com/cgi-bin/symphero.pl. Here is
an example of virtual host configuration for that (or you can simply
move or sym-link symphero.pl to your existing cgi-bin directory if you
have one):

 <VirtualHost 10.0.0.1:80>
  ServerName   test.company.com
  ServerAlias  test.company.com
 
  ScriptAlias /cgi-bin/ /usr/local/symphero/cgi-bin/
 </VirtualHost>

After you configure and re-start your web-server point your browser at
http://test.company.com/cgi-bin/symphero.pl/docsite/ -- you should be
able to see "docsite" content. To see simplest possible site that does
not even have its own templates go to
http://test.company.com/cgi-bin/symphero.pl/emptysite/

You do not have to use that "/cgi-bin/sitename/" garbage, it was only
here to demonstrate the idea. In normal circumstances you would want to
use Apache "rewrite" module to map everything or almost everything to be
processed by symphero.pl. Here is an example (note, that you cannot use
ScriptAlias if you use mod-rewrite, you have to change it to <Directory>
with explicitly set handler and options):

 <VirtualHost 10.0.0.1:80>
  ServerName   test.company.com
  ServerAlias  test.company.com
 
  <Directory /usr/local/symphero/cgi-bin>
   Options ExecCGI
   SetHandler cgi-script
  </Directory>

  RewriteEngine on
  RewriteRule   ^/images/(.*)$  \
                /usr/local/symphero/projects/docsite/images/$1  \
                [L]
  RewriteRule   ^/(.*)$  \
                /usr/local/symphero/cgi-bin/symphero.pl/docsite/$1  \
                [L]
 </VirtualHost>

That leaves everything in /images/ to be processed by web server in the
usual way and maps everything else to symphero.pl. Try going to just
http://test.company.com/ now and see the difference.

And finally, here is an example of mod_perl configuration. Please
replace ScriptAlias with the following:

 <Directory   /usr/local/symphero/cgi-bin>
  Options +ExecCGI
  SetHandler perl-script
  PerlHandler Apache::Registry
  PerlSendHeader Off
 </Directory>
 
I am currently working on pure Apache mod_perl handler that will be
faster then using Apache::Registry and would not require mod_rewrite to
rewrite paths. Keep tuned.

=head1 SITE DEVELOPMENT

Here is a couple of steps to start development of a new site:

=over

=item 1

Choose a name for your site. It have to start with a B<lowercase letter> and
may contain letters, digits and underscore sign. Let's assume you've
chosen "mysite" as a name.

=item 2

Create sub-directory in /usr/local/symphero/projects with the name of
your site (/usr/local/symphero/projects/mysite in our case). This
directory is home directory of your site. Everything else below is
relative to that directory.

=item 3

Create subdirectory named 'modules'. Place configuration file called
'Config.pm' inside of it. There are two requirements for that file:

=over

=item *

It have to be in the specific namespace --
XAO::Objects::mysite::Config, where mysite is your site name.

=item *

It have to be based on "XAO::SiteConfig" object.

=item *

It have to define "init" method that will initialize site
configuration. In mod_perl environment that method will be called only
once when the site is initialized first time. That means that init() is
a good place to open connection to a database and it is recommended to
do that as most of XAO modules require database connection to work
properly.

=back

Here is an example of configuration module Config.pm for "mysite" site:

 # Configuration for mysite
 package XAO::Objects::mysite::Config;
 use strict;
 use vars qw(@ISA);
 use XAO::SiteConfig;
 use DBI;
 use DBD::mysql;

 ##
 # Inheritance
 #
 use vars qw(@ISA);
 @ISA=qw(XAO::SiteConfig);

 ##
 # Site configuration values. A lot of stuff can be stored
 # here for different modules.
 #
 my %data=
 ( base_url =>		"http://test.company.com"
 , base_url_secure =>	"http://test.company.com"
 );

 ##
 # Initializing configuration object for our site.
 #
 sub init
 { my $self=shift;

   ##
   # Putting initialization data into configuration.
   #
   $self->fill(\%data);

   ##
   # Initializing database
   #
   $self->dbconnect(db_dsn => 'DBI:mysql:mysite'
                   ,db_user => 'mysite'
                   ,db_pass => 'SuperPassword'
                   );
 }

 ##
 # That's it
 #
 1;

=item 4

At that time you should already be able to see
your new site in your browser. Just point it to
http://test.company.com/cgi-bin/symphero.pl/mysite/

But in order to do something useful you need to create two more
directories: "objects" and "templates".

"Objects" will contain your site-specific extensions for system objects and
your new objects.

"Templates" will contain your site templates.

Nothing else is used by symphero.pl and usually you would also create
directories like "images" or "static"; put your site to CVS version
control or make some kind of installation tools for it. It is all up to
you.

=back

This is it. You should probably start from playing with "foocom" example
e-commerce site before creating your new site.

=head1 CORE CODE DEVELOPMENT

If you plan to make changes to the XAO::Web code (which is not
recommended unless you participate in official development) please read
devsite/README for instructions.

=head1 AUTHOR

Brave New Worlds, Andrew Maltsev <am@xao.com>. Creating of XAO::Web
would not be possible without valuable comments and ideas from everybody
on our team and especially from Bil Drury, Marcos Alves, Brian Despain
and Jason Shupe. Thank you guys!

=head1 SEE ALSO

Recommended reading:
L<symphero.pl>,
L<XAO::Categories>,
L<XAO::Objects>,
L<XAO::OrdersDB>,
L<XAO::ProductsDB>,
L<XAO::SiteConfig>,
L<XAO::Templates>,
L<XAO::UsersDB>,
L<XAO::Data>.

=cut
