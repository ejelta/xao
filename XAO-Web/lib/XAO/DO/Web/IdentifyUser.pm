=head1 NAME

XAO::DO::Web::IdentifyUser - class for user identification and verification

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

!!XXX!!TODO!! - document key_list_uri and multi-key logons in general!

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
    id_cookie_type      => 'name',          # optional, see below
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

=item id_cookie_type

Can be either 'name' (default) or 'id'. Determines what is stored in the
cookie on the client browser's side -- in 'name' mode it stores user
name, just the way it is entered in the login form, in 'id' mode the
internal id (container_key) of the user object is stored.

Downside to storing names is that some browsers fail to return
exactly the stored value if it had international characters in the
name. Downside to storing IDs is that you expose a bit of internal
structure to the outside world, usually its harmless though.

If 'user_prop' is not used then it does not matter, as the name and id
are the same thing.

=item user_prop

Name attribute of a user object. If there is no 'user_prop' parameter in
the configuration it is assumed that user ID is the key for the given
list.

An interesting capability is to specify name as a URI style path, for
instance if a member has many alternative names that all can be used to
log-in and these names are stored in a list called Nicknames on each
member object, then the following might be used:

 user_prop => 'Nicknames/nickname'

See below for how to access deeper objects and ids (the object in
'Nicknames' list in that case).

=item pass_prop

Password attribute of user object.

=item pass_encrypt

Encryption method for the password. Available values are 'plaintext'
(not encrypted at all, default) and 'md5' (MD5 one way hash encryption).

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

=head1 RESULTS

In addition to displaying the correct template, results of user
verification or identification are stored in the clipboard. Base
clipboard location is determined by 'cb_uri' configuration parameter and
defaults to '/IdentifyUser/TYPE', where TYPE is the type of user.

Parameters that are stored into the clipboard are:

=over

=item id

The internal ID of the use object (same as returned by container_key()
method on the object).

=item name

Name as used in the 'login' mode. If 'user_prop' configuration parameter
is not used then it is always the same as 'id'.

=item object

Reference to the user object loaded from the database.

=item verified

This is only set when user has 'verified' status.

=back

Additional information will also be stored if 'user_prop'
refers to deeper objects. For example, if user_prop is equal to
'Nicknames/nickname' then it is assumed that there is a list inside
of user objects called Nicknames and there is a property in that list
called 'nickname'. It is also implied that the 'nickname' is unique
throughout all objects of its class.

Information that gets stored in the clipboard in that case is:

=over

=item list_prop

Name of the list property of the user object that is used in
'user_prop'. In our example it will be 'Nicknames'.

=item Nicknames (only for the example above)

Name of the list property is used to store a hash containing 'id',
'object' and probably 'list_prop' for the next object in the 'user_prop'
path (although in practice it is hard to imagine a situation where more
then one level is required).

=back

=head1 EXAMPLES

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
use Error qw(:try);
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::IdentifyUser);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: IdentifyUser.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

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
        throw $self "check_mode - no such mode '$mode'";
    }
}

##############################################################################

=item check ()

Checks identification/verification status of the user. 

To determine identification status, first check clipboard to determine
if there is such object present. If so, then that object identifies the
user.

If not, then depending on 'id_cookie_type' parameter (that defaults to
'name') check whether there is an identification cookie or key cookie
and if so, perform a search for object in database. If this search
yields a positive result, the user's status is 'identified' and an
attempt to verify user is made, otherwise the status is 'anonymous'.

Identification by key only works when keys are stored in a separate list.

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
        throw $self "check - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw $self "check - no 'type' given";
    $config=$config->{$type} ||
        throw $self "check - no 'identify_user' configuration for '$type'";
    my $clipboard=$self->clipboard;

    my $cookie_domain=$config->{domain};

    ##
    # These are useful for both verification and identification cookies.
    #
    my $vf_time_prop=$config->{vf_time_prop} ||
        throw $self "No 'vf_time_prop' in the configuration";
    my $current_time=time;
    my $last_vf;

    ##
    # Checking if we already have user in the clipboard. If not -- checking
    # the cookie and trying to load from the database.
    #
    my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    my $id_cookie_type=$config->{id_cookie_type} || 'name';
    my $key_list_uri=$config->{key_list_uri};
    my $key_ref_prop=$config->{key_ref_prop};
    my $key_object;
    my $user=$clipboard->get("$cb_uri/object");
    if(!$user) {
        my $id_cookie=$config->{id_cookie} ||
            throw $self "check - no 'id_cookie' in the configuration";

        my $cookie_value=$self->cgi->cookie($id_cookie);

        if(!$cookie_value) {
            return $self->display_results($args,'anonymous');
        }

        my $data;
        my $list_uri=$config->{list_uri} ||
            throw $self "check - no 'list_uri' in the configuration";
        if($id_cookie_type eq 'key') {
            $key_list_uri || throw $self "check - key_list_uri required";
            $key_ref_prop || throw $self "check - key_ref_prop required";
    
            my $user_list=$self->odb->fetch($list_uri);
            my $key_list=$self->odb->fetch($key_list_uri);
            my $user_id;
            my $user_obj;
            try {
                $key_object=$key_list->get($cookie_value);
                ($user_id,$last_vf)=$key_object->get($key_ref_prop,$vf_time_prop);
                $user_obj=$user_list->get($user_id);
            }
            otherwise {
                my $e=shift;
                dprint "IGNORED(OK): $e";
            };
            $user_obj || return $self->display_results($args,'anonymous');

            $data={
                object      => $user_obj,
                id          => $user_id,
                name        => $cookie_value,
                key_object  => $key_object,
            };
        }
        elsif($id_cookie_type eq 'id' && $config->{user_prop}) {
            my $list=$self->odb->fetch($list_uri);

            my $user_prop=$config->{user_prop};
            my @names=split(/\/+/,$user_prop);
            my @ids=split(/\/+/,$cookie_value);
            my %d;

            try {
                my $obj;
                my $dref=\%d;
                for(my $i=0; $i!=@names; $i++) {
                    my $name=$names[$i];
                    my $id=$ids[$i];

                    my $obj=$list->get($id);
                    $dref->{object}=$obj;
                    $dref->{id}=$id;

                    $list=$obj->get($name);
                    if(ref $list) {
                        $dref->{list_prop}=$name;
                        $dref=$dref->{$name}={};
                    }
                    else {
                        $d{name}=$list;
                    }
                }
            }
            otherwise {
                my $e=shift;
                dprint "IGNORED(OK): $e";
            };

            $d{object} || return $self->display_results($args,'anonymous');

            $data=\%d;
        }
        elsif($id_cookie_type eq 'name' || !$config->{user_prop}) {
            $data=$self->find_user($config,$cookie_value);
        }
        else {
            throw $self "check - unknown id_cookie_type ($id_cookie_type)";
        }

        if(!$data) {
            return $self->display_results($args,'anonymous');
        }

        ##
        # Saving identified user to the clipboard
        #
        $clipboard->put($cb_uri => $data);
        $user=$data->{object};

        ##
        # Updating cookie, not doing it every time -- same reason as for
        # verification cookie below.
        #
        my $id_cookie_expire=$config->{id_cookie_expire} || 4*365*24*60*60;
        my $set_cookie_flag;
        if($key_list_uri) {
            $set_cookie_flag=1;
        }
        else {
            $last_vf=$user->get($vf_time_prop) unless defined $last_vf;
            my $quant=int($id_cookie_expire/60);
            $set_cookie_flag=($current_time-$last_vf > $quant);
        }
        if($set_cookie_flag) {
            $self->siteconfig->add_cookie(
                -name    => $id_cookie,
                -value   => $cookie_value,
                -path    => '/',
                -expires => '+' . $id_cookie_expire . 's',
                -domain  => $cookie_domain,
            );
        }
    }

    ##
    # Checking clipboard to determine if 'verified' flag is set and
    # if so user's status is 'verified'.
    #
    my $verified=$clipboard->get("$cb_uri/verified");
    if(!$verified) {
        my $vcookie;

        ##
        # If we have a list of keys find the key that belongs to this
        # browser. If there is not one, assume at most 'identified'
        # status.
        #
        my $vf_key_cookie=$config->{vf_key_cookie};
        if($key_list_uri && !$key_object) {
            my $key_list=$self->odb->fetch($key_list_uri);
            if($vf_key_cookie) {
                my $key_id=$self->cgi->cookie($vf_key_cookie);
                if($key_id) {
                    try {
                        $key_object=$key_list->get($key_id);
                        if($key_object->get($key_ref_prop) ne $user->container_key) {
                            $key_object=undef;
                        }
                    }
                    otherwise {
                        my $e=shift;
                        dprint "IGNORED(OK): $e";
                    };
                }
            }
        }

        ##
        # Checking the difference between the current time and the time
        # of last verification
        #
        my $vf_expire_time=$config->{vf_expire_time} ||
            throw $self "No 'vf_expire_time' in the configuration";
        my $quant=int($vf_expire_time/60);

        if($key_list_uri) {
            if($key_object) {
                $last_vf=$key_object->get($vf_time_prop);
            }
            else {
                $last_vf=0;
            }
        }
        else {
            $last_vf=$user->get($vf_time_prop);
        }

        if($last_vf && $current_time - $last_vf <= $vf_expire_time) {

            ##
            # If optional 'vf_key_prop' and 'vf_key_cookie' parameters
            # are present checking the content of the key cookie and
            # appropriate field in the user profile
            #
            if(!$key_list_uri && $config->{vf_key_prop} && $vf_key_cookie) {
                my $web_key=$self->cgi->cookie($vf_key_cookie) || '';
                my $db_key=$user->get($config->{vf_key_prop}) || '';
                if($web_key && $db_key eq $web_key) {
                    $verified=1;

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
                    if($current_time-$last_vf > $quant) {
                        $vcookie={
                            -name    => $config->{vf_key_cookie},
                            -value   => $web_key,
                            -path    => '/',
                            -expires => '+4y',
                            -domain  => $cookie_domain,
                        };
                    }
                }
            }
            else {
                $verified=1;
            }
        }

        ##
        # Calling external overridable function to check if it is OK to
        # verify that user.
        #
        if($verified) {
            my $errstr=$self->verify_check(
                args    => $args,
                object  => $user,
                type    => $type,
            );
            if(!$errstr) {
                $clipboard->put("$cb_uri/verified" => 1);
                if($current_time - $last_vf > $quant) {
                    my $key_object=$clipboard->get("$cb_uri/key_object");
                    if($key_object) {
                        $key_object->put($vf_time_prop => $current_time);
                        if($config->{vf_time_user_prop}) {
                            $user->put($config->{vf_time_user_prop} => $current_time);
                        }
                    }
                    else {
                        $user->put($vf_time_prop => $current_time);
                    }
                }
                if($vcookie) {
                    $self->siteconfig->add_cookie($vcookie);
                }
            }
            else {
                $verified=0;
            }
        }
    }

    ##
    # If we are failed to verify and we have a configuration parameter
    # called 'vf_key_strict' we remove 'vf_key_cookie' cookie.
    # That might help better track verification from browser side
    # applications and should not hurt anything else.
    #
    my $expire_mode=$config->{expire_mode} || 'keep';
    if(!$verified && $expire_mode eq 'clean') {
	if($id_cookie_type eq 'key') {
            $self->siteconfig->add_cookie(
                -name    => $config->{id_cookie},
                -value   => 0,
                -path    => '/',
                -expires => 'now',
                -domain  => $cookie_domain,
            );
        }
        elsif($config->{vf_key_cookie}) {
            $self->siteconfig->add_cookie(
                -name    => $config->{vf_key_cookie},
                -value   => 0,
                -path    => '/',
                -expires => 'now',
                -domain  => $cookie_domain,
            );
        }
    }

    ##
    # Displaying results
    #
    my $status=$verified ? 'verified' : 'identified';
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
            throw $self "check - no 'identify_user' configuration";
        my $type=$args->{type} ||
            throw $self "check - no 'type' given";
        $config=$config->{$type} ||
            throw $self "check - no 'identify_user' configuration for '$type'";
        my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";

        my $page=$self->object;
        $page->display(merge_refs($args,{
            path        => $args->{"$status.path"},
            template    => $args->{"$status.template"},
            CB_URI      => $cb_uri || '',
            ERRSTR      => $errstr || '',
            TYPE        => $type,
            NAME        => $self->clipboard->get("$cb_uri/name") || '',
            VERIFIED    => $self->clipboard->get("$cb_uri/verified") || '',
        }));

        $self->finaltextout('') if $args->{stop};
    }
}

##############################################################################

=item find_user ($;$)

Searches for the user in the list according to the configuration:

 my $data=$self->find_user($config,$username);

Sets the same parameters in the returned hash as stored in the clipboard
except 'verified'.

=cut

sub find_user ($$$) {
    my $self=shift;
    my $config=shift;
    my $username=shift;

    my $list_uri=$config->{list_uri} ||
        throw $self "find_user - no 'list_uri' in the configuration";
    my $list=$self->odb->fetch($list_uri);

    my $user_prop=$config->{user_prop};
 
    if($user_prop) {
        my @names=split(/\/+/,$user_prop);

        my %d;
        try {
            my $obj;
            my $dref=\%d;
            for(my $i=0; $i!=@names; ++$i) {
                my $searchprop=join('/',@names[$i..$#names]);
                my $sr=$list->search($searchprop,'eq',$username);
                return undef unless @$sr == 1;

                my $id=$sr->[0];
                my $obj=$list->get($id);

                $dref->{object}=$obj;
                $dref->{id}=$id;

                if($i!=$#names) {
                    my $name=$names[0];
                    $list=$obj->get($name);
                    $dref->{list_prop}=$name;
                    $dref=$dref->{$name}={};
                }
                else {
                    # Real username can be different even though we used
                    # 'eq' to get to it, MySQL ignores case by default.
                    #
                    my $real_username=$obj->get($searchprop);
                    if($config->{id_case_sensitive}) {
                        if($real_username ne $username) {
                            eprint "Case difference between '$real_username' and '$username'";
                            return undef;
                        }
                    }
                    else {
                        $username=$real_username;
                    }
                }
            }
        }
        otherwise {
            my $e=shift;
            dprint "IGNORED(OK): $e";
        };

        return undef unless $d{object};

        $d{name}=$username;
        $d{username}=$username;

        return \%d;
    }
    else {
        return undef unless $list->check_name($username);

        my $obj;
        try {
            $obj=$list->get($username);
        }
        otherwise {
            my $e=shift;
            dprint "IGNORED(OK): $e";
        };
        return undef unless $obj;

        ##
        # Real username can be different even though we used
        # 'eq' to get to it, MySQL ignores case by default.
        #
        my $real_key_name;
        foreach my $key ($obj->keys) {
            if($obj->describe($key)->{type} eq 'key') {
                $real_key_name=$key;
                last;
            }
        }
        my $real_username=$obj->get($real_key_name);
        if($config->{id_case_sensitive}) {
            if($real_username ne $username) {
                eprint "Case difference between '$real_username' and '$username'";
                return undef;
            }
        }
        else {
            $username=$real_username;
        }

        return {
            object      => $obj,
            name        => $username,
            username    => $username,
        };
    }
}

##############################################################################

=item login ()

Logs in user. Saves current time to vf_time_prop database field.
Generates pseudo unique key and saves its value into either vf_key_prop
or creates a record in key_list_uri. Sets identification cookies
accordingly.

There is a parameter named 'force' that allows to log in a user without
checking the password. One should be very careful not to abuse this
possibility! For security reasons 'force' will only have effect when
there is no 'password' parameter at all.

=cut

sub login ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw $self "login - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw $self "login - no 'type' given";
    $config=$config->{$type} ||
        throw $self "login - no 'identify_user' configuration for '$type'";
    my $cookie_domain=$config->{domain};

    ##
    # Looking for the user in the database
    #
    my $username=$args->{username} ||
        throw $self "login - no 'username' given";
    my $data=$self->find_user($config,$username);

    ##
    # Since MySQL is not case sensitive by default on text fields, there
    # was a glitch allowing people to log in with names like 'JOHN'
    # where the database entry would be keyed 'john'. Later on, if site
    # code compares user name to the database literally it does not
    # match leading to strange problems and inconsistencies.
    #
    my $errstr;
    my $user;
    if($data) {
        $user=$data->{object};
        $username=$data->{name};
    }
    else {
        $errstr="No information found about '$username'";
    }

    ##
    # Checking password
    #
    my $password=$args->{password};
    if($user) {
        $data->{id}=$user->container_key;

        if(!defined($password)) {
            if($args->{force}) {
                # success!
            }
            else {
                $errstr="No password given";
            }
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
                throw $self "login - unknown encryption mode '$pass_encrypt'";
            }

            my $pass_prop=$config->{pass_prop} || 
                throw $self "login - no 'pass_prop' in the configuration";
            my $dbpass=$user->get($pass_prop);

            if($dbpass ne $password) {
                $errstr='Password mismatch';
            }
        }
    }

    ##
    # Calling overridable function that can check some additional
    # conditions. Return a string with the suggested error message or an
    # empty string on success.
    #
    if(!$errstr) {
        $errstr=$self->login_check(
            name        => $username,
            object      => $user,
            password    => $password,
            type        => $type,
        );
    }

    ##
    # We know our fate at this point. Displaying anonymous path and
    # bailing out if there were errors.
    #
    return $self->display_results($args,'anonymous',$errstr) if $errstr;

    ##
    # If we have key_list_uri we store verification key there and ignore
    # vf_key_prop even if it exists.
    #
    my $vf_time_prop=$config->{vf_time_prop} ||
        throw $self "login - no 'vf_time_prop' in the configuration";
    my $id_cookie=$config->{id_cookie} ||
        throw $self "login - no 'id_cookie' in the configuration";
    my $id_cookie_type=$config->{id_cookie_type} || 'name';
    my $key_list_uri=$config->{key_list_uri};
    if($key_list_uri) {
        my $key_ref_prop=$config->{key_ref_prop} ||
            throw $self "login - key_ref_prop required";
        my $key_expire_prop=$config->{key_expire_prop} ||
            throw $self "login - key_expire_prop required";
        my $vf_expire_time=$config->{vf_expire_time} ||
            throw $self "login - no vf_expire_time in the configuration";

        my $key_id;
        my $vf_key_cookie=$config->{vf_key_cookie};
        if($id_cookie_type eq 'key') {
            $key_id=$self->cgi->cookie($id_cookie);
        }
        elsif($vf_key_cookie) {
            $key_id=$self->cgi->cookie($vf_key_cookie);
        }
        else {
            throw $self "login - id_cookie_type!=key and there is no vf_key_cookie";
        }

        my $key_list=$self->odb->fetch($key_list_uri);
        my $key_obj;
        if($key_id) {
            try {
                $key_obj=$key_list->get($key_id);
                if($key_obj->get($key_ref_prop) ne $user->container_key) {
                    $key_obj=undef;
                }
            }
            otherwise {
                my $e=shift;
                dprint "IGNORED(OK): $e";
            };
        }

        my $now=time;
        if(!$key_obj) {
            $key_obj=$key_list->get_new;
            $key_obj->put(
                $key_ref_prop       => $user->container_key,
                $key_expire_prop    => $now+$vf_expire_time,
                $vf_time_prop       => $now,
            );
            $key_id=$key_list->put($key_obj);
            $key_obj=$key_list->get($key_id);
        }
        else {
            $key_obj->put(
                $vf_time_prop       => $now,
            );
        }

        if($config->{vf_time_user_prop}) {
            $user->put($config->{vf_time_user_prop} => $now);
        }

        if($id_cookie_type eq 'key') {
            $self->siteconfig->add_cookie(
                -name    => $id_cookie,
                -value   => $key_id,
                -path    => '/',
                -expires => '+10y',
                -domain  => $cookie_domain,
            );
            $data->{name}=$key_id;
            $data->{key_object}=$key_obj;
        }
        elsif($config->{vf_key_cookie}) {
            $self->siteconfig->add_cookie(
                -name    => $config->{vf_key_cookie},
                -value   => $key_id,
                -path    => '/',
                -expires => '+10y',
                -domain  => $cookie_domain,
            );
        }

        ##
        # Auto expiring some keys
        #
        my $key_expire_mode=$config->{key_expire_mode} || 'auto';
        if($key_expire_mode eq 'auto') {
            my $cutoff=time - 10*$vf_expire_time;
            $self->odb->transact_begin;
            my $sr=$key_list->search($key_expire_prop,'lt',$cutoff,{ limit => 5 });
            foreach my $key_id (@$sr) {
                $key_list->delete($key_id);
            }
            $self->odb->transact_commit;
        }
    }
    elsif($config->{vf_key_prop} && $config->{vf_key_cookie}) {
        my $random_key=XAO::Utils::generate_key();
        $user->put($config->{vf_key_prop} => $random_key);
        $self->siteconfig->add_cookie(
            -name    => $config->{vf_key_cookie},
            -value   => $random_key,
            -path    => '/',
            -expires => '+10y',
            -domain  => $cookie_domain,
        );
    }

    ##
    # Setting login time
    #
    if(!$key_list_uri) {
        $user->put($vf_time_prop => time);
    }

    ##
    # Setting user name cookie depending on id_cookie_type parameter.
    #
    my $expire=$config->{id_cookie_expire} ? "+$config->{id_cookie_expire}s"
                                           : '+10y';
    if($id_cookie_type eq 'id') {
        my $cookie_value=$data->{id};
        my $r=$data;
        while($r->{list_prop}) {
            $r=$r->{$r->{list_prop}};
            $cookie_value.="/$r->{id}";
        };
        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => $cookie_value,
            -path    => '/',
            -expires => $expire,
            -domain  => $cookie_domain,
        );
        $data->{name}=$cookie_value;
    }
    elsif($id_cookie_type eq 'name') {
        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => $username,
            -path    => '/',
            -expires => $expire,
            -domain  => $cookie_domain,
        );
        $data->{name}=$username;
    }
    elsif($id_cookie_type eq 'key') {
        # already set above
    }
    else {
        throw $self "login - unsupported id_cookie_type ($id_cookie_type)";
    }

    ##
    # Storing values into the clipboard
    #
    my $clipboard=$self->clipboard;
    my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    $data->{verified}=1;
    $clipboard->put($cb_uri => $data);

    ##
    # Displaying results
    #
    $self->display_results($args,'verified');
}

##############################################################################

=item login_check ()

A method that can be overriden in a derived object to check additional
conditions for letting a user in. Gets the following arguments as its
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

Will install data into clipboard in soft logout mode just the same way
as mode='check' does.

=cut

sub logout{
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw $self "logout - no 'identify_user' configuration";
    my $type=$args->{type} ||
        throw $self "logout - no 'type' given";
    $config=$config->{$type} ||
        throw $self "logout - no 'identify_user' configuration for '$type'";

    my $cookie_domain=$config->{domain};

    ##
    # Logging in the user first
    #
    $self->check(type => $type);

    ##
    # Checking if we're currently logged in at all -- either verified or
    # identified.
    #
    my $clipboard=$self->clipboard;
    my $cb_uri=$config->{cb_uri} || "/IdentifyUser/$type";
    my $cb_data=$clipboard->get($cb_uri);
    my $user=$cb_data->{object};

    ##
    # If there is no user at all -- then we're already logged out
    #
    $user || return $self->display_results($args,'anonymous');

    ##
    # Removing user last verification time. This can mean removing it
    # from the key object if we're in multiple keys mode or from the
    # user record itself.
    #
    my $vf_time_prop=$config->{vf_time_prop} ||
        throw $self "logout - no 'vf_time_prop' in the configuration";
    my $key_object=$cb_data->{key_object};
    if($key_object) {
        $key_object->delete($vf_time_prop);
    }
    else {
        $user->delete($vf_time_prop);
    }

    ##
    # Removing user verification key if it is known
    #
    if($config->{vf_key_prop}) {
        $user->delete($config->{vf_key_prop});
    }

    ##
    # Deleting verification status from the clipboard
    #
    $clipboard->delete("$cb_uri/verified");

    ##
    # Not sure, but setting value to an empty string triggered a bug
    # somewhere, setting it to '0' instead and expiring it 'now'.
    #
    if($config->{vf_key_cookie}) {
        $self->siteconfig->add_cookie(
            -name    => $config->{vf_key_cookie},
            -value   => '0',
            -path    => '/',
            -expires => 'now',
            -domain  => $cookie_domain,
        );
    }

    ##
    # Deleting user identification if hard_logout is set.
    #
    if($args->{hard_logout}) {
        if($key_object) {
            $key_object->container_object->delete($key_object->container_key);
        }

        $clipboard->delete($cb_uri);

        my $id_cookie=$config->{id_cookie} ||
            throw $self "logout - no 'id_cookie' in the configuration";
        $self->siteconfig->add_cookie(
            -name    => $config->{id_cookie},
            -value   => '0',
            -path    => '/',
            -expires => 'now',
            -domain  => $cookie_domain,
        );

        return $self->display_results($args,'anonymous');
    }

    ##
    # We only get here if user is known, so returning 'identified'
    # status.
    #
    return $self->display_results($args,'identified');
}

##############################################################################

=item verify_check (%)

Overridable method that is called from check() after user is identified
and verified. May check for additional conditions, such as privilege
level or something similar.

Gets the following arguments as its input:

 args       => arguments as passed to the check() method
 object     => reference to a database object containing user info
 type       => user type

Must return empty string on success.

=cut

sub verify_check ($%) {
    return '';
}

##############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2001-2004 XAO Inc.

Andrew Maltsev <am@ejelta.com>,
Marcos Alves <alves@xao.com>,
Ilya Lityuga <ilya@boksoft.com>.

=head1 SEE ALSO

Recommended reading:

L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::FS>.
