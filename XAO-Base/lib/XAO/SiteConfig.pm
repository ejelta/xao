=head1 NAME

Symphero::SiteConfig - Base object for Symphero::Web site configuration

=head1 SYNOPSIS

Currently is only useful in Symphero::Web site context.

=head1 DESCRIPTION

This object holds all site-specific configuration values and provides
various useful methods that are not related to any particular
displayable object (see L<Symphero::Objects::Page>).

In mod_perl context this object is initialized only once for each apache
process and then is re-used every time until that process
die. SiteConfig keeps a cache of all site configurations and makes them
available on demand. It is perfectly fine that one apache process would
serve more then one site, they won't step on each other toes.

=head1 UTILITY FUNCTIONS

Symphero::SiteConfig provides some utility functions that do not require
any configuration object context.

=over

=cut

###############################################################################
package Symphero::SiteConfig;
use strict;
use Carp;
use Symphero::Utils;
use DBI;
use Error;

##
# Static methods.
#
sub find ($$);
sub get_site_config ();
sub get_site_name ();
#
# Private methods
#
sub _data ($);
#
# Configuration object specific methods additional to derived from
# SimpleHash.
#
sub new ($@);
sub add_cookie ($@);
sub cgi ($$);
sub cleanup ($);
sub cookies ($);
sub dbconnect ($%);
sub dbh ($$);
sub disable_special_access ($);
sub enable_special_access ($);
sub fixate ($);
sub header ($@);
sub header_args ($@);
sub init ($);
sub permanent ($@);
sub session_specific ($@);
sub set_current ($);
sub sitename ($);

##
# Package version for checks and reference
#
use vars qw($VERSION);
($VERSION)=(q$Id: SiteConfig.pm,v 1.1 2001/10/23 00:45:09 am Exp $ =~ /(\d+\.\d+)/);

##
# Deriving form SimpleHash and Exporter
#
use Symphero::SimpleHash;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA=qw(Symphero::SimpleHash Exporter);
@EXPORT=qw(get_site_name get_site_config);

##
# Container for all individual site configurations, each of those is
# SimpleHash object.
#
use vars qw(%data_objects);

###############################################################################

=item find ($;$)

Looks into pre-initialized configurations list and returns object if
found or undef if not.

Example:

 my $cf=Symphero::SiteConfig->find('testsite');

You do not normally need to use this function. It is called from
symphero.pl handler to find or initialize current site configuration.
After that the configuration is available by a simple call to
get_site_config() without any parameters. And more then that, inside of
displayable objects it is recommended to use $self->siteconfig() method
to get site configuration.

=cut

sub find ($$)
{ my ($class,$sitename)=@_;
  if(!$sitename && !ref($class) && $class =~ /^[a-z]/)
   { $sitename=$class;
   }
  $data_objects{$sitename};
}

###############################################################################

=item get_site_config ()

Returns current site configuration object or undef if it is not defined.

=cut

my $current_site_config;    # package private variable with current site config

sub get_site_config () {
    $current_site_config;
}

###############################################################################

=item get_site_name ()

Returns current site name and throws Symphero::Errors::SiteConfig error
if it is not available. That means that normally you should not care, it
will always return a correct value to you.

Example:

 use Symphero::SiteConfig;

 my $sitename=get_site_name();

=cut

sub get_site_name () {
    $current_site_config ||
        throw Symphero::Errors::SiteConfig "get_site_name() called before site has been defined";
    $current_site_config->sitename;
}

###############################################################################

=back (for utility functions)

=head1 METHODS

Symphero::SiteConfig is a Symphero::SimpleHash with all its methods also
available through inheritance (see L<Symphero::SimpleHash>).

After you got a configuration object by either calling to siteconfig()
method of any displayable object or by calling get_site_config() outside
of a displayable object you can call the following methods on it:

=over

=cut

###############################################################################

=item new ($$)

Creates and blesses new configuration object with given site
name. Accepts only one argument - site name. That site name must match
object namespace -- Symphero::Objects::sitename::Config.

Normally you should not override that method or call it directly. Any
initialization that you need you should do in overridden init() method
instead.

Configuration object for a site is created in symphero.pl handler for
each site when it is first called.

Argument can either be alone or in hash (sitename => $sitename).

=cut

sub new ($@) {
    my $proto=shift;
    my $sitename;
    if(@_ == 1 && !ref($_[0])) {
        $sitename=shift;
    }
    else {
        my $args=get_args(\@_);
        $sitename=$args->{sitename};
    }
    $sitename || throw Symphero::Errors::SiteConfig "new - no sitename given";

    return $data_objects{$sitename} if $data_objects{$sitename};

    ##
    # What class we actually are?
    #
    my $class=ref($proto) || $proto;
    if($class ne "Symphero::Objects::${sitename}::Config") {
        throw Symphero::Errors::SiteConfig
              "$class::new -- class name does not match site name ($sitename)";
    }

    ##
    # A bit of magic here to create an instance of SimpleHash so that it
    # will think it is an instance of Symphero::SiteConfig.
    #
    my $self=Symphero::SimpleHash::new($class);
    $data_objects{$sitename}=$self;

    ##
    # Pre-filling the hash
    #
    $self->fill(sitename => $sitename,
                _data => { crtime => time,
                           class => $class,
                         }
               );

    ##
    # This is supposed to be overriden in every site config
    #
    $self->init();

    ##
    # Fixing current configuration for permanent storage
    #
    $self->fixate();

    ##
    # Returning self-reference
    #
    $self;
}

###############################################################################
# Returns internal data hash, not to be called from outside.
# Private method.
#
sub _data ($) {
    my $self=shift;
    $self->get('_data');
}

###############################################################################

=item add_cookie (@)

Adding an HTTP cookie into the internal list. If there is only one
parameter we assume it is already encoded cookie, otherwise we assume it
is a hash of parameters for CGI->cookie method (see L<CGI>).

If a cookie with that name is already in the list (from previous call to
add_cookie) it gets replaced. This check is only performed if you pass a
hash of arguments, not already prepared cookie.

Think of it as if you're adding cookies to you final HTTP response as
symphero.pl handler will get all the cookies collected during template
processing and send them out for you.

Examples:

 $self->siteconfig->add_cookie($cookie);

 $self->siteconfig->add_cookie(-name => 'sessionID',
                               -value => 'xyzzy',
                               -expires=>'+1h');

=cut

sub add_cookie ($@)
{ my $self=shift;
  my $cookie=(@_==1 ? $_[0] : get_args(\@_));
  
  ##
  # If new cookie has the same name, domain and path
  # as previously set one - we replace it. Works only for
  # cookies stored as parameters, unprepared.
  #
  if($self->_data->{cookies} && ref($cookie) && ref($cookie) eq 'HASH')
   { for(my $i=0; $i!=@{$self->_data->{cookies}}; $i++)
      { my $c=$self->_data->{cookies}->[$i];
        next unless ref($c) && ref($c) eq 'HASH';
        next unless $c->{-name} eq $cookie->{-name} &&
                    $c->{-path} eq $cookie->{-path} &&
                    $c->{-domain} eq $cookie->{-domain};
        $self->_data->{cookies}->[$i]=$cookie;
        return $cookie;
      }
   }
  push @{$self->_data->{cookies}},$cookie;
}

###############################################################################

=item cgi (;$)

Returns or sets standard CGI object (see L<CGI>). In future versions this
would probably be converted to CGI::Lite or something similar, so do not
relay to much on the functionality of CGI.

Obviously you should not call this method to set CGI object unless you
are 100% sure you know what you're doing.

Example:

 my $cgi=$self->siteconfig->cgi;
 my $name=$cgi->param('name');

Or better yet, as cgi method also exists in Symphero::Objects::Page
object:

 my $cgi=$self->cgi;
 my $name=$cgi->param('name');

Or just:

 my $name=$self->cgi->param('name');

=cut

sub cgi ($$)
{ my ($self,$newcgi)=@_;
  my $data=$self->_data;
  return $data->{cgi} unless $newcgi;
  if($data->{special_access})
   { $data->{cgi}=$newcgi;
     return $newcgi;
   }
  throw Symphero::Errors::SiteConfig "$data->{class}::cgi() Storing new CGI requires allow_special_access()";
}

###############################################################################

=item cleanup ()

It is a common practice (probably not the best and cleanest, but still
common) to put some temporary values to the site configuration -- like
logged user name, order object reference and so on. Site configuration
object is used as a suitable place where displayable objects exchange
data between themselves.

In order to make this safe at the end of every session all parameters
added to the configuration during that session and not marked as
permanent by calling permanent() method are removed by cleanup()
method. Otherwise your logged user name or order data could become
available for the next session of the same site executed by the same
process under mod_perl. This could lead to exposing one user's data to
another.

Always wipes out cookies, CGI object handler and some internal variables
too and cleans current site configuration if it references current
object. Subsequent call to get_site_config() function will
fail. Configuration object itself is not very useful for the current
session after the call to cleanup().

Cleanup() method is called automatically at the end of each session, you
do not need to worry about it normally.

=cut

sub cleanup ($)
{ my $self=shift;
  my $data=$self->_data;
  delete $data->{cgi};
  delete $data->{cookies};
  delete $data->{header_printed};
  delete $data->{header_args};
  delete $data->{special_access};
  delete $data->{fixated};
  my %perm=map { $_ => 1 } @{$data->{permanent}};
  foreach my $key ($self->keys())
   { $self->delete($key) unless $perm{$key};
   }
  $current_site_config=undef;
}

###############################################################################

=item cookies ()

Returns reference to the array of prepared cookies.

=cut

sub cookies ($)
{ my $self=shift;
  my @baked;
  foreach my $c (@{$self->_data->{cookies}})
   { if(ref($c) && ref($c) eq 'HASH')
      { push @baked,$self->cgi->cookie(%{$c});
      }
     else
      { push @baked,$c;
      }
   }
  \@baked;
}

###############################################################################

=item dbconnect (%)

I<Should be considered obsolete by odbconnect().>

Connects to a database using DBI interface (see L<DBI>) and stores the
handler it gets permanently. That handler would be returned any time you
call dbh() method.

If it cannot connect to the database it throws
Symphero::Errors::SiteConfig error that you can catch if you want.

Arguments are:

 db_dsn => DSN (like DBI:mysql:database)
 db_user => User name
 db_pass => Password

Puts these values into configuration `hash' also on success.

The intended use is in overridden init() method for site configuration:

 sub init () {
     my $self=shift;
     $self->fill(\%site_configuration);
     $self->dbconnect(db_dsn => 'DBI:mysql:mysite',
                      db_user => 'me',
                      db_pass => 'mysecretpass'
                     );
 }

=cut

sub dbconnect ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $dbh=DBI->connect($args->{db_dsn},$args->{db_user},$args->{db_pass});
  $dbh || throw Symphero::Errors::SiteConfig ref($self)."::dbconnect - can't connect to the database";
  $self->fill($args);
  $self->enable_special_access();
  $self->dbh($dbh);
  $self->disable_special_access();
  $dbh;
}

###############################################################################

=item dbh (;$)

Returns or sets database handler for the current site configuration. If
you asked it for database handler and it was not created during site
initialization dbh() method will throw Symphero::Errors::SiteConfig
error.

Normally you can assume that if you need DBH you get it.

Example:

 my $db=Symphero::MultiValueDB->new(dbh => $self->siteconfig->dbh,
                                    table => "test");

Dbh() method is also duplicated in Symphero::Objects::Page and therefor
is available from all displayable objects by simply saying:

 my $db=Symphero::MultiValueDB->new(dbh => $self->dbh,
                                    table => "test");

=cut

sub dbh ($$)
{ my ($self,$newdbh)=@_;
  my $data=$self->_data;
  if($newdbh)
   { if($data->{special_access})
      { $data->{dbh}=$newdbh;
        return $newdbh;
      }
     throw Symphero::Errors::SiteConfig
           ref($self)."::dbh - Storing new DBH requires allow_special_access()";
   }
  $data->{dbh} || throw Symphero::Errors::SiteConfig ref($self)."::dbh - no DBH available";
}

###############################################################################

=item disable_special_access ()

Disables use of dbh() and cgi() methods to set values.

=cut

sub disable_special_access ($)
{ my $self=shift;
  delete $self->_data->{special_access};
}

###############################################################################

=item enable_special_access ()

Enables use of dbh() and cgi() methods to set values. Normally you do
not need this method.

Example:

 $config->enable_special_access();
 $config->dbh($newdbh);
 $config->disable_special_access();

=cut

sub enable_special_access ($)
{ my $self=shift;
  $self->_data->{special_access}=1;
}

###############################################################################

=item fixate ()

Fixates parameters that are now in the configuration object as
permanent. Any parameters added later in the session would be cleaned
when the session ends.

This method can only be called once, subsequent calls will do
nothing. Think of it as "private" method which you should never use. It
will be called for you from new() after call to init().

See also permanent() method.

=cut

sub fixate ($)
{ my $self=shift;
  my $data=$self->_data;
  return undef if $data->{fixated};
  push @{$data->{permanent}}, $self->keys();
  $data->{fixated}=1;
}

###############################################################################

=item header (@)

Returns HTTP header. The same as $cgi->header and accepts the same
parameters. Cookies added before by add_cookie() method are also
included in the header.

Returns header only once, on subsequent calls returns undef.

B<NOTE:> In mod_perl environment CGI will send the header itself and
return empty string. Be carefull to check the result for
C<if(defined($header))> instead of just C<if($header)>!

As with the most of SiteConfig methods you do not need this method
normally. It is called automatically by symphero.pl handler at the end
of a session before sending out its results.

=cut

sub header ($@)
{ my $self=shift;
  my $data=$self->_data;
  return undef if $data->{header_printed};
  $self->header_args(@_) if @_;
  $data->{header_printed}=1;
  $self->cgi->header(-cookie => $self->cookies,
                     %{$data->{header_args}}
                    );
}

###############################################################################

=item header_args (%)

Sets some parameters for header generation. You can use it to change
page status for example:

 $config->header_args(-Status => '404 File not found');

Accepts the same arguments CGI->header() accepts.

=cut

sub header_args ($@)
{ my $self=shift;
  my $args=get_args(\@_);
  my $data=$self->_data;
  @{$data->{header_args}}{keys %{$args}}=values %{$args};
}

###############################################################################

=item init ()

Pure virtual method that is supposed to initialize configuration
object. Should be overridden in every site's configuration object.

Complete example of site configuration object implementation:

 package Symphero::Objects::testsite::Config;
 use strict;
 use Symphero::SiteConfig;

 use vars qw(@ISA);
 @ISA=qw(Symphero::SiteConfig);

 ##
 # Configuration data
 #
 my %data = (
     base_url => 'http://testsite.com',
     base_url_secure => 'https://secure.testsite.com'
 );

 ##
 # Init method would be called only once.
 #
 sub init ($) {
     my $self=shift;
     $self->fill(\%data);
 }

 ##
 # That's it
 #
 1;

=cut

sub init ($)
{ my $self=shift;
  carp ref($self),"::init - pure virtual function called";
}

###############################################################################

=item odbconnect (%)

Connects to the Object Database (see L<Symphero::OS>) using given DSN,
user name and password. That handler would be returned any time you call
odb() method later.

If it cannot connect to the database it throws
Symphero::Errors::SiteConfig error that you can catch if you want.

Arguments are:

 db_dsn  => DSN (like OS:MySQL_DBI:database;hostname=dbserver.host.com)
 db_user => User name
 db_pass => Password

Puts these values into configuration `hash' also on success.

The intended use is in overridden init() method for site configuration:

 sub init () {
     my $self=shift;
     $self->fill(\%site_configuration);
     $self->odbconnect(odb_dsn => 'OS:MySQL_DBI:mysite',
                       odb_user => 'me',
                       odb_pass => 'mysecretpass'
                      );
 }

Database must already exist and be in consistent state. Otherwise an
error will be thrown from the object server,

=cut

sub odbconnect ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $odb=Symphero::Objects->new(objname => 'Data::System::Glue',
                                   dsn => $args->{odb_dsn},
                                   user => $args->{odb_user},
                                   password => $args->{odb_password} ||
                                               $args->{odb_pass});
    $odb || throw Symphero::Errors::SiteConfig
                  ref($self)."::odbconnect - can't connect to the object database ($args->{odb_dsn})";

    $self->enable_special_access();
    $self->odb($odb);
    $self->disable_special_access();

    $odb;
}

###############################################################################

=item odb (;$)

Returns or sets object database handler for the current site
configuration. If you asked for database handler and it was
not created during site initialization the method will throw
a Symphero::Errors::SiteConfig error.

Example:

 my $customers=$self->siteconfig->odb->fetch('/Customers');

Odb() method is also duplicated for convenience in
Symphero::Objects::Page and therefore is available from all displayable
objects by simply saying:

 my $customers=$self->odb->fetch('/Customers');

=cut

sub odb ($$) {
    my ($self,$newodb)=@_;
    my $data=$self->_data;

    if($newodb) {
        if($data->{special_access}) {
            $data->{odb}=$newodb;
            return $newodb;
        }
        throw Symphero::Errors::SiteConfig
              ref($self)."::odb - Storing new ODB requires allow_special_access()";
    }

    $data->{odb} || throw Symphero::Errors::SiteConfig
                          ref($self)."::odb - no ODB available";
}

###############################################################################

=item permanent (@)

Adds new parameter names to the list of parameters that would be kept
between sessions. Normally this is not what you want to do, be very very
careful with that or you can break site's security.

Configuration object is supposed to carry between sessions only site
configuration values that are global and common for all apsects of the
specific site. No parts of user setup, accounts or any personal data
should ever be made permanent. Although it is common practice to put
such values to the configuration temporary.

All values that you add during the session and did not mark as "permanent"
will be removed at the end of that session.

The only good case for use of permanent() method that I can see is that
you have some part of the site that is rarely visited and that requires
some additional database handler or some hard to dynamic table that is
hard to calculate and that is common for the entire site. In that case
you can opt to not initialize that data in init() but wait until someone
gets to that part of the site and initialize it then.

Otherwise, just put all your permanent data into configuration object
in init() and do not worry much about it, everything you put in init()
automatically becomes permanent.

Example:

 $config->put(mydata => some_rarely_used_piece_of_data());
 $config->permanent('mydata');

=cut

sub permanent ($@)
{ my $self=shift;
  push(@{$self->_data->{permanent}},@_);
}

###############################################################################

=item session_specific (@)

Adds a list of parameter names to the list of parameters that would be
purged from the configuration at the end of the current session.

B<This method is now deprecated> as all parameters added after a call
to the fixate() method are considered session specific by default.

=cut

sub session_specific ($@)
{ my $self=shift;
  my $data=$self->_data;
  return undef unless $data->{permanent};
  my %a=map { $_ => 1 } @{$data->{permanent}};
  delete @a{@_};
  $data->{permanent}=[keys %a];
}

###############################################################################

=item set_current ()

Sets default configuration to the current object. This object would be
returned by calls to get_current_config() after that.

Again, normally you do not need this method.

=cut

sub set_current ($)
{ my $self=shift;
  unless($self && ref($self))
   { carp "SiteConfig::set_current must be called on reference";
     return;
   }
  $current_site_config=$self;
}

###############################################################################

=item sitename ()

Returns sitename for the object.

=cut

sub sitename ($)
{ my $self=shift;
  $self->get("sitename");
}

##
# Error package for MultiValueDB.
#
package Symphero::Errors::SiteConfig;
use Error;
use vars qw(@ISA);
@ISA=qw(Error::Simple);

sub throw ($$) {
    my $self=shift;
    my $text=shift;
    $self->SUPER::throw("Symphero::Objects::" . $text);
}

##
# That's it
#
1;
__END__

=back

=head1 EXPORTS

get_site_name(), get_site_config().

=head1 AUTHOR

Brave New Worlds, Inc.: Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<Symphero::Web>,
L<Symphero::Page>.
