=head1 NAME

XAO::DO::Web::IdentifyAgent - class for agent (i.e. browser) identification. 

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

The 'IdentifyAgent' class is used for agent identification purposes. It relies on some site configuration values which are available in the form of a reference to a hash. An example of this hash with all required parameters is presented below:

{							
													 
 cb_uri=>'IdentifyAgent',#optional, default is '/IdentifyAgent'
							
 list_uri=>'/Browsers',#optional, see below
	
 access_time_prop=>'latest_access',#required if 'list_uri' present
	
 id_cookie=>'id_agent',
	
 id_cookie_expire=>126230400,#optional, default is 4y
	
 agent_expire=>126230400,#optional, default is 'id_cookie_expire'
							
}

When a given 'IdentifyAgent' object is instantiated, it first checks the clipboard to determine if there is an agent id present, indicating that the agent has already been identified in the current session. If so, the work here is done.

If the agent has not already been identified, it checks whether there is a cookie named as 'id_cookie' parameter value ('id_agent' in example). If there is, the value of this cookie is the agent ID and saves to the clipboard. Otherwise, cookie is set to a unique agent ID value. The expiration time is set to 'id_cookie_expire' value if it is present and to 4 years otherwise.

Once the agent cookie is retrieved or an unique agent ID is generated for setting a new agent cookie a call is made to an 'IdentifyAgent' method called 'save_agent_id()'. This method first checks if there is a 'list_uri' parameter. If 'list_uri' is present then the 'agent_id' is saved to this list, using agent ID as the list's key unless an entry for the agent already exists in the list. Otherwise, nothing is saved. Whenever saving an agent to the list, the access time is also saved in the database. Saving the access time also happens every time the agent is identified by a cookie. 

Agent object puts to clipboard if there is a 'list_uri' parameter. Otherwise, agent object remains undefined.

=head1 EXAMPLE

<%IdentifyAgent%>

=head1 METHODS

There are two methods available only. First of them is overriden display method that nothing displays but identify user agent. And last of them is save_agent_id. See description below.

=over

=cut

package XAO::DO::Web:IdentifyAgent;
use strict;
use XAO::Utils qw(generate_key);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: IdentifyAgent.pm,v 1.1 2001/12/05 22:58:35 am Exp $ =~ /(\d+\.\d+)/);

##
# Method displays nothing :-) but identifies user agent 
#
sub display($){
	my $self=shift;
	my $config=$self->siteconfig->get('identify_agent');
	my $clipboard_uri=$config->{cb_uri}||"/IdentifyAgent";
	
	# Checking the clipboard to determine if there is an agent id present.
	# If so, the work here is done.
	
	my $agent_id=$self->clipboard->get("$clipboard_uri/agent_id") && return;
	
	# Checking cookie named 'id_cookie'
	# If there is the value is saved to clipboard
	# Otherwise unique agent id is generated

	my $agent_id=$self->siteconfig->cgi->cookie($config->{id_cookie}) || generate_key;
	$self->clipboard->put("$clipboard_uri/agent_id" => $agent_id);
	my $expire=$config->{id_cookie_expire}?"+$config->{id_cookie_expire}s":"+4y";
	$self->siteconfig->add_cookie( -name=>$config->{id_cookie},
																-value=>$agent_id,
																-path=>'/',
																-expire=>$expire);
	
	# Calling save_agent_id method (returns agent object or undef)
	
	my $agent_object = $self->save_agent_id($agent_id);
	
	# Putting to clipboard agent object if there is

	$self->clipboard->put("$clipboard_uri/agent_object" => $agent_object);
}

##############################################################################

=item save_agent_id ($$)

Method saves agent ID to database if 'list_uri' parameter present. Returns agent object or undef. May be overriden if more sophisticated agent data storage is required.

=cut

sub save_agent_id ($$){
	my $self=shift;
	my $agent_id=$_[0];
	my $config=$self->siteconfig->get('identify_agent');
	
	# Checking whether there is a 'list_uri' parameter
	
	my $list_uri=$config->{list_uri} || return;
	
	# If not so return, otherwise agent id is save to list
	# and current time is saved to access time property
	
	my $agent_list=$self->siteconfig->odb->fetch($list_uri);
	my $agent;
	if ($agent_list->exists($agent_id)){
		$agent = $agent_list->get($agent_id);
		$agent->put($config->{access_time_prop} => time);
	} else {
		$agent=$agent_list->get_new;
		$agent->put($config->{access_time_prop} => time);
		$agent_list->put($agent_id=>$agent);
	}
	return $agent;
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
L<XAO::FS>,
