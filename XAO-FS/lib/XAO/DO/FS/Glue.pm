=head1 NAME

XAO::DO::FS::Glue - glue that connects database with classes in XAO::FS

=head1 SYNOPSIS

 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dbh => $dbh);
 my $global=$odb->fetch('/');

=head1 DESCRIPTION

A reference to the Glue object is what holds together all List and Hash
objects in your objects database. This is the only place in API where
you pass database handler.

It is quite possible that if XAO::OS would ever be implemented on
top of some non-relational database layer the syntax of Glue's new()
methow would change too.

In current implementation Glue also serves as a base class for both List
and Hash classes and it provides some common methods. You should avoid
calling them on Glue object (think of them as pure virtual methods in OO
sense) and in fact you should avoid using glue object for anything but
connecting to a database and retrieveing root node reference.

For XAO::Web case initialization of Glue and retrieveing of Global
object is hidden from developer.

In theory Glue object should be split into ListGlue and HashGlue because
now it mixes methods that know data structure inside List and Glue and
this is not a Right Thing. But on the other side it is easier to keep
everything that knows about SQL in just one place instead of spreading
it over a couple of classes. So, do not ever rely on the fact that let's
say _list_store_object is in Glue - it might move to some class of its
own later.

=head1 PUBLIC METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Errors qw(XAO::DO::FS::Glue);

use vars qw($VERSION);
($VERSION)=(q$Id: Glue.pm,v 1.7 2002/01/04 01:47:37 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item new ($%)

Creates new Glue object and connects it to a database. There should be
exactly one Glue object per process/per database.

It is highly recommended that you create a Glue object once somewhere
at the top of your script, then retrieve root node object from it and
keep reference for the lifetime of your script. The same applies for web
scripts, especially under mod_perl - it is recommended to keep root node
reference between sessions.

The only required argument is B<dsn> (database source name). It has
special format - first part is `OS', then driver name, then database
name and optionally port number, hostname and so on. It is recommended
to pass user name and password too. Example:

 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dsn => 'OS:MySQL:ostest;hostname=dbserver'
                           user => 'user',
                           password => 'pAsSwOrD');

In order to get objects connected to that database you should call new
on $odb with the following syntax:

 my $neworder=$odb->new(objname => 'Data::Order');

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);
    my $class=ref($proto) || $proto;

    ##
    # If we've got Glue reference in $proto then pass that to
    # XAO::Objects to load.
    #
    if(ref($proto) &&
       $proto->isa('XAO::DO::FS::Glue') &&
       $$proto->{objname} eq 'FS::Glue') {
        my %a=%{$args};
        $a{glue}=$proto;
        return XAO::Objects->new(\%a);
    }

    ##
    # Our object
    #
    my $hash={ class => $class };
    my $self=bless \$hash, $class;

    ##
    # We must always have objname
    #
    my $objname=$args->{objname};
    $objname || $self->throw("new - must be loaded by XAO::Objects");
    $$self->{objname}=$objname;

    ##
    # When new object is created by get()'ing it we will have 'uri'
    # parameter passed.
    #
    $$self->{uri}=$args->{uri};

    ##
    # Checking if this is System::Glue or something else that is based
    # on it.
    #
    if($objname eq 'FS::Glue') {

        my $user=$args->{user};
        my $password=$args->{password};

        my $dsn=$args->{dsn};
        $dsn || $self->throw("new - required parameter missed 'dsn'");
        $dsn=~/^OS:(\w+):\w+(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
        my $drvname='FS::Glue::' . $1;

        my $driver=XAO::Objects->new(objname  => $drvname,
                                     dsn      => $dsn,
                                     user     => $user,
                                     password => $password);
        $$self->{driver}=$driver;

        ##
        # Checking if this is a request to trash everything and produce
        # squeky clean new database.
        #
        if($args->{empty_database}) {
            $args->{empty_database} eq 'confirm' ||
                $self->throw("new - request for 'empty_database' is not 'confirm'ed");

            $driver->initialize_database();
        }

        ##
        # Loading data layout
        #
        $$self->{classes}=$driver->load_structure();
    }

    else {
        ##
        # We must have glue object somewhere - either explicitly given
        # or from an object being cloned..
        #
        my $glue=ref($proto) ? $proto : $args->{glue};
        $glue || $self->throw("new - required parameter missed 'glue'");
        $$self->{glue}=$glue;
    }

    ##
    # Returning resulting object
    #
    $self;
}

###############################################################################

sub DESTROY () {
    my $self=shift;
    if($$self->{driver}) {
        $self->disconnect();
    }
}

###############################################################################

=item collection (%)

Creates a collection object based on parameters given. Collection is
similar to List object -- it contains a list of objects having something
in common. Collection is a read-only object, you can use it only to
retrieve objects, not to store objects in it.

Currently the only type of collection supported is the list of all
objects of the same class. This can be very useful for searching and
analyzing tasks.

Example:

 my $orders=$odb->collection(class => 'Data::Order');

 my $sr=$orders->search('date_placed', ge, 12345678);

 my $sum=0;
 foreach my $id (@$sr) {
     $sum+=$orders->get($id)->get('order_total');
 }

=cut

sub collection ($%) {
    my $self=shift;
    my $args=merge_refs(get_args(\@_), {
                            objname => 'FS::Collection',
                            glue => $self,
                        });
    XAO::Objects->new($args);
}

###############################################################################

=item container_key ()

Works for Hash'es and List's -- returns the name of current object in
upper level container.

=cut

sub container_key ($) {
    my $self=shift;
    $$self->{key_value};
}

###############################################################################

=item contents ()

Alias for values() method.

=cut

sub contents ($) {
    shift->values();
}

###############################################################################

=item destroy ()

Rough equivalent of:

 foreach my $key ($object->keys()) {
     $object->delete($key);
 }

=cut

sub destroy ($) {
    my $self=shift;
    foreach my $key ($self->keys()) {
        $self->delete($key);
    }
}

###############################################################################

=item disconnect ()

If you need to explicitly disconnect from the database and you do not want to
trust perl's garbage collector to do that call this method.

After you call disconnect() nearly all methods on $odb handler will throw
errors and there is currently no way to re-connect existing handler to the
database.

=cut

sub disconnect () {
    my $self=shift;
    $$self->{glue} && $self->throw("disconnect - only makes sense on database handler (did you mean 'detach'?)");
    if($$self->{driver}) {
        $$self->{driver}->disconnect();
        delete $$self->{driver};
    }
}

###############################################################################

=item fetch ($)

Returns an object or a property referred to by the given URI. A URI must
always start from / currently, relative URIs are not supported.

This method is in fact the only way to get a reference to the root
object (formerly /Global):

 my $global=$odb->fetch('/');

=cut

sub fetch ($$) {
    my $self=shift;
    my $path=shift;

    ##
    # Normalizing and checking path
    #
    $path=$self->normalize_path($path);
    substr($path,0,1) eq '/' || $self->throw("fetch - bad path ($path)");

    ##
    # Going through the path and retrieving every element. Could be a
    # little bit more optimal, but not much..
    #
    my $node=XAO::Objects->new(objname => 'FS::Global',
                               glue => $self,
                               uri => '/');
    foreach my $nodename (split(/\/+/,$path)) {
        next unless length($nodename);
        if(ref($node)) {
            $node=$node->get($nodename);
        } else {
            return undef;
        }
    }
    $node;
}

###############################################################################

=item objname ()

Returns relative object name that XAO::Objects would accept.

=cut

sub objname ($) {
    my $self=shift;
    $$self->{objname} || $self->throw("objname - must have an objname");
}

###############################################################################

=item objtype ()

Always returns 'Glue' string for object database handler object.

=cut

sub objtype ($) {
    'Glue';
}

###############################################################################

=item unlink ($)

Alias to delete(), which is defined in derived classes - List and Hash.

=cut

sub unlink ($$) {
    my $self=shift;
    $self->delete(shift);
}

###############################################################################

=item upper_class ($)

Returns the upper class name for the given class or undef for
FS::Global. Will skip lists and return class name of hashes only.

Will throw an error if there is no description for the given class name.

Example:

    my $base=$odb->upper_class('Data::Order');

=cut

sub upper_class ($$) {
    my $self=shift;
    my $class_name=shift || 'FS::Global';

    return undef if $class_name eq 'FS::Global';

    my $cdesc=$$self->{classes}->{$class_name} ||
        $self->throw("upper_class - nothing known about '$class_name'");

    foreach my $fd (values %{$cdesc->{fields}}) {
        return $fd->{refers} if $fd->{type} eq 'connector';
    }
    return 'FS::Global';
}

###############################################################################

=item values ()

Returns list of values for either Hash or List.

=cut

sub values ($) {
    my $self=shift;
    $self->get($self->keys());
}

###############################################################################

=item uri ()

Returns complete URI to either the object itself (if no argument is
given) or to a property with the given name.

That URI can then be used to retrieve a property or object using
$odb->fetch($uri). Be aware, that fetch() is relatively slow method and
should not be abused.

Works for both List and Hash objects. For just created object will
return `undef'.

=cut

sub uri ($;$) {
    my $self=shift;
    my $name=shift;

    my $uri=$$self->{uri};
    return undef unless $uri;

    return $uri unless defined($name);

    return $uri eq '/' ? $uri . $name : $uri . '/' . $name;
}

###############################################################################

=back

=head1 

Most of the methods of Glue would be considered "protected" in more
restrictive OO languages. Perl does not impose such limitations and it
is up to a developer's conscience to avoid using them.

The following list is here only for reference. Names, arguments and
functions performed may change from version to version. You should
B<never use the following methods in your applications>.

=over

=cut

###############################################################################

=item _class_description ()

Returns hash reference describing fields of the class name given.

=cut

sub _class_description ($) {
    my $self=shift;
    my $class_name=shift;

    if($class_name) {
        return ${$self->_glue}->{classes}->{$class_name} ||
            $self->throw("_class_description - no description for class $class_name");
    }
    else {
        return $$self->{description} if $$self->{description};

        my $objname=$$self->{objname};
        my $desc=${$self->_glue}->{classes}->{$objname} ||
            $self->throw("_class_description - object ($objname) is not configured in the database");
        $$self->{description}=$desc;

        return $desc;
    }
}

###############################################################################

# Returns a reference to an array containing complete set of keys for
# the given list.
#
sub _collection_keys ($) {
    my $self=shift;
    my $desc=$$self->{class_description};
    $self->_driver->list_keys($desc->{table},'unique_id');
}

###############################################################################

=item _collection_setup ()

Sets up collection - base class name, key name and class_description.

=cut

sub _collection_setup ($) {
    my $self=shift;

    my $glue=$self->_glue;
    $glue || $self->throw("_collection_setup - meaningless on Glue object");

    my $class_name=$$self->{class_name} || $self->throw("_collection_setup - no class name given");
    $$self->{class_description}=$self->_class_description($class_name);

    my $base_name=$$self->{base_name};
    if(!$base_name) {
        $base_name=$$self->{base_name}=$glue->upper_class($class_name) ||
                  $self->throw("_collection_setup - $class_name does not belong to the database");
    }

    $$self->{key_name}=$glue->_list_key_name($class_name,$base_name);
    $$self->{class_description}=$self->_class_description($class_name);
}

###############################################################################

=item _driver ()

Returns a reference to the driver for both Glue and derived objects.

=cut

sub _driver ($) {
    my $self=shift;
    ($$self->{glue} ? ${$$self->{glue}}->{driver} : $$self->{driver}) ||
        $self->throw("_driver - no low level driver found");
}

###############################################################################

=item _empty_field ($)

Cleans out given field

=cut

sub _empty_field ($$) {
    my $self=shift;
    my $name=shift;
    my $table=$self->_class_description->{table};
    $self->_driver->empty_field($table,$$self->{unique_id},$name);
}

###############################################################################

=item _field_description ($)

Returns the description of the given field.

=cut

sub _field_description ($$) {
    my $self=shift;
    my $field=shift;
    $self->_class_description->{fields}->{$field};
}

###############################################################################

=item _glue ()

Returns glue object reference. Makes sense only in derived objects!
For GLue object itself would throw an error, this is expected
behavior!

=cut

sub _glue ($) {
    my $self=shift;
    $$self->{glue} || $self->throw("_glue - meaningless on Glue object");
}

###############################################################################

=item _hash_list_base_id ()

Returns unique_id of the hash that contains the list that contains the
current hash. Used in container_object() method of Hash.

=cut

sub _hash_list_base_id () {
    my $self=shift;

    ##
    # Most of the time that will work fine, except for objects retrieved
    # from a Collection of some sort.
    #
    return $$self->{list_base_id} if $$self->{list_base_id};

    ##
    # Global is a special case
    #
    my $base_name=$$self->{list_base_name};
    return $$self->{list_base_id}=1 if $base_name eq 'FS::Global';

    ##
    # Collection skips over hierarchy and we have to be more elaborate.
    #
    my $connector=$self->_glue->_connector_name($self->objname,$base_name);
    $$self->{list_base_id}=$self->_retrieve_data_fields($connector);
}

###############################################################################

=item _hash_list_key_value ()

Returns what would be returned by container_key() of upper level
List. Used in container_object().

=cut

sub _hash_list_key_value () {
    my $self=shift;

    ##
    # Returning cached value if available
    #
    return $$self->{list_key_value} if $$self->{list_key_value};

    ##
    # Finding that out.
    #
    my $cdesc=${$self->_glue}->{classes}->{$$self->{list_base_name}} ||
        $self->throw("_hash_list_key_value - no 'list_base_name' available");
    my $class_name=$self->objname;
    foreach my $fn (keys %{$cdesc->{fields}}) {
        my $fd=$cdesc->{fields}->{$fn};
        next unless $fd->{type} eq 'list' && $fd->{class} eq $class_name;
        return $$self->{list_key_value}=$fn;
    }

    $self->throw("_hash_list_key_value - no reference to the list in upper class, weird");
}

###############################################################################

##
# Retrieves content of arbitrary number of data fields. Works only for
# Hash object.
#
sub _retrieve_data_fields ($@) {
    my $self=shift;

    @_ || $self->throw("_retrieve_data_field - at least one name must present");

    my $desc=$self->_class_description();

    my $data=$self->_driver->retrieve_fields($desc->{table},
                                             $$self->{unique_id},
                                             @_);

    $data ? (@_ == 1 ? $data->[0] : @$data)
          : (@_ == 1 ? undef : ());
}

###############################################################################

##
# Stores single value into hash object. Works only on Hash objects.
#
sub _store_data_field ($$$$$) {
    my $self=shift;
    my ($name,$value)=@_;
    my $table=$self->_class_description->{table};
    $self->_driver->update_field($table,$$self->{unique_id},$name,$value);
}

###############################################################################

##
# Stores dictionary field (type=='words')
#
sub _store_dictionary_field ($$$$$) {
    my $self=shift;
    my ($name,$value)=@_;
    my $table=$self->_class_description->{table};
    $self->_driver->update_field($table,$$self->{unique_id},$name,$value);
    $self->_driver->update_dictionary($table,$$self->{unique_id},
                                      $name,$self->_split_words($value));
}

###############################################################################

##
# Returns and caches connector name between two given classes. Works
# only for Glue object.
#
sub _connector_name ($$$) {
    my $self=shift;
    my $class_name=shift;
    my $base_name=shift;
    if(exists($$self->{connectors_cache}->{$class_name}->{$base_name})) {
        return $$self->{connectors_cache}->{$class_name}->{$base_name};
    }
    my $class_desc=$$self->{classes}->{$class_name};
    $class_desc || $self->throw("_connector_name - no data for class $class_name (called on derived object?)");
    foreach my $field (keys %{$class_desc->{fields}}) {
        my $fdesc=$class_desc->{fields}->{$field};
        next unless $fdesc->{type} eq 'connector' && $fdesc->{refers} eq $base_name;
        $$self->{connectors_cache}->{$class_name}->{$base_name}=$field;
        return $field;
    }
    undef;
}

###############################################################################

##
# Checks if list contains an object with the given name
#
sub _list_exists ($$) {
    my $self=shift;
    my $name=shift;
    $self->_find_unique_id($name) ? 1 : 0;
}

###############################################################################

##
# Returns list key name that uniquely identify specific list objects
# along that list.
#
sub _list_key_name ($$$) {
    my $self=shift;
    my $class_name=shift;
    my $base_name=shift || '';
    if(exists($$self->{list_keys_cache}->{$class_name}->{$base_name})) {
        return $$self->{list_keys_cache}->{$class_name}->{$base_name};
    }
    my $class_desc=$$self->{classes}->{$class_name};
    $class_desc || $self->throw("_list_key_name - no data for class $class_name (called on derived object?)");
    foreach my $field (keys %{$class_desc->{fields}}) {
        my $fdesc=$class_desc->{fields}->{$field};
        next unless $fdesc->{type} eq 'key' && $fdesc->{refers} eq $base_name;
        $$self->{list_keys_cache}->{$class_name}->{$base_name}=$field;
        return $field;
    }
    $self->throw("_list_key_name - no key defines $class_name in $base_name");
}

###############################################################################

##
# Returns a reference to an array containing complete set of keys for
# the given list.
#
sub _list_keys ($) {
    my $self=shift;
    my $desc=$$self->{class_description};
    $self->_driver->list_keys($desc->{table},
                              $$self->{key_name},
                              $$self->{connector_name},
                              $$self->{base_id});
}

###############################################################################

=item _list_search (%)

Searches for elements in the list and returns a reference to the array
with object IDs. See search() method in
L<XAO::DO::FS::List> for more details.

Works on Collections too.

=cut

sub _list_search ($%) {
    my $self=shift;

    my $options;
    $options=pop(@_) if ref($_[$#_]) eq 'HASH';

    my $conditions;
    if(scalar(@_) == 3) {
        $conditions=[ @_ ];
    }
    elsif(scalar(@_) == 1 && ref($_[0]) eq 'ARRAY') {
        $conditions=$_[0];
    }
    elsif(! @_) {
        $conditions=undef;
    }
    else {
        $self->throw('_list_search - bad arguments');
    }

    if($$self->{connector_name} && $$self->{base_id}) {
        my $special=[ $$self->{connector_name}, 'eq', $$self->{base_id} ];
        if($conditions) {
            $conditions=[ $special, 'and', $conditions ];
        }
        else {
            $conditions=$special;
        }
    }

    my $key;
    if($self->objname eq 'FS::Collection') {
        $key='unique_id';
    }
    else {
        $key=$$self->{key_name};
    }

    my $query=$self->_build_search_query(options => $options,
                                         conditions => $conditions,
                                         key => $key);

    ##
    # Performing the search
    #
    my $list=$self->_driver->search($query);

    ##
    # Post-processing results if required. The only way to get here
    # currently is if database driver does not support regex'es and
    # ws/wq search was erformed on non-dictionary field.
    #
    if($query->{post_process}) {
        $self->throw('TODO; post-processing not supported yet, mail am@xao.com');
    }

    ##
    # Done
    #
    [ map { $_->[0] } @$list ];
}

###############################################################################

=item _build_search_query (%)

Builds SQL search query according to search parameters given. See
List manpage for description. Returns a reference to a hash of the
following structure, not a string:

 sql          => complete SQL statement
 values       => array of values to be substituted into the SQL query
 classes      => hash with all classes and their aliases
 fields_list  => list of all fiels names
 tables_list  => list of all tables, their aliases and class names
 fields_map   => hash with the map of 'condition field name' => 'sql name'
 distinct     => list of fields to be unique
 order_by     => list of fields to sort on
 post_process => is non-zero if there could be extra rows in the search
                 results because of some condition that could not be
                 expressed adequately in SQL.

=cut

sub _build_search_query ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Building the list of classes used and WHERE clause for the
    # conditions list.
    #
    # In case where we do not have conditions we just put current class
    # name into classes.
    #
    my $condition=$args->{conditions};
    my %classes;
    my @values;
    my %fields_map;
    my $post_process=0;
    my $clause;
    if($condition) {
        $clause=$self->_build_search_clause(\%classes,
                                            \@values,
                                            \%fields_map,
                                            \$post_process,
                                            $condition);
    }
    else {
        $clause='';
        my $class_name=$$self->{class_name} ||
            $self->throw("_build_search_query - no 'class_name', not a List or Collection?");
        $classes{index}='a';
        $classes{$class_name}=$classes{index}++;
    }

    ##
    # Analyzing options
    #
    my %return_fields;
    my @distinct;
    my $reverse;
    my @orderby;
    my $options=$args->{options};
    if($options) {
        foreach my $option (keys %$options) {
            if(lc($option) eq 'distinct') {
                my $list=$options->{$option};
                $list=[ $list ] unless ref($list);
                foreach my $fn (@$list) {
                    my ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$fn);
                    $fdesc->{type} eq 'list' &&
                        $self->throw("_build_search_query - can't use 'list' fields in DISTINCT");
                    $return_fields{$sqlfn}=1;
                    push(@distinct,$sqlfn);
                }
            }
            elsif(lc($option) eq 'orderby') {

                my $list=$options->{$option};

                if(ref($list)) {
                    ref($list) eq 'ARRAY' ||
                        $self->throw("_list_search - 'orderby' orderby argument must be an array reference");
                }
                else {
                    $list=[ ascend => $list ];
                }

                scalar(@$list)%2 &&
                    $self->throw("_list_search - odd number of values in 'orderby' list");

                for(my $i=0; $i<@$list; $i+=2) {
                    my $fn=$list->[$i+1];
                    my ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$fn);
                    $fdesc->{type} eq 'list' &&
                        $self->throw("_build_search_query - can't use 'list' fields in ORDERBY");
                    my $o=lc($list->[$i]);
                    $o='ascend' if $o eq 'asc';
                    $o='descend' if $o eq 'desc';
                    push(@orderby,$o,$sqlfn);
                }
            }
            else {
                $self->throw("_build_search_query - unknown option '$option'");
            }
        }
    }

    ##
    # If post processing is required then adding everything to the list
    # of fields to return.
    #
    if($post_process) {
        @return_fields{CORE::values %fields_map}=CORE::values %fields_map;
    }

    ##
    # Translating classes into table names and adding glue to join
    # tables together into the clause.
    #
    my @tables_list;
    delete $classes{index};
    my $previous;
    my $wrapped;
    my $glue=$self->_glue;
    foreach my $cn (sort { $classes{$a} cmp $classes{$b} } keys %classes) {
        my $desc=$self->_class_description($cn);
        my $table=$desc->{table};
        my $item={ table => $table,
                   class => $cn,
                   index => $classes{$cn}
                 };
        push(@tables_list,$item);

        if($previous) {
            if(!$wrapped) {
                $clause="($clause)" if $clause;
                $wrapped=1;
            }

            my $base_name=$glue->upper_class($cn);
            my $conn=$glue->_connector_name($cn,$base_name);
            $conn=$classes{$cn} . '.' .
                  $self->_driver->mangle_field_name($conn);
            $clause.=" AND " if $clause;
            $clause.="$previous->{index}.unique_id=$conn";
        }
        $previous=$item;
    }

    ##
    # Adding key name into fields we need. Forming an array of field
    # names with key guaranteed to be the first.
    #
    my $key=$args->{key} || $self->throw("_build_search_query - no 'key' given");
    if($key ne 'unique_id') {
        ($key)=$self->_build_search_field(\%classes,$key);
    }
    else {
        my $class_alias=$tables_list[0]->{index};
        $key=$class_alias . '.' . $key;
    }
    delete $return_fields{$key};
    my @fields_list=($key, keys %return_fields);
    undef %return_fields;

    ##
    # Composing SQL query out of data we have.
    #
    my $sql='SELECT ';
    $sql.=join(',',@fields_list) .
          ' FROM ' .
          join(',',map { $_->{table} . ' AS ' . $_->{index} } @tables_list);
    $sql.=' WHERE ' . $clause if $clause;

    ##
    # If we're asked to produce distinct on something then we only group
    # on that, because if we include key into group by we will not
    # eliminate rows that have non-unique values in the parameter.
    # 
    # The drawback of that is that if we were asked to have distinct
    # values in some inner class then we can have repeating keys.
    #
    if(@distinct) {
        $sql.=' GROUP BY ' . join(',',@distinct);
    }
    elsif(@fields_list>1 || @tables_list>1) {
        $sql.=' GROUP BY ' . join(',',$fields_list[0]);
    }

    ##
    # Ordering goes after GROUP BY
    #
    if(@orderby) {
        $sql.=' ORDER BY ';
        for(my $i=0; $i<@orderby; $i+=2) {
            $sql.=$orderby[$i+1];
            $sql.=' DESC' if $orderby[$i] eq 'descend';
            $sql.=',' unless $i+2 == @orderby;
        }
    }

    # dprint "SQL: $sql";

    ##
    # Returning resulting hash
    #
    return {
        sql => $sql,
        where => $clause,
        values => \@values,
        classes => \%classes,
        fields_list => \@fields_list,
        fields_map => \%fields_map,
        tables_list => \@tables_list,
        distinct => \@distinct,
        order_by => \@orderby,
        post_process => $post_process,
    };
}

###############################################################################

=item _build_search_field ($$)

Builds SQL field name including table alias from field path like
'Specification/value'.

Returns array consisting of translated field name, final class name,
class description and field description.

=cut

sub _build_search_field ($$$) {
    my $self=shift;
    my $classes=shift;
    my $lha=shift;

    my $class_name=$$self->{class_name} ||
        $self->throw("_build_search_field - no 'class_name', not a List or Collection?");

    $classes->{$class_name}=$classes->{index}++ unless $classes->{$class_name};

    my $desc=$$self->{class_description};
    my @path=split(/\/+/,$lha);
    $lha=pop @path;
    foreach my $n (@path) {
        my $fd=$desc->{fields}->{$n} ||
            $self->throw("_build_search_field - unknown field '$n' in $lha");
        $fd->{type} eq 'list' ||
            $self->throw("_build_search_field - '$n' is not a list in $lha");
        $class_name=$fd->{class};
        $desc=$self->_class_description($class_name);

        if(! $classes->{$class_name}) {
            $classes->{$class_name}=$classes->{index}++;
        }
    }

    my $field_desc=$desc->{fields}->{$lha} ||
        $self->throw("_build_search_field - unknown field '$lha'");

    $lha=$classes->{$class_name} . '.' .
         $self->_driver->mangle_field_name($lha);

    ($lha,$field_desc);
}

###############################################################################

=item _build_search_clause ($$$$$)

Builds a list of classes used and WHERE clause for the given search
conditions.

=cut

sub _build_search_clause ($$$$$$) {
    my $self=shift;
    my $classes=shift;
    my $values=shift;
    my $fields_map=shift;
    my $post_process=shift;
    my $condition=shift;

    ##
    # Initial index for classes is 'a'
    #
    $classes->{index}='a' unless $classes->{index};

    ##
    # Checking if the condition has exactly three elements
    #
    ref($condition) eq 'ARRAY' && @$condition == 3 ||
        $self->throw("_build_search_query - bad syntax of 'conditions'");
    my ($lha,$op,$rha)=@$condition;
    $op=lc($op);

    ##
    # Handling search('comment', 'wq', [ 'big', 'ugly' ]);
    #
    # Translated to search([ 'comment', 'wq', 'big' ],
    #                      'or',
    #                      [ 'comment', 'wq', 'ugly' ]);
    #
    if(!ref($lha) && ref($rha) eq 'ARRAY') {
        my @args=($lha,$op,$rha->[0]);
        for(my $i=1; $i!=@$rha; $i++) {
            @args=( [ @args ], 'or', [ $lha, $op, $rha->[$i] ] );
        }
        ($lha,$op,$rha)=@args;
    }

    ##
    # First checking if we have OR/AND stuff
    #
    if(ref($lha)) {
        ref($rha) eq 'ARRAY' ||
            $self->throw("_build_search_clause - expected an array reference in RHA '$rha'");

        my $lhv=$self->_build_search_clause($classes,
                                            $values,
                                            $fields_map,
                                            $post_process,
                                            $lha);

        my $rhv=$self->_build_search_clause($classes,
                                            $values,
                                            $fields_map,
                                            $post_process,
                                            $rha);


        my $clause;
        if($op eq 'or' || $op eq '||') {
            $clause="($lhv OR $rhv)";
        }
        elsif($op eq 'and' || $op eq '&&') {
            $clause="($lhv AND $rhv)";
        }
        else {
            $self->throw("_build_search_clause - unknown operation '$op'");
        }

        return $clause;
    }

    ##
    # Now building SQL field name and class aliases to support it.
    #
    my ($field,$field_desc)=$self->_build_search_field($classes,$lha);
    $fields_map->{$lha}=$field;

    ##
    # And finally making the part of clause we were asked for
    #
    $field_desc->{type} ne 'list' ||
        $self->throw("_build_search_clause - can't search on 'list' field '$lha'");
    ref($rha) &&
        $self->throw("_build_search_clause - expected constant right hand side argument ['$lha', '$op', $rha]");

    my $rha_escaped=$rha;
    $rha_escaped=~s/([%_\\'"])/\\$1/g;

    my $clause;
    if($op eq 'eq') {
        $clause="$field=?";
        push(@$values,$rha);
    }
    elsif($op eq 'ne') {
        $clause="$field<>?";
        push(@$values,$rha);
    }
    elsif($op eq 'lt') {
        $clause="$field<?";
        push(@$values,$rha);
    }
    elsif($op eq 'le') {
        $clause="$field<=?";
        push(@$values,$rha);
    }
    elsif($op eq 'gt') {
        $clause="$field>?";
        push(@$values,$rha);
    }
    elsif($op eq 'ge') {
        $clause="$field>=?";
        push(@$values,$rha);
    }
    elsif($op eq 'cs') {
        $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
    }
    elsif($op eq 'ws') {
        if($field_desc->{type} eq 'words') {
            $self->throw("Not implemented ws on words");
        }
        else {
            $clause=$self->_driver->search_clause_ws($field,$rha,$rha_escaped);
            if(!$clause) {
                $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
                $$post_process=1;
            }
        }
    }
    elsif($op eq 'wq') {
        if($field_desc->{type} eq 'words') {
            $self->throw("Not implemented wq on words");
        }
        else {
            $clause=$self->_driver->search_clause_wq($field,$rha,$rha_escaped);
            if(!$clause) {
                $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
                $$post_process=1;
            }
        }
    }
    else {
        $self->throw("_build_search_clause - unknown operator '$op'");
    }

    $clause;
}

###############################################################################

=item _list_setup ()

Sets up list reference fields - relation to upper hash. Makes sense
only in derived objects.

=cut

sub _list_setup ($) {
    my $self=shift;
    my $glue=$$self->{glue};
    $glue || $self->throw("_setup_list - meaningless on Glue object");
    my $class_name=$$self->{class_name} || $self->throw("_setup_list - no class name given");
    my $base_name=$$self->{base_name} || $self->throw("_setup_list - no base class name given");
    $$self->{connector_name}=$glue->_connector_name($class_name,$base_name);
    $$self->{key_name}=$glue->_list_key_name($class_name,$base_name);
    $$self->{class_description}=$$glue->{classes}->{$class_name};
}

##
# Finds specific value unique ID for list object. Works only in derived
# objects.
#
sub _find_unique_id ($$) {
    my $self=shift;
    my $name=shift;
    my $key_name=$$self->{key_name} || $self->throw("_find_unique_id - no key name");
    my $connector_name=$$self->{connector_name};
    my $table=$$self->{class_description}->{table};
    $self->_driver->unique_id($table,
                              $key_name,$name,
                              $connector_name,$$self->{base_id});
}

##
# Unlinks object from list. If object is not linked anywhere else calls
# destroy() on the object first.
#
sub _list_unlink_object ($$$) {
    my $self=shift;
    my $name=shift;

    my $object=$self->get($name) || $self->throw("_list_unlink_object - no object exists (name=$name)");
    my $class_desc=$object->_class_description();

    $object->destroy();
    $self->_driver->delete_row($class_desc->{table},
                               $$object->{unique_id});
}

##
# Stores data object into list. Must be called on List object.
#
sub _list_store_object ($$$) {
    my $self=shift;
    my ($name,$value)=@_;

    ref($value) ||
        $self->throw("_list_store_object - value must be an object reference");
    $value->objname eq $$self->{class_name} ||
        $self->throw("_list_store_object - wrong objname ".$value->objname.", should be $self->{class_name}");

    my $desc=$value->_class_description;
    my @flist;
    foreach my $fn (keys %{$desc->{fields}}) {
        my $type=$desc->{fields}->{$fn}->{type};
        next if $type eq 'list';
        next if $type eq 'key';
        next if $type eq 'connector';
        push @flist, $fn;
    }
    my %fields;
    @fields{@flist}=$value->get(@flist) if @flist;

    my $table=$desc->{table};
    $table || $self->throw("_list_store_object - no table");

    my $driver=$self->_driver;
    $name=$driver->store_row($table,
                             $$self->{key_name},$name,
                             $$self->{connector_name},$$self->{base_id},
                             \%fields);

    my $uid;
    foreach my $fn (keys %{$desc->{fields}}) {
        next unless $desc->{fields}->{$fn}->{type} eq 'words';
        if(!$uid) {
            $uid=$driver->unique_id($table,
                                    $$self->{key_name},$name,
                                    $$self->{connector_name},$$self->{base_id});
        }
        $driver->update_dictionary($table,$uid,
                                   $fn,$self->_split_words($fields{$fn}));
    }

    $name;
}

##
# Splits text string to words and returns array reference
#
sub _split_words ($$) {
    my $self=shift;
    my $text=shift;
    [ defined($text)
        ? map { length($_) ? (lc($_)) : () } split(/\W+/,$text)
        : ''
    ];
}

##
# Adds new data field to the hash object.
#
sub _add_data_placeholder ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Temporary make words -> text.
    #
    $args->{type}='text' if $args->{type} eq 'words';

    my $name=$args->{name};
    my $type=$args->{type};

    my $desc=$self->_class_description;
    my $table=$self->_class_description->{table};
    my $driver=$self->_driver;

    ##
    # Copying args to avoid destroying external hash
    #
    my %fdesc;
    @fdesc{keys %{$args}}=CORE::values %{$args};
    undef $args;

    ##
    # Whenever unique is set index is set too.
    #
    $fdesc{index}=1 if $fdesc{unique};

    if($type eq 'words') {
        $fdesc{maxlength}=100 unless $fdesc{maxlength};
        $driver->add_field_text($table,$name,$fdesc{index},$fdesc{unique},$fdesc{maxlength});
        $driver->setup_dictionary($table,$name,$fdesc{maxlength});
    }
    elsif ($type eq 'text') {
        $fdesc{maxlength}=100 unless $fdesc{maxlength};
        $driver->add_field_text($table,$name,$fdesc{index},$fdesc{unique},$fdesc{maxlength});
    }
    elsif ($type eq 'integer') {
        $fdesc{minvalue}=-0x80000000 unless defined($fdesc{minvalue});
        $fdesc{maxvalue}=0x7FFFFFFF unless defined($fdesc{maxvalue});
        $driver->add_field_integer($table,$name,$fdesc{index},$fdesc{unique},
                                   $fdesc{minvalue},$fdesc{maxvalue});
    }
    elsif ($type eq 'real') {
        $fdesc{minvalue}+=0 if defined($fdesc{minvalue});
        $fdesc{maxvalue}+=0 if defined($fdesc{maxvalue});
        $driver->add_field_real($table,$name,$fdesc{index},$fdesc{unique},
                                $fdesc{minvalue},$fdesc{maxvalue});
    }
    else {
        $self->throw("_add_data_placeholder - unknown type ($type)");
    }

    ##
    # Updating Global_Fields
    #
    $desc->{fields}->{$name}=\%fdesc;
    $driver->store_row('Global_Fields',
                       'field_name',$name,
                       'table_name',$table,
                       { type => $fdesc{type},
                         maxlength => $fdesc{maxlength},
                         index => $fdesc{unique} ? 2 : ($fdesc{index} ? 1 : 0),
                         minvalue => $fdesc{minvalue},
                         maxvalue => $fdesc{maxvalue},
                       });
}

##
# Adds list placeholder to the Hash object.
#
# It gets here when name was already checked for being correct and
# unique.
#
sub _add_list_placeholder ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $desc=$self->_class_description;

    my $name=$args->{name} || $self->throw("_add_list_placeholder - no 'name' argument");
    my $class=$args->{class} || $self->throw("_add_list_placeholder - no 'class' argument");
    my $key=$args->{key} || $self->throw("_add_list_placeholder - no 'key' argument");
    $self->_check_name($key) || $self->throw("_add_list_placeholder - bad key name ($key)");
    my $connector;
    if($self->objname ne 'FS::Global') {  
        $connector=$args->{connector} || 'parent_unique_id';
        $self->_check_name($connector) ||
            $self->throw("_add_list_placeholder - bad connector name ($key)");
    }

    my $glue=$self->_glue;
    if($$glue->{classes}->{$class}) {
        $self->throw("_add_list_placeholder - multiple lists for the same class are not allowed");
    }

    XAO::Objects->load(objname => $class);

    my $table=$args->{table};
    if(!$table) {
        $table=$class;
        $table =~ s/^Data:://;
        $table =~ s/::/_/g;
        $table =~ s/_{2,}/_/g;
        $table='fs' . $table;
    }

    my $driver=$self->_driver;
    if($$glue->{classes}->{$class}) {

        my $class_desc=$$glue->{classes}->{$class};
        $table=$class_desc->{table};

        $class_desc->{fields}->{$key} &&
            $self->throw("_add_list_placeholder - key '$key' already exists in table '$table'");

        defined($connector) && $class_desc->{fields}->{$connector} &&
            $self->throw("_add_list_placeholder - connector '$connector' already exists in table '$table'");

        $driver->add_reference_fields($table,$key,$connector);

        $class_desc->{fields}->{$key}={
            type => 'key',
            refers => $self->objname,
        };
        if(defined($connector)) {
            $class_desc->{fields}->{$connector}={
                type => 'connector',
                refers => $self->objname,
            }
        }
    }
    else {
        foreach my $c (keys %{$$self->{classes}}) {
            $c->{table} ne $table || $self->throw("_add_list_placeholder - such table ($table) is already used");
        }

        $driver->add_table($table,$key,$connector);

        $$glue->{classes}->{$class}={
            table => $table,
            fields => {
                $key => {
                    type => 'key',
                    refers => $self->objname
                }
            }
        };
        if(defined($connector)) {
            $$glue->{classes}->{$class}->{fields}->{$connector}={
                type => 'connector',
                refers => $self->objname
            }
        }

        $driver->store_row('Global_Classes',
                           'class_name',$class,
                           'table_name',$table);
    }

    ##
    # Updating Global_Fields
    #
    $driver->store_row('Global_Fields',
                       'field_name',$key,
                       'table_name',$table,
                       { type => 'key',
                         refers => $self->objname
                       });
    $driver->store_row('Global_Fields',
                       'field_name',$connector,
                       'table_name',$table,
                       { type => 'connector',
                         refers => $self->objname
                       }) if defined($connector);
    $desc->{fields}->{$name}=$args;
    $driver->store_row('Global_Fields',
                       'field_name',$name,
                       'table_name',$desc->{table},
                       { type => 'list',
                         refers => $class
                       });
}

##
# Drops data field from table.
#
sub _drop_data_placeholder ($$) {
    my $self=shift;
    my $name=shift;

    my $desc=$self->_class_description;
    my $table=$self->_class_description->{table};
    my $driver=$self->_driver;

    my $uid=$driver->unique_id('Global_Fields',
                               'field_name',$name,
                               'table_name',$table);
    $uid || $self->throw("_drop_data_placeholder - no description for $table.$name in the Global_Fields");
    $driver->delete_row('Global_Fields',$uid);

    delete $desc->{fields}->{$name};

    $driver->drop_field($table,$name);
}

##
# Drops list placeholder. This is recursive - when you drop a list you
# also drop all objects in that list and if these objects had any lists
# on them - these lists too.
#
# Instead of dropping each object individually we just drop entire
# tables here. Potentially very dangerous.
#
sub _drop_list_placeholder ($$;$) {
    my $self=shift;
    my $name=shift;
    my $recursive=shift;

    my $desc=$recursive || $self->_field_description($name);
    my $class=$desc->{class};
    my $glue=$self->_glue;
    my $cdesc=$$glue->{classes}->{$class};
    my $cf=$cdesc->{fields};
    foreach my $fname (keys %{$cf}) {
        if($cf->{$fname}->{type} eq 'list') {
            $self->_drop_list_placeholder($fname,$cf->{$fname});
        }
    }

    my $driver=$self->_driver;
    my $table=$cdesc->{table};

    my $uid=$driver->unique_id('Global_Classes',
                               'class_name',$class,
                               'table_name',$table);
    $uid || $self->throw("_drop_list_placeholder - no description for $table in the Global_Classes");
    $driver->delete_row('Global_Classes',$uid);

    my $ul=$driver->list_keys('Global_Fields','unique_id','table_name',$table);
    foreach $uid (@{$ul}) {
        $driver->delete_row('Global_Fields',$uid);
    }

    if(! $recursive) {
        my $selftable=$$glue->{classes}->{$self->objname}->{table};
        $uid=$driver->unique_id('Global_Fields',
                            'field_name',$name,
                            'table_name',$selftable);
        $uid || $self->throw("_drop_list_placeholder - no description for $selftable.$name in the Global_Fields");
        $driver->delete_row('Global_Fields',$uid);
    }

    delete $$glue->{classes}->{$class};
    delete $$glue->{list_keys_cache}->{$class};
    delete $$glue->{connectors_cache}->{$class};
    delete $$glue->{classes}->{$self->objname}->{fields}->{$name};

    $self->_driver->drop_table($table);
}

###############################################################################

=item _check_name ($)

Checks if the given name is a valid field name to be used in put() or
get(). Should not be overriden unless you fully understand potential
effects.

Valid name must start from letter and may consist from letters, digits
and underscore symbol. Length is limited to 30 characters.

Returns boolean value.

=cut

sub _check_name ($$) {
    my $self=shift;
    my $name=shift;
    defined($name) && $name =~ /^[a-z][a-z0-9_]*$/i && length($name)<=30;
}

sub normalize_path ($$) {
    my $self=shift;
    my $path=shift;
    $path=~s/\s//g;
    $path=~s/\/{2,}/\//g;
    $path;
}

sub throw {
    my $self=shift;
    throw Error::Simple ref($self)."::".join('',@_,"\n");
}

###############################################################################
1;
__END__

=back

=head1 BUGS

MySQL chops off spaces at the end of text strings and Glue currently
does not compensate for that.

=head1 AUTHORS

XAO, Inc. (c) 2001. This module was developed by Andrew Maltsev
<am@xao.com> with help and valuable comments of other team members.

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).

=cut
