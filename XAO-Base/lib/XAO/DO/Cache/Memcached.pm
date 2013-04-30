=head1 NAME

XAO::DO::Cache::Memcached - memcached back-end for XAO::Cache

=head1 SYNOPSIS

You should not use this object directly, it is a back-end for
XAO::Cache.

 if($backend->exists(\@c)) {
     return $backend->get(\@c);
 }

=head1 DESCRIPTION

This back end uses Cache::Memcached to store and access distributed data
in memcached servers.

It does not work without special support data stored in the site
configuration:

    /cache/memcached => {
        servers             => [ '192.168.0.100','192.168.0.101' ],
        compress_threshold  => 15000,
        ...
    },

The only default is having namespace set to the current site name
so that the same keys in different sites don't overlap. If you feel
adventurous you can explicitly set "namespace" to an empty string in the
config to enable cross-site data caching.

The keys are built from cache name and concatenated coordinate values.

NOTE: The memcached backend does not work well on nameless caches. The
name in that case will be simply "$self" (typically something like
XAO::DO::Cache::Memcached=GLOB(0x8d850f0)) -- which almost makes the
cache useless, as several instances of the process will store data
duplicates. Don't do that.

Thankfully all caches used through $config->cache interface have names
by definition.

The XAO::Cache "size" parameter is ignored and must be controlled in
memcached configuration. The "expire" argument is given to MemCacheD to
honor and is not locally enforced.

Two additional cache parameters are accepted on a per-cache level:

   separator => used for building cache keys from coordinates
   debug     => if set then dprint is used for extra logging

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Cache::Memcached;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;
use JSON;
use Encode;
use Cache::Memcached;

use base XAO::Objects->load(objname => 'Atom');

###############################################################################

=item drop (@)

Drops an element from the cache.

=cut

sub drop ($@) {
    my $self=shift;
    $self->memcached->delete($self->make_key(@_));
}

###############################################################################

=item drop (@)

Drops all elements from the cache.

=cut

sub drop_all ($@) {
    my $self=shift;
    $self->memcached->flush_all();
}

###############################################################################

=item get (\@)

Retrieves an element from the cache. Does not validate expiration time,
trusts memcached on that.

=cut

sub get ($$) {
    my $self=shift;

    # We need to support storing undefs. All data is stored as JSON.
    #
    my $key=$self->make_key(shift);

    my $json_text=$self->memcached->get($key);

    if($self->{'debug'}) {
        dprint "MEMCACHED:get('$key') = '",$json_text,"'";
    }

    if(defined $json_text) {
        my $data=decode_json($json_text)->[0];
        return \$data;
    }
    else {
        return undef;
    }
}

###############################################################################

=item make_key (\@)

Makes a key from the given reference to a list of coordinates.

=cut

sub make_key ($$) {
    my $self=shift;

    my $key=join($self->{'separator'},$self->{'name'},map { defined($_) ? $_ : '' } @{$_[0]});

    # Ascii memcached protocol cannot handle whitespace in keys
    #
    $key=Encode::encode('utf8',$key) if Encode::is_utf8($key);

    $key=~s/([\s\r\n])/'%'.unpack('H2',$1)/sge;

    return $key;
}

###############################################################################

=item put (\@\$)

Add a new element to the cache.

=cut

sub put ($$$) {
    my $self=shift;
    my $key=$self->make_key(shift);
    my $data=shift;

    # We need to support storing complex data and undefs. Using JSON to
    # accomplish both.
    #
    my $json_text=encode_json([$$data]);

    if($self->{'debug'}) {
        dprint "MEMCACHED:put('$key' => '$json_text')"; 
    }

    my $expire=$self->{'expire'};

    $self->memcached->set($key,$json_text,($expire ? time + $expire : 0));
}

###############################################################################

=item setup (%)

Sets expiration time and maximum cache size.

=cut

sub setup ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ### use Data::Dumper;
    ### dprint Dumper($args);

    # Checking if we have a configuration
    #
    my $siteconfig=XAO::Projects::get_current_project();

    $siteconfig->can('get') ||
        throw $self "- site configuration needs to support a get() method";

    $siteconfig->get('/cache/memcached/servers') ||
        throw $self "- need at least /cache/memcached/servers in the site config";

    # Having a name is really advisable. Showing a warning if it's not
    # given. Without a name the cache degrades to a per-process cache,
    # losing all of memcached benefits.
    #
    my $name=$args->{'name'};

    if(!$name) {
        $name="$self";
        eprint "Memcached is nearly useless without a 'name' (assumed '$name')";
    }

    $self->{'name'}=$name;

    # Additional per-cache configuration
    #
    $self->{'expire'}=$args->{'expire'} || 0;

    $self->{'debug'}=$args->{'debug'};

    $self->{'separator'}=$args->{'separator'} || ($self->{'debug'} ? ":" : "\001");

    if($self->{'debug'}) {
        dprint "MEMCACHED:name=     ",$self->{'name'};
        dprint "MEMCACHED:expire=   ",$self->{'expire'};
        dprint "MEMCACHED:separator=",$self->{'separator'};
    }
}

###############################################################################

sub memcached ($) {
    my $self=shift;

    my $memcached=$self->{'memcached'};

    return $memcached if $memcached;

    my $cfg=XAO::Projects::get_current_project()->get('/cache/memcached') ||
        throw $self "- need a /config/memcached in the site configuration";

    if(!exists $cfg->{'namespace'}) {
        $cfg=merge_refs($cfg,{
            namespace   => XAO::Projects::get_current_project_name().':',
        });

        if($self->{'debug'}) {
            dprint "MEMCACHED: assumed namespace is '$cfg->{'namespace'}'";
        }
    }

    $memcached=Cache::Memcached->new($cfg) ||
        throw $self "- unable to instantiate Cache::Memcached";

    $self->{'memcached'}=$memcached;

    return $memcached;
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2013 Andrew Maltsev <am@ejelta.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::Cache>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
