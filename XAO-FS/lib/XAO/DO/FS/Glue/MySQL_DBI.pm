=head1 NAME

XAO::DO::FS::Glue::MySQL_DBI - DBD::mysql driver for XAO::FS

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

This module implements some functionality required by FS::Glue
in MySQL specific way. The module uses DBD/DBI interface; whenever
possible it is recommended to use direct MySQL module that works
directly with database without DBD/DBI layer in between.

This is the lowest level XAO::FS knows about.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::MySQL_DBI;
use strict;
use Error qw(:try);
use XAO::Utils qw(:debug :args :keys);
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Glue::SQL_DBI');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: MySQL_DBI.pm,v 2.1 2005/01/14 00:23:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item new ($%)

Creates new instance of the driver connected to the given database using
DSN, user and password.

Example:

 my $driver=XAO::Objects->new(objname => 'FS::Glue::MySQL',
                              dsn => 'OS:MySQL_DBI:dbname',
                              user => 'username',
                              password => '123123123');

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $self=$proto->SUPER::new($args);

    my $dsn=$args->{dsn};
    $dsn || $self->throw("new - required parameter missed 'dsn'");
    $dsn=~/^OS:(\w+):(\w+)(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
    my $driver=$1;
    my $dbname=$2;
    my $options=$3 || '';

    ##
    # Parsing dbopts, separating what we know about from what is passed
    # directly to the driver.
    #
    my $dbopts='';
    foreach my $pair (split(/[,;]/,$options)) {
        next unless length($pair);
        if($pair =~ /^table_type\s*=\s*(.*?)\s*$/) {
            $self->{table_type}=lc($1);
        }
        else {
            $dbopts.=';' . $pair;
        }
    }

    $driver =~ '^MySQL' ||
        throw $self "new - wrong driver type ($driver)";

    $self->sql_connect(dsn => "DBI:mysql:$dbname$dbopts",
                       user => $args->{user},
                       password => $args->{password});

    return $self;
}

###############################################################################

=item add_field_integer ($$$$)

Adds new integer field to the given table. First parameter is table
name, then field name, then index flag, then unique flag, then minimal
value and then maximum value and default value.

B<Note:> Indexes only work with MySQL 3.23 and later.

=cut

sub add_field_integer ($$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max,$default,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_integer - modifying structure in transaction scope is not supported";
    }

    $min=-0x80000000 unless defined $min;
    $min=int($min);
    if(!defined($max)) {
        $max=($min<0) ? 0x7FFFFFFF : 0xFFFFFFFF;
    }

    my $sql;
    if($min<0) {
        if($min>=-0x80 && $max<=0x7F) {
            $sql='TINYINT';
        }
        elsif($min>=-0x8000 && $max<=0x7FFF) {
            $sql='SMALLINT';
        }
        elsif($min>=-0x800000 && $max<=0x7FFFFF) {
            $sql='MEDIUMINT';
        }
        else {
            $sql='INT';
        }
    }
    else {
        if($max<=0xFF) {
            $sql='TINYINT UNSIGNED';
        }
        elsif($max<=0xFFFF) {
            $sql='SMALLINT UNSIGNED';
        }
        elsif($max<=0xFFFFFF) {
            $sql='MEDIUMINT UNSIGNED';
        }
        else {
            $sql='INT UNSIGNED';
        }
    }

    $sql.=" NOT NULL DEFAULT $default";

    $sql="ALTER TABLE $table ADD $name $sql";

    $self->sql_do($sql);

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }

    if($unique && $connected) {
        $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }
}

###############################################################################

=item add_field_real ($$;$$)

Adds new real field to the given table. First parameter is table name,
then field name, then index flag, then unique flag, then optional
minimal value and then optional maximum value and default value.

B<Note:> Indexes only work with MySQL 3.23 and later.

=cut

sub add_field_real ($$$;$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max,$default,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_real - modifying structure in transaction scope is not supported";
    }

    my $sql="ALTER TABLE $table ADD $name DOUBLE NOT NULL DEFAULT $default";

    $self->sql_do($sql);

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }

    if($unique && $connected) {
        $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }
}

###############################################################################

=item add_field_text ($$$$$)

Adds new text field to the given table. First is table name, then field
name, then index flag, then unique flag, maximum length, default value
and 'connected' flag. Depending on maximum length it will create CHAR,
TEXT, MEDIUMTEXT or LONGTEXT.

'Connected' flag must be set if that table holds elements deeper into
the tree then the top level.

B<Note:> Modifiers 'index' and 'unique' only work with MySQL 3.23 and
later.

=cut

sub add_field_text ($$$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$max,$default,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_text - modifying structure in transaction scope is not supported";
    }

    my $sql;
    if($max<255) {
        $sql="CHAR($max)";
    } elsif($max<65535) {
        $sql="TEXT";
    } elsif($max<16777215) {
        $sql="MEDIUMTEXT";
    } elsif($max<4294967295) {
        $sql="LONGTEXT";
    }

    $self->sql_do("ALTER TABLE $table ADD $name $sql NOT NULL DEFAULT ?",
                  $default);

    !$unique || $max<=255 ||
        throw $self "add_field_text - property is too long to make it unique ($max)";
    !$index || $max<=255 ||
        throw $self "add_field_text - property is too long for an index ($max)";

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }

    if($unique && $connected) {
        $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        #dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }
}

###############################################################################

=item add_table ($$$)

Creates new empty table with unique_id, key and optionally connector
fields.

=cut

sub add_table ($$$$$) {
    my $self=shift;
    my ($table,$key,$key_length,$connector)=@_;
    $key.='_';
    $connector.='_' if $connector;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_table - modifying structure in transaction scope is not supported";
    }

    my $sql="CREATE TABLE $table (" . 
            " unique_id INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY," .
            " $key CHAR($key_length) NOT NULL," .
            " INDEX $key($key)" .
            (defined($connector) ? ", $connector INT UNSIGNED NOT NULL" .
                                   ", INDEX $connector($connector)"
                                 : "") .
            ")";

    $sql.=" TYPE=$self->{table_type}"
        if $self->{table_type} && $self->{table_type} ne 'mixed';

    $self->sql_do($sql);
}

###############################################################################

=item delete_row ($$)

Deletes a row from the given name and unique_id.

=cut

sub delete_row ($$$) {
    my $self=shift;
    my ($table,$uid)=@_;

    $self->tr_loc_begin;
    $self->sql_do("DELETE FROM $table WHERE unique_id=?",$uid);
    $self->tr_loc_commit;
}

###############################################################################

=item disconnect ()

Permanently disconnects driver from database. Normally perl's garbage collector
will do that for you.

=cut

sub disconnect ($) {
    my $self=shift;
    if($self->{table_type} eq 'innodb') {
        $self->tr_ext_rollback if $self->tr_ext_active;
        $self->tr_loc_rollback if $self->tr_loc_active;
    }
    else {
        $self->unlock_tables;
    }
    $self->sql_disconnect;
}

###############################################################################

=item drop_field ($$$$$)

Drops the given field from the given table in the database. Whatever
content was in that field is lost irrevocably.

If index, unique and connected flags are given then it first will drop
the appropriate index.

=cut

sub drop_field ($$$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$connected)=@_;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "drop_field - modifying structure in transaction scope is not supported";
    }

    $name.='_';

    if($index && (!$unique || !$connected)) {
        my $sql="ALTER TABLE $table DROP INDEX fsi__$name";
        # dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }

    if($unique && $connected) {
        my $sql="ALTER TABLE $table DROP INDEX fsu__$name";
        # dprint ">>>$sql<<<";
        $self->sql_do($sql);
    }

    $self->sql_do("ALTER TABLE $table DROP $name");
}

###############################################################################

=item drop_table ($)

Drops the given table with all its data. Whatever content was in that
table before is lost irrevocably.

=cut

sub drop_table ($$) {
    my $self=shift;
    my $table=shift;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "drop_table - modifying structure in transaction scope is not supported";
    }

    $self->sql_do("DROP TABLE $table");
}

###############################################################################

=item increment_key_seq ($)

Increments the value of key_seq in Global_Fields table identified by the
given row unique ID. Returns previous value.

B<Note:> Always executed as a part of some outer level transaction. Does
not create any locks or starts transactions.

=cut

sub increment_key_seq ($$) {
    my $self=shift;
    my $uid=shift;

    $self->sql_do('UPDATE Global_Fields SET key_seq_=key_seq_+1 WHERE unique_id=?',$uid);

    my $sth=$self->sql_execute('SELECT key_seq_ FROM Global_Fields WHERE unique_id=?',$uid);
    my $seq=$self->sql_first_row($sth)->[0];
    if($seq==1) {
        $self->sql_do('UPDATE Global_Fields SET key_seq_=key_seq_+1 WHERE unique_id=?',$uid);
        $sth=$self->sql_execute('SELECT key_seq_ FROM Global_Fields WHERE unique_id=?',$uid);
        $seq=$self->sql_first_row($sth)->[0];
    }

    return $seq-1;
}

###############################################################################

=item initialize_database ($)

Removes all data from all tables and creates minimal tables that support
objects database.

=cut

sub initialize_database ($) {
    my $self=shift;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "initialize_database - modifying structure in transaction scope is not supported";
    }

    my $sth=$self->sql_execute('SHOW TABLE STATUS');
    my $table_type=$self->{table_type};
    while(my $row=$self->sql_fetch_row($sth)) {
        my ($name,$type)=@$row;
        $table_type||=lc($type);
        $self->sql_do("DROP TABLE $name");
    }
    $self->sql_finish($sth);

    my @initseq=(
        <<'END_OF_SQL',
CREATE TABLE Global_Fields (
  unique_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_name_ CHAR(30) NOT NULL DEFAULT '',
  field_name_ CHAR(30) NOT NULL DEFAULT '',
  type_ CHAR(20) NOT NULL DEFAULT '',
  refers_ CHAR(30) DEFAULT NULL,
  key_format_ CHAR(100) DEFAULT NULL,
  key_seq_ INT UNSIGNED DEFAULT NULL,
  index_ TINYINT DEFAULT NULL,
  default_ CHAR(30) DEFAULT NULL,
  maxlength_ INT UNSIGNED DEFAULT NULL,
  maxvalue_ DOUBLE DEFAULT NULL,
  minvalue_ DOUBLE DEFAULT NULL,
  PRIMARY KEY  (table_name_,field_name_),
  UNIQUE KEY unique_id (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Fields VALUES (1,'Global_Data','project',
                                  'text','',NULL,NULL,0,'',40,NULL,NULL)
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Data (
  unique_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_ char(40) NOT NULL DEFAULT '',
  PRIMARY KEY (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Data VALUES (1,'XAO::FS New Database')
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Classes (
  unique_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  class_name_ char(100) NOT NULL DEFAULT '',
  table_name_ char(30) NOT NULL DEFAULT '',
  PRIMARY KEY  (unique_id),
  UNIQUE KEY  (class_name_)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Classes VALUES (1,'FS::Global','Global_Data')
END_OF_SQL
    );

    foreach my $sql (@initseq) {
        $sql.=" TYPE=$table_type" if $table_type && $sql =~ /^CREATE/;
        $self->sql_do($sql);
    }
}

###############################################################################

=item list_keys ($$$$)

Returns a reference to an array containing all possible values of a
given field (list key) in the given table. If connector is given - then
it is used in select too.

=cut

sub list_keys ($$$$$) {
    my $self=shift;
    my ($table,$key,$conn_name,$conn_value)=@_;
    $key.='_' unless $key eq 'unique_id';
    $conn_name.='_' if $conn_name;

    my $sth;
    if($conn_name) {
        $sth=$self->sql_execute("SELECT $key FROM $table WHERE $conn_name=?",
                                $conn_value);
    }
    else {
        $sth=$self->sql_execute("SELECT $key FROM $table");
    }

    return $self->sql_first_column($sth);
}

###############################################################################

=item load_structure ()

Loads Global_Fields and Global_Classes tables into internal hash for
use in Glue.

Returns the hash reference.

B<TODO:> This should be changed so that data types would not be
hard-coded here. Probably a reference to a subroutine that will parse
and store them would do the job?

=cut

sub load_structure ($) {
    my $self=shift;
    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "load_structure - modifying structure in transaction scope is not supported";
    }

    ##
    # Checking table types.
    #
    my $sth=$self->sql_execute("SHOW TABLE STATUS");
    my %table_status;
    my %type_counts;
    my $table_count=0;
    while(my $row=$self->sql_fetch_row($sth)) {
        my ($name,$type,$row_format,$rows)=@$row;
        $type=lc($type);
        $type_counts{$type}++;
        $table_status{$name}=$type;
        $table_count++;
        # dprint "Table '$name', type=$type, row_format=$row_format, rows=$rows";
    }
    if($self->{table_type}) {
        my $table_type=$self->{table_type};
        if($table_type eq 'innodb' || $table_type eq 'myisam') {
            foreach my $table_name (keys %table_status) {
                next if $table_status{$table_name} eq $table_type;
                dprint "Converting table '$table_name' type from '$table_status{$table_name}' to '$table_type'";
                $self->sql_do("ALTER TABLE $table_name TYPE=$table_type");
            }
        }
        else {
            throw $self "Unsupported table_type '$table_type' in DSN options";
        }
    }
    elsif($type_counts{innodb} && $type_counts{innodb}==$table_count) {
        $self->{table_type}='innodb';
    }
    elsif($type_counts{myisam} && $type_counts{myisam}==$table_count) {
        $self->{table_type}='myisam';
    }
    else {
        $self->{table_type}='mixed';
        eprint "You have mixed table types in the database (" .
               join(',',map { $_ . '=' . $table_status{$_} } sort keys %table_status) . 
               ")";
    }

    ##
    # Checking if Global_Fields table has key_format_ and key_seq_
    # fields. Adding them if it does not.
    #
    $sth=$self->sql_execute("DESC Global_Fields");
    my $flist=$self->sql_first_column($sth);
    if(! grep { $_ eq 'key_format_' } @$flist) {
        $self->sql_do('ALTER TABLE Global_Fields ADD key_format_ CHAR(100) DEFAULT NULL');
    }
    if(! grep { $_ eq 'key_seq_' } @$flist) {
        $self->sql_do('ALTER TABLE Global_Fields ADD key_seq_ INT UNSIGNED DEFAULT NULL');
    }

    ##
    # Loading fields descriptions from the database.
    #
    my %fields;
    my %tkeys;
    my %ckeys;
    $sth=$self->sql_execute("SELECT unique_id,table_name_,field_name_," .
                                   "type_,refers_,key_format_," .
                                   "index_,default_," .
                                   "maxlength_,minvalue_,maxvalue_" .
                            " FROM Global_Fields");

    while(my $row=$self->sql_fetch_row($sth)) {
        my ($uid,$table,$field,$type,$refers,$key_format,
            $index,$default,$maxlength,$minvalue,$maxvalue)=@$row;
        my $data;
        if($type eq 'list') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                class       => $refers,
            };
            $ckeys{$refers}=$field;
        }
        elsif($type eq 'key') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                refers      => $refers,
                key_format  => $key_format || '<$RANDOM$>',
                key_unique_id => $uid,
                key_length  => $maxlength || 30,
            };
            $tkeys{$table}=$field;
        }
        elsif($type eq 'connector') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                refers      => $refers
            };
        }
        elsif($type eq 'text' || $type eq 'words') {
            $data={
                type        => $type,
                index       => $index ? 1 : 0,
                unique      => $index==2 ? 1 : 0,
                default     => $default,
                maxlength   => $maxlength,
            };
        }
        elsif($type eq 'real' || $type eq 'integer') {
            $data={
                type        => $type,
                index       => $index ? 1 : 0,
                unique      => $index==2 ? 1 : 0,
                default     => $default,
                minvalue    => defined($minvalue) ? 0+$minvalue : undef,
                maxvalue    => defined($maxvalue) ? 0+$maxvalue : undef,
            };
        }
        else {
            $self->throw("load_structure - unknown type ($type) for table=$table, field=$field");
        }
        $fields{$table}->{$field}=$data;
    }
    $self->sql_finish($sth);

    ##
    # Now loading classes translation table and putting fields
    # descriptions inside of it as well.
    #
    $sth=$self->sql_execute("SELECT class_name_,table_name_ FROM Global_Classes");
    my %classes;
    while(my $row=$self->sql_fetch_row($sth)) {
        my ($class,$table)=@$row;
        my $f=$fields{$table};
        $f || $self->throw("load_structure - no description for $table table (class $class)");
        $classes{$class}={
            table   => $table,
            fields  => $f,
        };
    }
    $self->sql_finish($sth);

    ##
    # Copying key related stuff to list description which is very
    # helpful for build_structure
    #
    foreach my $class (keys %ckeys) {
        my $upper_key_name=$ckeys{$class};
        my ($data,$table)=@{$classes{$class}}{'fields','table'};
        my $key_name=$tkeys{$table};
        my $key_data=$data->{$key_name};
        my $upper_data=$classes{$key_data->{refers}}->{fields}->{$upper_key_name};
        @{$upper_data}{qw(key key_format key_length)}=
            ($key_name,@{$key_data}{qw(key_format key_length)});
    }

    ##
    # Resulting structure
    #
    \%classes;
}

###############################################################################

=item mangle_field_name ($)

Adds underscore to the end of field name to avoid problems with reserved
words. Could do something else in other drivers, do not count on the
fact that there would be underscore at the end.

=cut

sub mangle_field_name ($$) {
    my $self=shift;
    my $name=shift;
    defined($name) ? $name . '_' : undef;
}

###############################################################################

=item reset ()

Brings driver to usable state. Unlocks tables if they were somehow left
in locked state.

=cut

sub reset () {
    my $self=shift;
    if($self->{table_type} eq 'innodb') {
        $self->tr_loc_rollback();
    }
    else {
        $self->unlock_tables();
    }
}

###############################################################################

=item retrieve_fields ($$$@)

Retrieves individual fields from the given table by unique ID of the
row. Always returns array reference even if there is just one field in
it.

=cut

sub retrieve_fields ($$$@) {
    my $self=shift;
    my $table=shift;
    my $unique_id=shift;

    $unique_id ||
        $self->throw("retrieve_field($table,...) - no unique_id given");

    my @names=map { $_ . '_' } @_;

    my $sql=join(',',@names);
    $sql="SELECT $sql FROM $table WHERE unique_id=?";

    my $sth=$self->sql_execute($sql,$unique_id);
    return $self->sql_first_row($sth);
}

###############################################################################

=item search (\%query)

performs a search on the given query and returns a reference to an array
of arrays containing search results. Query hash is as prepared by
_build_search_query() in the Glue.

=cut

sub search ($%) {
    my $self=shift;
    my $query=get_args(\@_);

    my $sql=$query->{sql};

    if($query->{options} && $query->{options}->{limit}) {
        $sql.=' LIMIT '.int($query->{options}->{limit});
    }

    # dprint "SQL: $sql";

    my $sth=$self->sql_execute($sql,$query->{values});

    if(scalar(@{$query->{fields_list}})>1) {
        my @results;

        ##
        # We need to copy the array we get here to avoid replicating the
        # last row into all rows by using reference to the same array.
        #
        while(my $row=$self->sql_fetch_row($sth)) {
            push @results,[ @$row ];
        }
        $self->sql_finish($sth);
        return \@results;
    }
    else {
        return $self->sql_first_column($sth);
    }

}

###############################################################################

=item search_clause_wq ($field $string)

Returns database specific syntax for REGEX matching a complete word
if database supports it or undef otherwise. For MySQL returns REGEXP
clause.

=cut

sub search_clause_wq ($$$) {
    my $self=shift;
    my ($field,$rha)=@_;
    $rha=~s/([\\'\[\]\|\{\}\(\)\.\*\?\$\^])/\\$1/g;
    ("$field REGEXP ?","[[:<:]]" . $rha . "[[:>:]]");
}

###############################################################################

=item search_clause_ws ($field $string)

Returns database specific syntax for REGEX matching the beginning of
a word if database supports it or undef otherwise. For MySQL returns
REGEXP clause.

=cut

sub search_clause_ws ($$$) {
    my $self=shift;
    my ($field,$rha)=@_;
    $rha=~s/([\\'\[\]])/\\$1/g;
    ("$field REGEXP ?","[[:<:]]$rha");
}

###############################################################################

=item store_row ($$$$$$$)

Stores complete row of data into the given table. New name is generated
in the given key field if there is no name given.

Example:

 $self->_driver->store_row($table,
                           $key_name,$key_value,
                           $conn_name,$conn_value,
                           \%row);

Connector name and connector value are optional if this list is directly
underneath of Global.

=cut

sub store_row ($$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$key_value,$conn_name,$conn_value,$row)=@_;
    $key_name.='_';
    $conn_name.='_' if $conn_name;

    ##
    # If we have no transaction support we need to lock Global_Fields
    # too as it might be used in AUTOINC key formats.
    #
    my @ltab;
    if($self->{table_type} eq 'innodb') {
        #dprint "store_row: transaction begin";
        $self->tr_loc_begin;
    }
    else {
        #dprint "store_row: locking tables";
        @ltab=$table eq 'Global_Fields' ? ('Global_Fields') : ($table,'Global_Fields');
        $self->lock_tables(@ltab);
    }

    my $uid;
    if(ref($key_value) eq 'CODE') {
        my $kv;
        while(1) {
            $kv=&{$key_value};
            last unless $self->unique_id($table,
                                         $key_name,$kv,
                                         $conn_name,$conn_value,
                                         1);
        }
        $key_value=$kv;
    }
    elsif($key_value) {
        $uid=$self->unique_id($table,
                              $key_name,$key_value,
                              $conn_name,$conn_value,
                              1);
    }
    else {
        throw $self "store_row - no key_value given (old usage??)";
    }
    
    if($uid) {
        # Needs to be split into local version that is called from
        # underneath transactional cover and "public" one.
        $self->update_fields($table,$uid,$row,0);
    }
    else {
        my @fn=($key_name, map { $_.'_' } keys %{$row});
        my @fv=($key_value, values %{$row});
        if($conn_name && $conn_value) {
            unshift @fn,$conn_name;
            unshift @fv,$conn_value;
        }

        my $sql="INSERT INTO $table (";
        $sql.=join(',',@fn);
        $sql.=') VALUES (';
        $sql.=join(',',('?') x scalar(@fn));
        $sql.=')';

        $self->sql_do($sql,\@fv);
    }

    if($self->{table_type} eq 'innodb') {
        #dprint "store_row: commit()";
        $self->tr_loc_commit;
    }
    else {
        #dprint "store_row: unlock_tables()";
        $self->unlock_tables(@ltab);
    }

    $key_value;
}

###############################################################################

=item unique_id ($$$$$)

Looks up row unique ID by given key name and value (required) and
connector name and value (optional for top level lists).

=cut

sub unique_id ($$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$key_value,$conn_name,$conn_value,$translated)=@_;
    $key_name.='_' unless $translated;
    $conn_name.='_' unless $translated || !$conn_name;

    my $sth;
    if(defined($conn_name) && defined($conn_value)) {
        $sth=$self->sql_execute("SELECT unique_id FROM $table WHERE $conn_name=? AND $key_name=?",
                                ''.$conn_value,''.$key_value);
    }
    else {
        $sth=$self->sql_execute("SELECT unique_id FROM $table WHERE $key_name=?",
                                ''.$key_value);
    }

    my $row=$self->sql_first_row($sth);
    return $row ? $row->[0] : undef;
}

###############################################################################

=item update_fields ($$$;$) {

Stores new values. Example:

 $self->_driver->update_field($table,$unique_id,{ name => 'value' });

Optional last argument can be used to disable transactional wrapping if
set to a non-zero value.

=cut

sub update_fields ($$$$;$) {
    my ($self,$table,$unique_id,$data,$internal)=@_;

    $unique_id ||
        throw $self "update_field($table,..) - no unique_id given";

    my @names=keys %$data;
    return unless @names;

    my $sql="UPDATE $table SET ";
    $sql.=join(',',map { "${_}_=?" } @names);
    $sql.=' WHERE unique_id=?';

    if(!$internal && $self->{table_type} eq 'innodb') {
        #dprint "store_row: transaction begin";
        $self->tr_loc_begin;
    }

    $self->sql_do($sql,values %$data,$unique_id);

    if(!$internal && $self->{table_type} eq 'innodb') {
        #dprint "store_row: transaction commit";
        $self->tr_loc_commit;
    }
}

###############################################################################

=item tr_loc_active ()

Checks if we currently have active local or external transaction.

=cut

sub tr_loc_active ($) {
    my $self=shift;
    return $self->{tr_loc_active} || $self->{tr_ext_active};
}

###############################################################################

=item tr_loc_begin ()

Starts new local transaction. Will only really start it if we do not
have currently active external transaction. Does nothing for MyISAM.

=cut

sub tr_loc_begin ($) {
    my $self=shift;
    return if $self->{table_type} ne 'innodb' ||
              $self->{tr_ext_active} ||
              $self->{tr_loc_active};
    $self->sql_do('START TRANSACTION');
    $self->{tr_loc_active}=1;
}

###############################################################################

=item tr_loc_commit ()

Commits changes for local transaction if it is active.

=cut

sub tr_loc_commit ($) {
    my $self=shift;
    return unless $self->{tr_loc_active};
    $self->sql_do('COMMIT');
    $self->{tr_loc_active}=0;
}

###############################################################################

=item tr_loc_rollback ()

Rolls back changes for local transaction if it is active. Called
automatically on errors.

=cut

sub tr_loc_rollback ($) {
    my $self=shift;
    return unless $self->{tr_loc_active};
    $self->sql_do('ROLLBACK');
    $self->{tr_loc_active}=0;
}

###############################################################################

=item tr_ext_active ()

Checks if an external transaction is currently active.

=cut

sub tr_ext_active ($) {
    my $self=shift;
    return $self->{tr_ext_active};
}

###############################################################################

sub tr_ext_begin ($) {
    my $self=shift;
    $self->{tr_ext_active} &&
        throw $self "tr_ext_begin - attempt to nest transactions";
    $self->{tr_loc_active} &&
        throw $self "tr_ext_begin - internal error, still in local transaction";
    if($self->{table_type} eq 'innodb') {
        $self->sql_do('START TRANSACTION');
    }
    $self->{tr_ext_active}=1;
}

###############################################################################

sub tr_ext_can ($) {
    my $self=shift;
    return $self->{table_type} eq 'innodb' ? 1 : 0;
}

###############################################################################

sub tr_ext_commit ($) {
    my $self=shift;

    $self->{tr_ext_active} ||
        throw $self "tr_ext_commit - no active transaction";

    if($self->{table_type} eq 'innodb') {
        $self->sql_do('COMMIT');
    }
    $self->{tr_ext_active}=0;
}

###############################################################################

sub tr_ext_rollback ($) {
    my $self=shift;

    $self->{tr_ext_active} ||
        throw $self "tr_ext_rollback - no active transaction";

    if($self->{table_type} eq 'innodb') {
        $self->sql_do('ROLLBACK');
    }
    $self->{tr_ext_active}=0;
}

###################################################################### PRIVATE

sub lock_tables ($@) {
    my $self=shift;
    my $sql='LOCK TABLES ';
    $sql.=join(',',map { "$_ WRITE" } @_);
    #dprint "lock_tables: sql=$sql";
    $self->sql_do($sql);
}

sub unlock_tables ($) {
    my $self=shift;
    return unless $self->sql_connected;
    #dprint "unlock_tables:";
    $self->sql_do_no_error('UNLOCK TABLES');
}

sub throw ($@) {
    my $self=shift;
    if($self->{table_type} eq 'innodb') {
        $self->tr_loc_rollback();
    }
    else {
        $self->unlock_tables();
    }

    $self->SUPER::throw(@_);
}

sub DESTROY ($) {
    my $self=shift;
	$self->sql_disconnect();
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue::SQL_DBI>,
L<XAO::DO::FS::Glue>.

=cut
