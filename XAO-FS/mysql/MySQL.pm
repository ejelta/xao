=head1 NAME

XAO::DO::FS::Glue::MySQL - MySQL driver for XAO::FS

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

B<Not finished, is being worked on! Unusable.>

This module implements some functionality required by XAO::DO::FS::Glue
in MySQL specific way.

The advantage of this module over MySQL_DBI is that it does not use DBI
and therefore is faster. As XAO::FS has specific drivers for each
database anyway it does not make a lot of sense to use DBI.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::MySQL;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error;

###############################################################################

require DynaLoader;
use base qw(DynaLoader);
bootstrap XAO::DO::FS::Glue::MySQL;

###############################################################################

=item new ($%)

Creates new instance of driver connected to the given $dbh handler. An
example:

 my $driver=XAO::Objects->new(objname => 'FS::Glue::MySQL',
                              dbh => $dbh);

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);
    my $class=ref($proto) || $proto;

    ##
    # Our object
    #
    my $self={
        class => $class,
        objname => $args->{objname},
        dbh => $args->{dbh}
    };

    ##
    # Returning resulting object
    #
    bless $self, $class;
}

###############################################################################

=item add_field_text ($$$)

Adds new text field to the given table.

=cut

sub add_field_text ($$$$) {
    my $self=shift;
    my ($table,$name,$max)=@_;

    my $sth;
    if($max<255) {
        $sth=$self->{dbh}->prepare("ALTER TABLE $table ADD $name CHAR($max)");
    } elsif($max<65535) {
        $sth=$self->{dbh}->prepare("ALTER TABLE $table ADD $name TEXT");
    } elsif($max<16777215) {
        $sth=$self->{dbh}->prepare("ALTER TABLE $table ADD $name MEDIUMTEXT");
    } elsif($max<4294967295) {
        $sth=$self->{dbh}->prepare("ALTER TABLE $table ADD $name LONGTEXT");
    }

    $sth && $sth->execute && $sth->finish || $self->throw_sql('add_field_text');
}

###############################################################################

=item add_reference_fields ($$$)

Adds new key and connector fields to the existing table. Used when
secondary reference is created for the same object.

=cut

sub add_reference_fields ($$$$) {
    my $self=shift;
    my ($table,$key,$connector)=@_;

    $self->{dbh}->do("ALTER TABLE $table ADD $key CHAR(20)") ||
        $self->throw_sql('add_reference_fields');
    $self->{dbh}->do("ALTER TABLE $table ADD INDEX $key($key)") ||
        $self->throw_sql('add_reference_fields');

    if(defined($connector)) {
        $self->{dbh}->do("ALTER TABLE $table ADD $connector CHAR(20)") ||
            $self->throw_sql('add_reference_fields');
        $self->{dbh}->do("ALTER TABLE $table ADD INDEX $connector($connector)") ||
            $self->throw_sql('add_reference_fields');
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

    my $sql="CREATE TABLE $table (" . 
            " unique_id INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY," .
            " $key CHAR(20)," .
            " INDEX $key($key)" .
            (defined($connector) ? ", $connector CHAR(20)" .
                                   ", INDEX $connector($connector)"
                                 : "") .
            ")";

##    dprint "add_table($table,$key,$connector): $sql";

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

=item drop_field ($$)

Drops the given field from the given table in the database. Whatever
content was in that field is lost irrevocably.

=cut

sub drop_field ($$$) {
    my $self=shift;
    my ($table,$name)=@_;

    my $sth=$self->{dbh}->prepare("ALTER TABLE $table DROP $name");
    $sth && $sth->execute && $sth->finish || $self->throw_sql('drop_field');
}

###############################################################################

=item empty_field ($$$)

Removes content of given field in the given table by storing NULL in it.

=cut

sub empty_field ($$$$) {
    my $self=shift;
    my ($table,$unique_id,$name)=@_;

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
  unique_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  table_name char(20) NOT NULL default '',
  field_name char(20) NOT NULL default '',
  type char(20) NOT NULL default '',
  refers char(20) default NULL,
  maxlength int(10) unsigned default NULL,
  dictionary char(20) default NULL,
  bitsize enum('8','16','24','32') default NULL,
  maxvalue double default NULL,
  minvalue double default NULL,
  PRIMARY KEY  (table_name,field_name),
  UNIQUE KEY unique_id (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Fields VALUES (1,'Global_Data','project',
                                  'text','',40,'',NULL,NULL,NULL)
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
  project char(40),
  PRIMARY KEY (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Data VALUES (1,'XAO::FS New Database')
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Classes (
  unique_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  class_name char(100) NOT NULL default '',
  table_name char(20) NOT NULL default '',
  PRIMARY KEY  (unique_id),
  UNIQUE KEY  (class_name)
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

=item retrieve_field ($$$$)

Retrieves individual field from the given table by unique ID of the row.

=cut

sub retrieve_field ($$$$) {
    my $self=shift;
    my ($table,$unique_id,$name)=@_;
    $unique_id || $self->throw("retrieve_field($name,undef,$table) - no unique_id given");
    my $sth=$self->{dbh}->prepare("SELECT $name FROM $table WHERE unique_id=?");
    $sth && $sth->execute(''.$unique_id) || $self->throw_sql("retrieve_field");
    my $row=$sth->fetchrow_arrayref;
    $sth->finish;
    $row ? $row->[0] : undef;
}

###############################################################################

=item search ($table $keyname $c_name $c_value $lha $op $rha)

Searches on single condition in single table and returns a reference to
the list of values in the given key field. Even if the list is empty a
reference to the empty list is still returned.

Example:

 $self->_driver->search($table,$$self->{key_name},
                        $$self->{connector_name},$$self->{base_id},
                        'first_name', 'eq', 'john');

=cut

sub search ($$$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$conn_name,$conn_value,$lha,$op,$rha)=@_;

    my $select_value;
    my $sql_cond;
    my $rhv=$rha;
    if($op eq 'eq') {
        $sql_cond="$lha = ?";
    } elsif($op eq 'ne') {
        $sql_cond="$lha <> ?";
    } elsif($op eq 'gt') {
        $sql_cond="$lha > ?";
    } elsif($op eq 'ge') {
        $sql_cond="$lha >= ?";
    } elsif($op eq 'lt') {
        $sql_cond="$lha < ?";
    } elsif($op eq 'le') {
        $sql_cond="$lha <= ?";
    } elsif($op eq 'wq' || $op eq 'ws') {
        $select_value=1;
        $sql_cond="$lha like ?";
        if($rha =~ /^(\w+)$/) {
            $rhv='%' . $rha . '%';
        } else {
            return [ ];
        }
    } else {
        $self->throw("search - unknown operator in ($lha $op '$rha')");
    }

    my $sql="SELECT $key_name";
    $sql.=",$lha" if $select_value;
    $sql.=" FROM $table WHERE ";
    if($conn_name && $conn_value) {
        $sql.="$conn_name='$conn_value' AND ";
    }
    $sql.=$sql_cond;

    my $sth=$self->{dbh}->prepare($sql);
    $sth && $sth->execute($rhv) || $self->throw_sql('search');

    my @results;
    if($op eq 'ws') {
        while(my ($id,$value)=$sth->fetchrow_array) {
            my $regex='(^|\W)' . lc($rha);
            next unless lc($value) =~ $regex;
            push @results,$id;
        }
    } elsif($op eq 'wq') {
        while(my ($id,$value)=$sth->fetchrow_array) {
            my $regex='(^|\W)' . lc($rha) . '(\W|$)';
            next unless lc($value) =~ $regex;
            push @results,$id;
        }
    } else {
        while(my ($id)=$sth->fetchrow_array) {
            push @results,$id;
        }
    }
    $sth->finish;

    \@results;
}

###############################################################################

=item search_dictionary ($table $keyname $c_name $c_value $lha $op $rha)

Searches on single condition in single table using dictionary and
returns a reference to the list of values in the given key field. Even
if the list is empty a reference to the empty list is still returned.

Only supported operations are 'wq' and 'ws'.

=cut

sub search_dictionary ($$$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$conn_name,$conn_value,$lha,$op,$rha)=@_;

    ## dprint "table=$table key_name=$key_name lha=$lha op=$op rha=$rha";

    my $sql_cond;
    my $rhv;
    if($op eq 'wq') {
        $sql_cond="=";
        $rhv=$rha;
    } elsif($op eq 'ws') {
        $sql_cond="like";
        $rhv=$rha . '%';
    } else {
        $self->throw("search_dictionary - unknown operator in ($lha $op '$rha')");
    }

    my $sql="SELECT t.$key_name" .
             " FROM Global_Dictionary AS d,$table AS t" .
            " WHERE d.table_name=?" .
              " AND d.field_name=?" .
              " AND d.strip $sql_cond ?" .
              " AND t.unique_id=d.table_uid";
    my @xa;
    if($conn_name && $conn_value) {
        $sql.=" AND $conn_name=?";
        @xa=($conn_value);
    }
    dprint "SEARCH SQL: $sql";
    dprint "<< '",join("','",$table,$lha,$rhv,@xa),"' >>";
    my $sth=$self->{dbh}->prepare($sql);
    $sth && $sth->execute($table,$lha,$rhv,@xa) || $self->throw_sql('search');
    my %used;
    my @results;
    while(my ($id)=$sth->fetchrow_array) {
        next if $used{$id};
        $used{$id}=1;
        push @results,$id;
    }
    $sth->finish;

    \@results;
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

    $self->lock_tables($table);

    my $uid;
    if($key_value) {
        $uid=$self->unique_id($table,
                              $key_name,$key_value,
                              $conn_name,$conn_value);
    } else {
        while(1) {
            $key_value=generate_key();
            #$key_value=sprintf('%5.2f',rand(100));
            last unless $self->unique_id($table,
                                         $key_name,$key_value,
                                         $conn_name,$conn_value);
        }
    }

    if($uid) {
        $self->update_row($table,$uid,$row);
    } else {
##dprint "store_row: row=",join(',',%{$row ? $row : {}});
        my @fn=($key_name, keys %{$row});
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
##        dprint $sql;
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

sub unique_id ($$$$$$) {
    my $self=shift;
    my ($table,$key_name,$key_value,$conn_name,$conn_value)=@_;

    my $sth;
    if(defined($conn_name) && defined($conn_value)) {
        $sth=$self->{dbh}->prepare("SELECT unique_id FROM $table WHERE $conn_name=? AND $key_name=?");
        $sth && $sth->execute(''.$conn_value,''.$key_value) ||
            $self->throw_sql("retrieve_field");
    } else {
        $sth=$self->{dbh}->prepare("SELECT unique_id FROM $table WHERE $key_name=?");
        $sth && $sth->execute(''.$key_value) ||
            $self->throw_sql("retrieve_field");
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

    $self->lock_tables($table);

    if(! $key_value) {
        while(1) {
            $key_value=generate_key();
            last unless $self->unique_id($table,
                                         $key_name,$key_value,
                                         $conn_name,$conn_value);
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
    $sql.=join(',',map { "$_=?" } keys %{$row});
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
    $self->{dbh}->do('UNLOCK TABLES') || die 'unlock_tables - failed';
}

#########
# Temporary..
#
sub throw ($@) {
    my $self=shift;
    $self->unlock_tables();
    throw Error::Simple ref($self)."::".join('',@_,"\n");
}

sub throw_sql ($$) {
    my $self=shift;
    my $method=shift;
    $self->throw($method . ' - SQL error (' . $self->{dbh}->errstr . ')');
}

sub DESTROY ($) {
    my $self=shift;
    $self->unlock_tables();
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
