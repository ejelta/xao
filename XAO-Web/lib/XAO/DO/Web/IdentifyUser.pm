=head1 NAME

XAO::DO::Web::IdentifyUser - class for user identification and verification

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

IdentifyUser class is used for user identification and verification purposes. In 'login' mode it logs a user in while in 'logout' mode, it logs a user out. In 'check' mode it determines the identification status of the user using cookies.

Possible user identification status are:

=over

=item * anonymous - user cannot be identified

=item * identified - user has been identified

=item * verified - user has recently been positively identified

=back

The 'IdentifyUser' class takes the following parameters:

=over 4

=item * mode

Indicates how 'IdentifyUser' will be used. Possible values are

=over 12

=item - check: (default) check the identification status

=item - login: log user in

=item - logout: Log current user out

=back 

=item * anonymous.path

Template to display if user has not been identified.

=item * identified.path

Template to display if user has been identified, but not verified.

=item * verified.path

Template to display if user has been identified.

=item * hard_logout

If 'true' in logout mode, this parameter not only unverifies the user, but erases identification cookies too. The default is to retain identified status.

=item * stop

Directive indicating that if a specified template is displayed, the remainder of the current template must not be displayed.

=back

The 'IdentifyUser' class relies on some site configuration values. These values are available in the form of reference to a hash obtained as follows:

 my $config=$page->siteconfig->get('identify_user');

where $page is a 'Page' object. The keys of such a hash correspond to the 'type' parameter of the 'IdentifyUser' class. An example of an $config hash with all required parameters is presented below:

{
 customer=>{ 
  list_uri=>'/Customers', 
	id_cookie=>'id_customer',	
	id_cookie_expire=>126230400,#(seconds) optional, default is 4y  
	vf_key_cookie=>'key_customer',#optional, see below
	user_prop=>'email',#optional, see below	
	pass_prop=>'password', 
	vf_key_prop=>'verify_key',#optional, see below 
	vf_time_prop=>'latest_verified_access',	
	vf_expire_time=>'600',#seconds
	cb_uri=>'IdentifyUser/customer' #optional
 }
}

And now describe all parameters step by step

=over

=item list_uri

URI of users list (see L<XAO::FS> and L<XAO::DO::FS::List>).

=item id_cookie

Name of cookie sets to identificate user in a future

=item id_cookie_expire

Expiration time for the identification cookie (default 4 years)

=item vf_key_cookie

See below.

=item user_prop

Name attribute of user object. If there is no 'user_prop' parameter in the configuration it is assumed that user ID is the key for the given list.

=item pass_prop

Password attribute of user object.

=item vf_key_prop

The purpose of two optional parameters 'vf_key_cookie' and 'vf_key_prop' is to limit verification to just one computer at a time. When these parameters are present in the configuration on login success 'IdentifyUser' object generates random key and store it into user's profile anf create a cookie named according to 'vf_key_cookie' with the value of the generated key.

=item vf_time_prop

Attribute of user object which stores the time of latest verified access.

=item vf_expire_time

Time period that user still remain verified.

=item cb_uri

URI of clipboard that stores identification and verification information about user and made it globally available.

=back

=head1 EXAMPLE

Now, let us look at some examples that show how each mode works

=head2 LOGIN MODE

<%IdentifyUser mode="login"
 type="customer"
 username="<%CgiParam param="username" %>
 password="<%CgiParam param="password" %>
 anonymous.path="/bits/login.html"
 verified.path="/bits/thankyou.html"
%>

=head2 LOGOUT MODE

<%IdentifyUser mode="logout"
 type="customer"
 anonymous.path="/bits/thankyou.html"
 identified.path="/bits/thankyou.html"
 hard_logout="<%CgiParam param="hard_logout" %>"
%>

=head2 CHECK MODE

<%IdentifyUser mode="check"
 type="customer"
 anonymous.path="/bits/login.html"
 identified.path="/bits/order.html"
 verified.path="/bits/order.html"
%>

=head1 METHODS

No publicly available methods except overriden display().

There are some private methods (see below). Never use it!

=over

=cut

###############################################################################
package XAO::DO::Web::IdentifyUser;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::E::Web::IdentifyUser);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: IdentifyUser.pm,v 1.1 2001/12/05 22:58:35 am Exp $ =~ /(\d+\.\d+)/);

##
# Displaying some template. Template selecting based on user status.
#
sub display($;%){
	my $self=shift;
	my $args=get_args(\@_);
	for (keys %$args){ $self->{$_} = $args->{$_}; }
	$self->{type} || throw XAO::E::Web::IdentifyUser ref ($self)."::display - no 'type' argument given"; 
	$self->{mode}||="check";
	my $method=$self->{mode};
	$self->$method;
	if ($self->{stop} eq 'true') {
		my $obj=$self->object;
		my $text=$self->{$self->status.".path"}?
							$obj->expand( path=>$self->{$self->status.".path"} ) : '';
		$obj->finaltextout($text);
	}else{
		$self->SUPER::display( path=>$self->{$self->status.".path"} ) if $self->{$self->status.".path"};
	}
}

#############################################################################
# Returns user status or sets it to particular value, 
# not to be call from outside.
# Private method.
#
sub status{
	my $self=shift;
	$self->{status}=shift if @_;
	return $self->{status};
}

##############################################################################

=item login ()

Logs in user. Saves current time to vf_time_prop database field. Generates pseudo unique key and saves it value to vf_key_property (optional). Sets identification cookies.

=cut

sub login{
	my $self=shift;
	my $config=$self->siteconfig->get('identify_user')->{"$self->{type}"};
	my $clipboard_uri=$config->{cb_uri}||"/IdentifyUser/$self->{type}";
	##
	# Identification/Verification
	#
	(my $user=$self->_get_user(1)) || return $self->status('anonymous');
	##
	# Generating key (optional) and saving timestamp
	#
	my $random_key=generate_key;
	$user->put("$config->{vf_key_prop}"=>$random_key) if $config->{vf_key_prop};
	$user->put("$config->{vf_time_prop}"=>time);
	##
	# Setting cookies
	#
	my $expire=$config->{id_cookie_expire}?"+$config->{id_cookie_expire}s":'+4y';
	$self->siteconfig->add_cookie( 
		 -name=>$config->{id_cookie},
		 -value=>$self->{username},
		 -path=>'/',
		 -expires=>$expire);
	$self->siteconfig->add_cookie( 
		 -name=>$config->{vf_key_cookie},
		 -value=>$random_key,
		 -path=>'/',
		 -expires=>"+$config->{vf_expire_time}s") if $config->{vf_key_cookie};

	$self->clipboard->put("$clipboard_uri/username"=>$self->{username});
	$self->clipboard->put("$clipboard_uri/user_object"=>$user);
	$self->clipboard->put("$clipboard_uri/verified"=>1);
	
	$self->status("verified");
}

##############################################################################

=item logout ()

Logs out user. Resetting vf_time_prop database field and clearing identification cookie (for hard logout mode). Set user status to 'anonymous' (hard logout mode) or 'identified'.

=cut

sub logout{
	my $self=shift;
	my $config=$self->siteconfig->get('identify_user')->{"$self->{type}"};
	my $clipboard_uri=$config->{cb_uri}||"/IdentifyUser/$self->{type}";
	##
	# Resetting vf_time_property
	#
	(my $user=$self->_get_user) || return $self->status('anonymous');
	$user->put("$config->{vf_time_prop}"=>'0');
	##
	# Clearing clipboard
	#
	$self->clipboard->delete("$clipboard_uri/username");
	$self->clipboard->delete("$clipboard_uri/user_object");
	$self->clipboard->delete("$clipboard_uri/verified");
	##
	# Clearing cookies (only for hard logout mode)
	#
	my $expire=$config->{id_cookie_expire}?"+$config->{id_cookie_expire}s":'+4y';
	if ($self->{hard_logout} eq 'true'){
		$self->siteconfig->add_cookie(
			-name=>$config->{id_cookie},
			-value=>'none',
			-path=>'/',
			-expires=> $expire);
		$self->siteconfig->add_cookie(
			-name=>$config->{vf_key_cookie},
			-value=>'none',
			-path=>'/',
			-expires=>"+$config->{vf_expire_time}s") if $config->{vf_key_cookie};
		return $self->status('anonymous');
	}
	$self->status('identified');
}

##############################################################################

=item check ()

Checks identification/verification status of the user. 

To determine identification status, first check clipboard to determine if there is such object present. If so, then that object identifies the user. If not, then check whether there is a identification cookie and if so, perform a search for object in database. If this search yields a positive result, the user's status is 'identified' and an attempt to verify user is made, otherwise the status is 'anonymous'.

Once identity is established, to determine verification status, first check the clipboard to determine if there is a 'verified' flag set. If so, then the user's status is 'verified'. If not, check whether the difference between the current time and the time of the latest visit is less than vf_expire_time property. If so, the user status considered 'verified', a new time is stored.

If optional 'vf_key_prop' and 'vf_key_cookie' parameters are present in the configuration then one additional check must be performed before changing status to 'verified' - the content of the key cookie and apropriate field in the user profile must match.

=cut

sub check{
	my $self=shift;
	my $config=$self->siteconfig->get('identify_user')->{"$self->{type}"};
	my $clipboard_uri=$config->{cb_uri}||"/IdentifyUser/$self->{type}";
	
	##################
	# Identification #
	##################
	# Checking clipboard to determine if there is a user object present
	
	my $user=$self->clipboard->get("$clipboard_uri/user_object");
	
	# If a user object does not stores in clipboard check database
	
	($user||=$self->_get_user) || return $self->status('anonymous');

	# Saving identified user to clipboard
	my $username=$self->siteconfig->cgi->cookie(-name=>$config->{id_cookie});
	$self->clipboard->put("$clipboard_uri/username" => $username);
	$self->clipboard->put("$clipboard_uri/user_object" => $user);
	
	$self->status('identified');
	
	################
	# Verification #
	################
	# Checking clipboard to determine if there is 'verified' flag set and
	# if so user's status is 'verified'
	
	return $self->status('verified') if $self->clipboard->get("$clipboard_uri/verified");
	
	# If not, checking the difference between the current time 
	# and the time of last visit
	
	return $self->status if (time-$user->get($config->{vf_time_prop})>$config->{vf_expire_time});
	
	# If optional 'vf_key_prop' and 'vf_key_cookie' parameters are present
	# checking the content of key cookie and appropriate field 
	# in the user profile
	
	if ($config->{vf_key_prop} && $config->{vf_key_cookie}) {
		my $c=$self->siteconfig->cgi->cookie(-name=>$config->{vf_key_cookie});
		return $self->status if $c ne $user->get($config->{vf_key_prop});
	}
	
	$user->put("$config->{vf_time_prop}" => time);
	$self->clipboard->put( "$clipboard_uri/verified" => 1 );
	
	$self->status('verified');
}

##############################################################################

=item _get_user ($;$)

Searches user in list. There are two modes available for this method: 0 (default) and 1.

 my $user=$self->_get_user(1);

or 

 my $user=$self->_get_user();

In first case user searching will be completed with a password checking. In the second password is not significant.

Returns user object or 0 in case this user absent or password not match (mode 1).

=cut

sub _get_user($;$){
	my $self=shift;
	my $mode=$_[0]||0;
	my $user;
	my $config=$self->siteconfig->get('identify_user')->{"$self->{type}"};
	$self->{username}=$self->siteconfig->cgi->cookie(-name=>$config->{id_cookie})  unless $mode;
#	$self->finaltextout($self->{username});
#	return;
	my $list=$self->odb()->fetch($config->{list_uri});
	if ($config->{user_prop}){
		my $users;
		if ($mode){
			$users=$list->search(
				[$config->{user_prop},'eq',$self->{username}],
				'and',
				[$config->{pass_prop},'eq',$self->{password}]);
		}else{
			$users=$list->search( [$config->{user_prop},'eq',$self->{username}] );
		}
		return 0 unless (@$users);
		$user = $list->get($users->[0]);
	}else{
		return 0 unless $list->exists($self->{username});
		$user = $list->get($self->{username});
		return 0 if ($mode && $user->get($config->{pass_prop}) ne $self->{password});
	}
	return $user;
}

##############################################################################
# That's all
#
1;
__END__

=back

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2001 XAO, Inc.

Ilya Lityuga <ilya@boksoft.com>

=head1 SEE ALSO

Recommended reading:

L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::FS>.

