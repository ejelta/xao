=head1 NAME

XAO::DO::FS::Glue::MySQL_DBI - DBD::mysql driver for XAO::FS

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

This module implements some functionality required by FS::Glue
in MySQL specific way. The module uses DBD/DBI interface; whenever
possible it is recommended to use direct MySQL module that works
directly with database without DBD/DBI layer in between.

This is the lowest level XAO::FS knows about. Underneath of it are
DBD::mysql, DBI, database itself, operationg system, hardware, atoms,
protons, gluons and so on and on and on.. The level might be not so low
if we look at it this way.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::MySQL_DBI;
use strict;
use XAO::Utils qw(:debug :args :keys);
use XAO::Objects;
use XAO::Errors qw(XAO::DO::FS::Glue::MySQL_DBI);
use DBI;
use DBD::mysql;

###############################################################################

=item new ($%)

Creates new instance of the driver connected to the given database using
DSN, user and password.

Example:

 my $driver=XAO::Objects->new(objname => 'FS::Glue::MySQL',
                              dsn => 'DBI:MySQL_DBI:dbname',
                              user => 'username',
                              password => '123123123');

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);
    my $class=ref($proto) || $proto;

    ##
    # Our object
    #
    my $user=$args->{user};
    my $password=$args->{password};
    my $dsn=$args->{dsn};
    my $self={
        class => $class,
        objname => $args->{objname},
        dsn => $dsn,
        user => $user,
        password => $password
    };
    bless $self, $class;

    ##
    # Connecting to the database
    #
    $dsn || $self->throw("new - required parameter missed 'dsn'");
    $dsn=~/^OS:(\w+):(\w+)(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
    $1 eq 'MySQL_DBI' || $self->throw("new - driver type is not MySQL_DBI");
    my $dbname=$2;
    my $dbopts=$3 || '';
    my $dbh=DBI->connect("DBI:mysql:$dbname$dbopts",$user,$password) ||
            $self->throw("new - can't connect to the database ($dsn,$user,$password)");
    $self->{dbh}=$dbh;
    my $v=$dbh->{mysql_serverinfo} || $dbh->{serverinfo};
    if(!$v || $v !~ /^(\d+)\.(\d+)(\.(\d+))?$/ || $1<3 || $2<23) {
        $self->{no_null_indexes}=1;
        eprint "Disabling NULL indexes, older MySQL found";
    }

    ##
    # Returning resulting object
    #
    $self;
}

###############################################################################

=item add_field_integer ($$$$)

Adds new integer field to the given table. First parameter is table
name, then field name, then index flag, then unique flag, then minimal
value and then maximum value.

B<Note:> Indexes only work with MySQL 3.23 and later.

B<Note:> Unique modifier has a side effect of making that field NOT
NULL.

=cut

sub add_field_integer ($$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max)=@_;
    $name.='_';

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

    $sql.=' NOT NULL' if $unique;

    $sql="ALTER TABLE $table ADD $name $sql";

    $self->{dbh}->do($sql) || $self->throw_sql('add_field_integer');

    if($unique || !$self->{no_null_indexes}) {
        my $usql=$unique ? " UNIQUE" : "";
        $self->{dbh}->do("ALTER TABLE $table ADD$usql INDEX($name)") ||
            $self->throw_sql('add_field_integer');
    }
}

###############################################################################

=item add_field_real ($$;$$)

Adds new real field to the given table. First parameter is table name,
then field name, then index flag, then unique flag, then optional
minimal value and then optional maximum value.

B<Note:> Indexes only work with MySQL 3.23 and later.

B<Note:> Unique modifier has a side effect of making that field NOT
NULL.

=cut

sub add_field_real ($$$;$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max)=@_;
    $name.='_';

    my $sql="ALTER TABLE $table ADD $name DOUBLE";
    $sql.=' NOT NULL' if $unique;

    $self->{dbh}->do($sql) || $self->throw_sql('add_field_real');

    if($unique || !$self->{no_null_indexes}) {
        my $usql=$unique ? " UNIQUE" : "";
        $self->{dbh}->do("ALTER TABLE $table ADD$usql INDEX($name)") ||
            $self->throw_sql('add_field_real');
    }
}

###############################################################################

=item add_field_text ($$$$)

Adds new text field to the given table. First is table name, then field
name, then index flag, then unique flag and then maximum
length. Depending on maximum length it will create CHAR, TEXT,
MEDIUMTEXT or LONGTEXT.

B<Note:> Indexes only work with MySQL 3.23 and later.

B<Note:> Unique modifier has a side effect of making that field NOT
NULL. In most of the cases that means that you can only add it on empty
table.

=cut

sub add_field_text ($$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$max)=@_;
    $name.='_';

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

    $sql.=' NOT NULL' if $unique;

    $self->{dbh}->do("ALTER TABLE $table ADD $name $sql") ||
        $self->throw_sql('add_field_text');

    if($max<255 && ($unique || !$self->{no_null_indexes})) {
        my $usql=$unique ? " UNIQUE" : "";
        $self->{dbh}->do("ALTER TABLE $table ADD$usql INDEX($name)") ||
            $self->throw_sql('add_field_text');
    }
}

###############################################################################

=item add_table ($$$)

Creates new empty table with unique_id, key and optionally connector
fields.

=cut

sub add_table ($$$$) {
    my $self=shift;
    my ($table,$key,$connector)=@_;
    $key.='_';
    $connector.='_' if $connector;

    my $sql="CREATE TABLE $table (" . 
            " unique_id INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY," .
            " $key CHAR(30) NOT NULL," .
            " INDEX $key($key)" .
            (defined($connector) ? ", $connector INT UNSIGNED NOT NULL" .
                                   ", INDEX $connector($connector)"
                                 : "") .
            ")";

    $self->{dbh}->do($sql) || $self->throw_sql('add_table');
}

###############################################################################

=item delete_row ($$)

Deletes a row from the given name and unique_id.

=cut

sub delete_row ($$$) {
    my $self=shift;
    my ($table,$uid)=@_;

    my $sth=$self->{dbh}->prepare("DELETE FROM $table WHERE unique_id=?");
    $sth && $sth->execute(''.$uid) && $sth->finish ||
        $self->throw_sql('drop_row');
}

###############################################################################

=item disconnect ()

Permanently disconnects driver from database. Normally perl's garbage collector
will do that for you.

=cut

sub disconnect ($) {
    my $self=shift;
    my $dbh=$self->{dbh};
	if($dbh) {
        $self->unlock_tables();
        $dbh->disconnect();
        delete $self->{dbh};
    }
}

###############################################################################

=item drop_field ($$)

Drops the given field from the given table in the database. Whatever
content was in that field is lost irrevocably.

=cut

sub drop_field ($$$) {
    my $self=shift;
    my ($table,$name)=@_;
    $name.='_';

    my $sth=$self->{dbh}->prepare("ALTER TABLE $table DROP $name");
    $sth && $sth->execute && $sth->finish || $self->throw_sql('drop_field');
}

###############################################################################

=item drop_table ($)

Drops the given table with all its data. Whatever content was in that
table before is lost irrevocably.

=cut

sub drop_table ($$) {
    my $self=shift;
    my $table=shift;

    my $sth=$self->{dbh}->prepare("DROP TABLE $table");
    $sth && $sth->execute && $sth->finish || $self->throw_sql('drop_table');
}

###############################################################################

=item empty_field ($$$)

Removes content of given field in the given table by storing NULL in it.

=cut

sub empty_field ($$$$) {
    my $self=shift;
    my ($table,$unique_id,$name)=@_;
    $name.='_';

    my $sth=$self->{dbh}->prepare("UPDATE $table SET $name=NULL WHERE unique_id=?");
    $sth && $sth->execute($unique_id) && $sth->finish() ||
        $self->throw_sql('empty_field');
}

###############################################################################

=item initialize_database ($)

Removes all data from all tables and creates minimal tables that support
objects database.

=cut

sub initialize_database ($) {
    my $self=shift;
    my $dbh=$self->{dbh};

    my $sth=$dbh->prepare('SHOW TABLES');
    $sth && $sth->execute() || $self->throw_sql('initialize_database');
    my %tables;
    while(my ($table)=$sth->fetchrow_array()) {
        $tables{$table}=1;
        $dbh->do("DROP TABLE $table") || $self->throw_sql('initialize_database');
    }
    $sth->finish;

    my @initseq=(
        <<'END_OF_SQL',
CREATE TABLE Global_Fields (
  unique_id INT unsigned NOT NULL AUTO_INCREMENT,
  table_name_ CHAR(30) NOT NULL default '',
  field_name_ CHAR(30) NOT NULL default '',
  type_ CHAR(20) NOT NULL default '',
  refers_ CHAR(30) default NULL,
  maxlength_ INT unsigned default NULL,
  index_ TINYINT default NULL,
  maxvalue_ DOUBLE default NULL,
  minvalue_ DOUBLE default NULL,
  PRIMARY KEY  (table_name_,field_name_),
  UNIQUE KEY unique_id (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Fields VALUES (1,'Global_Data','project',
                                  'text','',40,0,NULL,NULL)
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Dictionary (
  table_name varchar(20) NOT NULL default '',
  field_name varchar(20) NOT NULL default '',
  strip varchar(100) NOT NULL default '',
  table_uid int(10) unsigned NOT NULL default '0',
  INDEX (table_name,field_name),
  INDEX (strip(8)),
  INDEX (table_uid)
)
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Data (
  unique_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_ char(40),
  PRIMARY KEY (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Data VALUES (1,'XAO::FS New Database')
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Classes (
  unique_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  class_name_ char(100) NOT NULL default '',
  table_name_ char(30) NOT NULL default '',
  PRIMARY KEY  (unique_id),
  UNIQUE KEY  (class_name_)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Classes VALUES (2,'FS::Global','Global_Data')
END_OF_SQL
    );

    foreach my $clause (@initseq) {
        $dbh->do($clause) || $self->throw('initialize_database');
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
        $sth=$self->{dbh}->prepare("SELECT $key FROM $table" .
                                   " WHERE $conn_name=?");
        $sth->execute($conn_value) || $self->throw_sql('list_keys');
    }
    else {
        $sth=$self->{dbh}->prepare("SELECT $key FROM $table");
        $sth->execute() || $self->throw_sql();
    }

    [ map { $_->[0] } @{$sth->fetchall_arrayref([0])} ];
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

    ##
    # Loading fields descriptions from the database.
    #
    my %fields;
    my $dbh=$self->{dbh};
    my $sth=$dbh->prepare("SELECT table_name_,field_name_,type_,index_," .
                                 "refers_,maxlength_,minvalue_,maxvalue_" .
                          " FROM Global_Fields");
    $sth && $sth->execute() || $self->throw("_reload - SQL error");
    while(my ($table,$field,$type,$index,$refers,$maxlength,
              $minvalue,$maxvalue)=$sth->fetchrow_array) {
        my $data;
        if($type eq 'list') {
            $refers || $self->throw("_reload - no class name at Global_Fields($table,$field,..)");
            $data={
                type => $type,
                class => $refers,
            };
        }
        elsif($type eq 'key') {
            $refers || $self->throw("_reload - no class name at Global_Fields($table,$field,..)");
            $data={
                type => $type,
                refers => $refers
            };
        }
        elsif($type eq 'connector') {
            $refers || $self->throw("_reload - no class name at Global_Fields($table,$field,..)");
            $data={
                type => $type,
                refers => $refers
            };
        }
        elsif($type eq 'text' || $type eq 'words') {
            $data={
                type => $type,
                maxlength => $maxlength,
                index => $index ? 1 : 0,
                unique => $index==2 ? 1 : 0,
            };
        }
        elsif($type eq 'real' || $type eq 'integer') {
            $data={
                type => $type,
                minvalue => defined($minvalue) ? 0+$minvalue : undef,
                maxvalue => defined($maxvalue) ? 0+$maxvalue : undef,
                index => $index ? 1 : 0,
                unique => $index==2 ? 1 : 0,
            };
        }
        else {
            $self->throw("_reload - unknown type ($type) for table=$table, field=$field");
        }
        $fields{$table}->{$field}=$data;
    }
    $sth->finish();

    ##
    # Now loading classes translation table and putting fields
    # descriptions inside of it as well.
    #
    $sth=$dbh->prepare("SELECT class_name_,table_name_ FROM Global_Classes");
    $sth && $sth->execute() || $self->throw("_reload - SQL error");
    my %classes;
    while(my ($class,$table)=$sth->fetchrow_array) {
        my $f=$fields{$table};
        $f || $self->throw("_reload - no description for $table table (class $class)");
        $classes{$class}={ table => $table,
                           fields => $f
                         };
    }
    $sth->finish();

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

=item retrieve_fields ($$$@)

Retrieves individual fields from the given table by unique ID of the
row. Always returns array reference even if there is just one field in
it.

=cut

sub retrieve_fields ($$$$) {
    my $self=shift;
    my $table=shift;
    my $unique_id=shift;

    $unique_id || $self->throw("retrieve_field($table,...) - no unique_id given");

    my @names=map { $_ . '_' } @_;

    my $sql=join(',',@names);
    $sql="SELECT $sql FROM $table WHERE unique_id=?";

    my $sth=$self->{dbh}->prepare($sql);
    $sth && $sth->execute($unique_id) || $self->throw_sql("retrieve_field");

    my $row=$sth->fetchrow_arrayref;
    $sth->finish;

    $row;
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

    my $sth=$self->{dbh}->prepare($query->{sql});
    $sth && $sth->execute(@{$query->{values}}) || $self->throw_sql('search');

    my @results;
    while(my @row=$sth->fetchrow_array) {
        push @results,\@row;
    }
    $sth->finish;

    \@results;
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
    $rha=~s/([\\'\[\]])/\\$1/g;
    $rha=~s/\000/\\0/g;
    "$field REGEXP '[[:<:]]" . $rha . "[[:>:]]'";
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
    $rha=~s/\000/\\0/g;
    "$field REGEXP '[[:<:]]$rha'";
}

###############################################################################

=item setup_dictionary ($$$)

Supposed to set up dictionary tables if required. For MySQL driver it
does nothing as all dictionaries are stored in the same table currently
and this table is created when initial database layout is created.

=cut

sub setup_dictionary ($$$$) {
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

    $self->lock_tables($table);

    my $uid;
    if($key_value) {
        $uid=$self->unique_id($table,
                              $key_name,$key_value,
                              $conn_name,$conn_value,
                              1);
    } else {
        while(1) {
            $key_value=generate_key();
            #$key_value=sprintf('%5.2f',rand(100));
            last unless $self->unique_id($table,
                                         $key_name,$key_value,
                                         $conn_name,$conn_value,
                                         1);
        }
    }

    if($uid) {
        $self->update_row($table,$uid,$row);
    } else {
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

        my $sth=$self->{dbh}->prepare($sql);
        $sth && $sth->execute(@fv) || $self->throw_sql('store_row');
    }

    $self->unlock_tables($table);

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
        $sth=$self->{dbh}->prepare("SELECT unique_id FROM $table WHERE $conn_name=? AND $key_name=?");
        $sth && $sth->execute(''.$conn_value,''.$key_value) ||
            $self->throw_sql("unique_id");
    } else {
        $sth=$self->{dbh}->prepare("SELECT unique_id FROM $table WHERE $key_name=?");
        $sth && $sth->execute(''.$key_value) ||
            $self->throw_sql("unique_id");
    }

    my $row=$sth->fetchrow_arrayref;
    $sth->finish;
    $row ? $row->[0] : undef;
}

###############################################################################

=item update_dictionary ($table $uid $name $value)

Updates dictionary for the given field. Dictionary is supported by two
tables Global_Dictionary and Global_Backrefs. The first table is
dictionary itself, while the second holds references that allow to
delete/modify records in the dictionary quicker.

Here is an example content of Global_Dictionary with two names ('John
Silver' and 'John Doe') encoded. It assumes that unique_id's of rows
that holds `John Silver' and 'John Doe' in Customers table are 15 and 25
respectfully.

 | unique_id | table_name | field_name | strip  |  ids  |
 +-----------+------------+------------+--------+-------+
 |         1 | Customers  | name       | john   | 15,25 |
 |         2 | Customers  | name       | silver | 15    |
 |         3 | Customers  | name       | doe    | 25    |

Structure of Global_Backrefs for the same data:

 | unique_id | table_name | table_uid | field_name | ids |
 +-----------+------------+-----------+------------+-----+
 |         1 | Customers  | 15        | name       | 1,2 |
 |         2 | Customers  | 25        | name       | 1,3 |

=cut

sub update_dictionary ($$$$$) {
    my $self=shift;
    my ($table,$uid,$name,$strips)=@_;
    $name.='_';

    $self->lock_tables('Global_Dictionary');

    my %rows;
    my $dbh=$self->{dbh};
    my $sth=$dbh->prepare('DELETE FROM Global_Dictionary' .
                          ' WHERE table_name=? AND field_name=? AND table_uid=?');
    $sth && $sth->execute($table,$name,$uid) ||
        $self->throw_sql('update_dictionary');

    $sth=$dbh->prepare('INSERT INTO Global_Dictionary' .
                       ' (table_name,field_name,strip,table_uid)' .
                       ' VALUES (?,?,?,?)');
    my %inserted;
    foreach my $strip (@{$strips}) {
        next if $inserted{$strip};
        $inserted{$strip}=1;
        $sth && $sth->execute($table,$name,$strip,$uid) ||
            $self->throw_sql('update_dictionary');
    }

    $self->unlock_tables();
}

###############################################################################

=item update_field ($$$$) {

Stores new value into single data field. Example:

 $self->_driver->update_field($table,$unique_id,$name,$value);

=cut

sub update_field ($$$$$) {
    my $self=shift;
    my ($table,$unique_id,$name,$value)=@_;
    $name.='_';
    $unique_id || $self->throw("update_field($table,..,$name,..) - no unique_id given");
    my $sth=$self->{dbh}->prepare("UPDATE $table SET $name=? WHERE unique_id=?");
    $sth && $sth->execute(defined($value) ? ''.$value : undef,''.$unique_id) ||
        $self->throw_sql("update_field");
}

###############################################################################

=item update_key ($$$$) {

Stores new value into key field in the given table. If value for key is
not given then it generates new random one just like store_row does.

 $self->_driver->update_key($table,$unique_id,$key_name,$key_value);

=cut

sub update_key ($$$$$) {
    my $self=shift;
    my ($table,$unique_id,$key_name,$key_value,$conn_name,$conn_value)=@_;
    $key_name.='_';
    $conn_name.='_' if $conn_name;

    $self->lock_tables($table);

    if(! $key_value) {
        while(1) {
            $key_value=generate_key();
            last unless $self->unique_id($table,
                                         $key_name,$key_value,
                                         $conn_name,$conn_value,
                                         1);
        }
    }

    $self->update_field($table,$unique_id,$key_name,$key_value);

    if(defined($conn_name) && defined($conn_value)) {
        $self->update_field($table,$unique_id,$conn_name,$conn_value);
    }

    $self->unlock_tables();

    return $key_value;
}

###############################################################################

=item update_row ($$$$)

Updates multiple fields in the row by unique id and table.

Example:

 $self->_driver->update_row($table,$unique_id,\%row);

=cut

sub update_row ($$$$) {
    my $self=shift;
    my ($table,$uid,$row)=@_;

    my $sql="UPDATE $table SET ";
    $sql.=join(',',map { "${_}_=?" } keys %{$row});
    $sql.=' WHERE unique_id=?';

    my $sth=$self->{dbh}->prepare($sql);
    $sth && $sth->execute(values %{$row},$uid) ||
        $self->throw_sql('update_row');
}

###################################################################### PRIVATE

sub lock_tables ($@) {
    my $self=shift;
    my $sql='LOCK TABLES ';
    $sql.=join(',',map { "$_ WRITE" } @_);
    $self->{dbh}->do($sql) || $self->throw_sql('lock_tables');
}

sub unlock_tables ($) {
    my $self=shift;
    return unless $self->{dbh};
    $self->{dbh}->do('UNLOCK TABLES') ||
        die 'unlock_tables - failed';
}

##
# Throwing an error
#
sub throw ($@) {
    my $self=shift;
    $self->unlock_tables();
    throw XAO::E::DO::FS::Glue::MySQL_DBI join('',@_);
}

sub throw_sql ($$) {
    my $self=shift;
    my $method=shift;
    $self->throw($method . ' - SQL error (' . $self->{dbh}->errstr . ')');
}

sub DESTROY ($) {
    my $self=shift;
	$self->disconnect();
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Xao, Inc. (c) 2001. This module was developed by Andrew Maltsev
<am@xao.com> with help and valuable comments from other team members.

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue>.

=cut
