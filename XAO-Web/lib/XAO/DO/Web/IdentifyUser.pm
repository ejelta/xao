=head1 NAME

XAO::DO::Web::IdentifyUser - class for user identification and verification

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

IdentifyUser class is used for user identification and verification
purposes. In 'login' mode it logs a user in while in 'logout' mode, it
logs a user out. In 'check' mode it determines the identification status
of the user using cookies.

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

If 'true' in logout mode, this parameter not only unverifies the
user, but erases identification cookies too. The default is to retain
identified status.

=item * stop

Directive indicating that if a specified template is displayed, the
remainder of the current template must not be displayed.

=back

The 'IdentifyUser' class relies on some site configuration values. These
values are available in the form of a reference to a hash obtained as
follows:

 my $config=$page->siteconfig->get('identify_user');

where $page is a 'Page' object. The keys of such a hash correspond to
the 'type' parameter of the 'IdentifyUser' class. An example of a
$config hash with all required parameters is presented below:

 customer => { 
    list_uri            => '/Customers', 
    id_cookie           => 'id_customer',    
    id_cookie_expire    => 126230400,       # (seconds) optional,
                                            # default is 10 years
    user_prop           => 'email',         # optional, see below    
    pass_prop           => 'password', 
    pass_encrypt        =>  'md5',          # optional, see below
    vf_key_prop         => 'verify_key',    # optional, see below 
    vf_key_cookie       => 'key_customer',  # optional, see below
    vf_time_prop        => 'verify_time',   # time of last verification
    vf_expire_time      => '600',           # seconds
    cb_uri              => 'IdentifyUser/customer' # optional
 }

=over

=item list_uri

URI of users list (see L<XAO::FS> and L<XAO::DO::FS::List>).

=item id_cookie

Name of cookie that IdentifyUser sets to identificate the user in the
future

=item id_cookie_expire

Expiration time for the identification cookie (default is 4 years).

=item user_prop

Name attribute of a user object. If there is no 'user_prop' parameter in
the configuration it is assumed that user ID is the key for the given
list.

An interesting capability is to specify name as a URI style path, for
instance if a member has many alternative names that all can be used to
log-in and these names are stored in a list called Nicknames on each
member object, then the following might be used:

 user_prop => 'Nicknames/nickname'

=item pass_prop

Password attribute of user object.

=item pass_encrypt

Encryption method for the password. Available values are 'plaintext'
(not encrypted at all, default) and 'md5' (MD5 one way hash encryption.

=item vf_key_prop

The purpose of two optional parameters 'vf_key_cookie' and 'vf_key_prop'
is to limit verification to just one computer at a time. When
these parameters are present in the configuration on login success
'IdentifyUser' object generates random key and store it into user's
profile anf create a cookie named according to 'vf_key_cookie' with the
value of the generated key.

=item vf_key_cookie

Temporary verifiction key cookie.

=item vf_time_prop

Attribute of user object which stores the time of latest verified access.

=item vf_expire_time

Time period for which user remains verified.

Please note, that the cookie with the customer key will be set to expire
in 10 years and actual expiration will only be checked using the content
of 'vf_time_prop' field value. The reason for such behavior is that many
(if not all) versions of Microsoft IE have what can be considered a
serious bug -- they compare the cookie expiration time to the local time
on the computer. And therefore if customer computer is accidentally set
to some future date the cookie might expire immediately and prevent this
customer from logging into the system at all. Most (if not all) versions
of Netscape and Mozilla do not have this problem.

Therefore, when possible we do not trust customer's computer to measure
time for us and do that ourselves.

=item cb_uri

URI of clipboard where IdentifyUser stores identification and
verification information about user and makes it globally available.

=back

=head1 EXAMPLE

Now, let us look at some examples that show how each mode works.

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

=over

=cut

###############################################################################
package XAO::DO::Web::IdentifyUser;
use strict;
use Digest::MD5 qw(md5_base64);
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::IdentifyUser);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
($VERSION)=(q$Id: IdentifyUser.pm,v 1.16 2002/11/09 02:22:15 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item check_mode (%)

Checks operation mode and redirects to a method accordingly.

=cut

sub check_mode($;%){
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'check';

    if($mode eq 'check') {
        $self->check($args);
    }
    elsif($mode eq 'login') {
        $self->login($args);
    }
    elsif($mode eq 'logout') {
        $self->logout($args);
    }
    else {
        throw XAO::E::DO::Web::IdentifyUser "check_mode - no such mode '$mode'";
    }
}

##############################################################################

=item check ()

Checks identification/verification status of the user. 

To determine identification status, first check clipboard to determine
if there is such object present. If so, then that object identifies the
user. If not, then check whether there is a identification cookie and
if so, perform a search for object in database. If this search yields
a positive result, the user's status is 'identified' and an attempt to
verify user is made, otherwise the status is 'anonymous'.

Once identity is established, to determine verification status, first
check the clipboard to determine if there is a 'verified' flag set. If
so, then the user's status is 'verified'. If not, check whether the
difference between the current time and the time of the latest visit is
less than vf_expire_time property. If so, the user status considered
'verified', a new time is stored.

If optional 'vf_key_prop' and 'vf_key_cookie' parameters are present in
the configuration then one additional check must be performed before
changing status to 'verified' - the content of the key cookie and
apropriate field in the user profile must match.

=cut

sub check {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw XAO::E::DO::Web::IdentifyUser "check - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw XAO::E::DO::Web::IdentifyUser "check - no 'type' given";
    $config=$config->{$type} ||
        throw XAO::E::DO::Web::IdentifyUser "check - no 'identify_user' configuration for '$type'";
    my $clipboard=$self->clipboard;

    ##
    # Checking clipboard to determine if there is a user object present
    #
    my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    my $user=$clipboard->get("$cb_uri/object");
    my $username=$clipboard->get("$cb_uri/name");

    ##
    # If there is no user in the clipboard - trying database.
    #
    if(!$user || !$username) {
        my $id_cookie=$config->{id_cookie} ||
            throw XAO::E::DO::Web::IdentifyUser "check - no 'id_cookie' in the configuration";
        $username=$self->cgi->cookie($id_cookie);
        if($username) {
            $user=$self->find_user($config,$username);
        }
        if(!$username || !$user) {
            return $self->display_results($args,'anonymous');
        }

        ##
        # Saving identified user to the clipboard
        #
        $clipboard->put("$cb_uri/name"   => $username);
        $clipboard->put("$cb_uri/object" => $user);
    }

    ##
    # Checking clipboard to determine if there is 'verified' flag set and
    # if so user's status is 'verified'
    #
    if(! $clipboard->get("$cb_uri/verified")) {

        ##
        # Checking the difference between the current time and the time
        # of last verification
        #
        my $vf_expire_time=$config->{vf_expire_time} ||
            throw XAO::E::DO::Web::IdentifyUser "No 'expire_time' in the configuration";
        my $vf_time_prop=$config->{vf_time_prop} ||
            throw XAO::E::DO::Web::IdentifyUser "No 'vf_time_prop' in the configuration";
        my $last_vf=$user->get($vf_time_prop);

        my $current_time=time;
        if($last_vf && $current_time - $last_vf <= $vf_expire_time) {

            ##
            # If optional 'vf_key_prop' and 'vf_key_cookie' parameters
            # are present checking the content of the key cookie and
            # appropriate field in the user profile
            #
            if ($config->{vf_key_prop} && $config->{vf_key_cookie}) {
                my $web_key=$self->cgi->cookie($config->{vf_key_cookie}) || '';
                my $db_key=$user->get($config->{vf_key_prop}) || '';
                if($web_key && $db_key eq $web_key) {
                    $clipboard->put("$cb_uri/verified" => 1);

                    ##
                    # In order to reduce global heating we only transfer
                    # cookie if more then 1/20 of the expiration time passed
                    # since the last visit.
                    #
                    # Mozilla (and probably other browsers as well) seems
                    # to re-write its cookies file every time it gets a
                    # new cookie. Nobody cares, but I don't like it for
                    # aesthetic reasons.
                    #
                    my $quant=int($vf_expire_time/20);
                    if($current_time-$last_vf > $quant) {
                        $self->siteconfig->add_cookie(
                            -name    => $config->{vf_key_cookie},
                            -value   => $web_key,
                            -path    => '/',
                            -expires => '+10y',
                        );
                        $user->put($vf_time_prop => $current_time);
                    }
                }
            }
            else {
                $clipboard->put("$cb_uri/verified" => 1);
                $user->put($vf_time_prop => $current_time);
            }
        }
    }

    ##
    # Displaying results
    #
    my $status=$clipboard->get("$cb_uri/verified") ? 'verified' : 'identified';
    $self->display_results($args,$status);
}

##############################################################################

=item display_results ($$;$)

Displays template according to the given status. Third optinal parameter
may include the content of 'ERRSTR'.

=cut

sub display_results ($$$;$) {
    my $self=shift;
    my $args=shift;
    my $status=shift;
    my $errstr=shift;

    if($args->{"$status.template"} || $args->{"$status.path"}) {

        my $config=$self->siteconfig->get('identify_user') ||
            throw XAO::E::DO::Web::IdentifyUser
                  "check - no 'identify_user' configuration";
        my $type=$args->{type} ||
            throw XAO::E::DO::Web::IdentifyUser
                  "check - no 'type' given";
        $config=$config->{$type} ||
            throw XAO::E::DO::Web::IdentifyUser
                  "check - no 'identify_user' configuration for '$type'";
        my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";

        my $page=$self->object;
        $page->display(
            path        => $args->{"$status.path"},
            template    => $args->{"$status.template"},
            CB_URI      => $cb_uri || '',
            ERRSTR      => $errstr || '',
            TYPE        => $type,
            NAME        => $self->clipboard->get("$cb_uri/name") || '',
            VERIFIED    => $self->clipboard->get("$cb_uri/verified") || '',
        );

        $self->finaltextout('') if $args->{stop};
    }
}

##############################################################################

=item find_user ($;$)

Searches for the user in the list according to the configuration:

 my $user=$self->find_user($config,$username);

=cut

sub find_user ($$$) {
    my $self=shift;
    my $config=shift;
    my $username=shift;

    my $user;

    my $list_uri=$config->{list_uri} ||
        throw XAO::E::DO::Web::IdentifyUser "find_user - no 'list_uri' in the configuration";
    my $list=$self->odb()->fetch($list_uri);

    if($config->{user_prop}) {
        my $users=$list->search([$config->{user_prop}, 'eq', $username]);
        return undef if scalar(@$users) != 1;
        return $list->get($users->[0]);
    }
    else {
        return undef unless $list->exists($username);
        return $list->get($username);
    }
}

##############################################################################

=item login ()

Logs in user. Saves current time to vf_time_prop database field.
Generates pseudo unique key and saves it value to vf_key_prop
(optional). Sets identification cookies.

=cut

sub login ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw XAO::E::DO::Web::IdentifyUser
              "login - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw XAO::E::DO::Web::IdentifyUser
              "login - no 'type' given";
    $config=$config->{$type} ||
        throw XAO::E::DO::Web::IdentifyUser
              "login - no 'identify_user' configuration for '$type'";

    ##
    # Looking for the user in the database
    #
    my $username=$args->{username} ||
        throw XAO::E::DO::Web::IdentifyUser "login - no 'username' given";
    my $errstr;
    my $user=$self->find_user($config,$username);
    $errstr="No information found about '$username'" unless $user;

    ##
    # Checking password
    #
    if($user) {
        my $password=$args->{password};

        if(! $password) {
            $errstr="No password given";
        }
        else {
            my $pass_encrypt=lc($config->{pass_encrypt} || 'plaintext');
            if($pass_encrypt eq 'plaintext') {
                # Nothing
            }
            elsif($pass_encrypt eq 'md5') {
                $password=md5_base64($password);
            }
            else {
                throw XAO::E::DO::Web::IdentifyUser
                      "login - unknown encryption mode '$pass_encrypt'";
            }

            my $pass_prop=$config->{pass_prop} || 
                throw XAO::E::DO::Web::IdentifyUser "login - no 'pass_prop' in the configuration";
            my $dbpass=$user->get($pass_prop);

            if($dbpass ne $password) {
                $errstr='Password mismatch';
            }
            else {

                ##
                # Calling overridable function that can check some
                # additional condition. Return a string with the
                # suggested error message or an empty string on success.
                #
                $errstr=$self->login_check(name => $username,
                                           object => $user,
                                           password => $password,
                                           type => $type,
                                          );
            }
        }
    }

    ##
    # We know our fate at this point. Displaying anonymous path and
    # bailing out if there were errors.
    #
    return $self->display_results($args,'anonymous',$errstr) if $errstr;

    ##
    # Generating verification key if required
    #
    if($config->{vf_key_prop} && $config->{vf_key_cookie}) {
        my $random_key=XAO::Utils::generate_key();
        $user->put($config->{vf_key_prop}  => $random_key);
        $self->siteconfig->add_cookie(
            -name    => $config->{vf_key_cookie},
            -value   => $random_key,
            -path    => '/',
            -expires => '+10y',
        );
    }

    ##
    # Setting login time
    #
    my $vf_time_prop=$config->{vf_time_prop} ||
        throw XAO::E::DO::Web::IdentifyUser "login - no 'vf_time_prop' in the configuration";
    $user->put($vf_time_prop => time);

    ##
    # Setting user name cookie
    #
    my $expire=$config->{id_cookie_expire} ? "+$config->{id_cookie_expire}s"
                                           : '+10y';
    my $id_cookie=$config->{id_cookie} ||
        throw XAO::E::DO::Web::IdentifyUser "login - no 'id_cookie' in the configuration";
    $self->siteconfig->add_cookie(
        -name    => $config->{id_cookie},
        -value   => $username,
        -path    => '/',
        -expires => $expire,
    );

    ##
    # Storing values into the clipboard
    #
    my $clipboard=$self->clipboard;
    my $clipboard_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    $clipboard->put("$clipboard_uri/name"       => $username);
    $clipboard->put("$clipboard_uri/object"     => $user);
    $clipboard->put("$clipboard_uri/verified"   => 1);

    ##
    # Displaying results
    #
    $self->display_results($args,'verified');
}

##############################################################################

=item login_check ()

A method that can be overriden in a derived object to check addition
conditions for letting a user in. Get the following arguments as its
input:

 name       => name of user object
 password   => password
 object     => reference to a database object containing user info
 type       => user type

This method is called after all standard checks - it is guaranteed that
user object exists and password matches its database record.

Must return empty string on success or suggested error message on
failure. That error message will be passed in ERRSTR argument to the
templates.

=cut

sub login_check ($%) {
    return '';
}

##############################################################################

=item logout ()

Logs out user. Resetting vf_time_prop database field and clearing
identification cookie (for hard logout mode). Set user status to
'anonymous' (hard logout mode) or 'identified'.

=cut

sub logout{
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw XAO::E::DO::Web::IdentifyUser
              "logout - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw XAO::E::DO::Web::IdentifyUser
              "logout - no 'type' given";
    $config=$config->{$type} ||
        throw XAO::E::DO::Web::IdentifyUser
              "logout - no 'identify_user' configuration for '$type'";

    ##
    # Checking if we're currently logged in at all.
    #
    my $clipboard=$self->clipboard;
    my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    my $user=$clipboard->get("$cb_uri/object");

    ##
    # Resetting last verification time
    #
    if($user) {
        my $vf_time_prop=$config->{vf_time_prop} ||
            throw XAO::E::DO::Web::IdentifyUser "logout - no 'vf_time_prop' in the configuration";
        $user->delete($vf_time_prop);
    }

    ##
    # Deleting verification status from the clipboard
    #
    $clipboard->delete("$cb_uri/verified");

    ##
    # Resetting cookies regardless, even if we're not currently logged
    # in.
    #
    if($config->{vf_key_prop} && $config->{vf_key_cookie}) {
        $self->siteconfig->add_cookie(
            -name    => $config->{vf_key_cookie},
            -value   => '0',
            -path    => '/',
            -expires => 'now',
        );

        $user->delete($config->{vf_key_prop}) if $user;
    }

    ##
    # Deleting user identification cookie if hard_logout is set.
    #
    if($args->{hard_logout}) {

        $clipboard->delete("$cb_uri/object");
        $clipboard->delete("$cb_uri/name");

        my $id_cookie=$config->{id_cookie} ||
            throw XAO::E::DO::Web::IdentifyUser "logout - no 'id_cookie' in the configuration";
        $self->siteconfig->add_cookie(
            -name    => $config->{id_cookie},
            -value   => '0'
            -path    => '/',
            -expires => 'now',
        );

        return $self->display_results($args,'anonymous');
    }

    return $self->display_results($args,'identified');
}

##############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2001 XAO, Inc.

Andrew Maltsev <am@xao.com>,
Marcos Alves <alves@xao.com>,
Ilya Lityuga <ilya@boksoft.com>.

=head1 SEE ALSO

Recommended reading:

L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::FS>.
