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
($VERSION)=(q$Id: MySQL_DBI.pm,v 1.15 2002/10/29 09:23:59 am Exp $ =~ /(\d+\.\d+)/);

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

    my $self=$proto->SUPER::new($args);

    my $dsn=$args->{dsn};
    $dsn || $self->throw("new - required parameter missed 'dsn'");
    $dsn=~/^OS:(\w+):(\w+)(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
    my $driver=$1;
    my $dbname=$2;
    my $dbopts=$3 || '';

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

    $self->sql_do($sql);
}

###############################################################################

=item delete_row ($$)

Deletes a row from the given name and unique_id.

=cut

sub delete_row ($$$) {
    my $self=shift;
    my ($table,$uid)=@_;

    $self->sql_do("DELETE FROM $table WHERE unique_id=?",$uid);
}

###############################################################################

=item disconnect ()

Permanently disconnects driver from database. Normally perl's garbage collector
will do that for you.

=cut

sub disconnect ($) {
    shift->sql_disconnect;
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

    $self->sql_do("DROP TABLE $table");
}

###############################################################################

=item increment_key_seq ($)

Increments the value of key_seq in Global_Fields table identified by the
given row unique ID. Returns previous value.

=cut

sub increment_key_seq ($$) {
    my $self=shift;
    my $uid=shift;

    my $sth=$self->sql_execute('SELECT key_seq_ FROM Global_Fields WHERE unique_id=?',$uid);
    my $seq=$self->sql_first_row($sth)->[0];
    if(!$seq) {
        $self->sql_do('UPDATE Global_Fields SET key_seq_=2 WHERE unique_id=?',$uid);
        return 1;
    }
    else {
        $self->sql_do('UPDATE Global_Fields SET key_seq_=key_seq_+1 WHERE unique_id=?',$uid);
        return $seq;
    }
}

###############################################################################

=item initialize_database ($)

Removes all data from all tables and creates minimal tables that support
objects database.

=cut

sub initialize_database ($) {
    my $self=shift;

    my $sth=$self->sql_execute('SHOW TABLES');
    while(my $row=$self->sql_fetch_row($sth)) {
        $self->sql_do("DROP TABLE $row->[0]");
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

    foreach my $clause (@initseq) {
        $self->sql_do($clause);
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

    ##
    # Checking if Global_Fields table has key_format_ and key_seq_
    # fields. Adding them if it does not.
    #
    my $sth=$self->sql_execute("DESC Global_Fields");
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
        }
        elsif($type eq 'key') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                refers      => $refers,
                key_format  => $key_format,
                key_unique_id => $uid,
            };
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

sub retrieve_fields ($$$@) {
    my $self=shift;
    my $table=shift;
    my $unique_id=shift;

    $unique_id || $self->throw("retrieve_field($table,...) - no unique_id given");

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
        while(my $row=$self->sql_fetch_row($sth)) {
            push @results,$row;
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
    # We need to lock Global_Fields too as it might be used in AUTOINC
    # key formats.
    #
    my @ltab=$table eq 'Global_Fields' ? ('Global_Fields') : ($table,'Global_Fields');
    $self->lock_tables(@ltab);

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
        $self->update_row($table,$uid,$row);
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

    $self->unlock_tables(@ltab);

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

=item update_field ($$$$) {

Stores new value into single data field. Example:

 $self->_driver->update_field($table,$unique_id,$name,$value);

=cut

sub update_field ($$$$$) {
    my $self=shift;
    my ($table,$unique_id,$name,$value)=@_;

    $unique_id ||
        throw $self "update_field($table,..,$name,..) - no unique_id given";

    $name.='_';

    defined($value) ||
        throw $self "update_field($table,..,$name,..) - undefined value given";

    $self->sql_do("UPDATE $table SET $name=? WHERE unique_id=?",
                  ''.$value,$unique_id);
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

    return unless keys %$row;

    my $sql="UPDATE $table SET ";
    $sql.=join(',',map { "${_}_=?" } keys %{$row});
    $sql.=' WHERE unique_id=?';

    my $sth=$self->sql_do($sql,values %$row,$uid);
}

###################################################################### PRIVATE

sub lock_tables ($@) {
    my $self=shift;
    my $sql='LOCK TABLES ';
    $sql.=join(',',map { "$_ WRITE" } @_);
    $self->sql_do($sql);
}

sub unlock_tables ($) {
    my $self=shift;
    return unless $self->sql_connected;
    $self->sql_do_no_error('UNLOCK TABLES');
}

sub throw ($@) {
    my $self=shift;
    $self->unlock_tables();
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

Copyright (c) 2001,2002 XAO, Inc.

This module was developed by Andrew Maltsev <am@xao.com> with the help
and valuable comments from other team members.

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue::SQL_DBI>,
L<XAO::DO::FS::Glue>.

=cut
