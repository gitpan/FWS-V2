package FWS::V2::Database;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Database - Framework Sites version 2 common database methods

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';


=head1 SYNOPSIS

	use FWS::V2;

        #
        # Create FWS with MySQL connectivity
        #
        my $fws = FWS::V2->new(       DBName          => "theDBName",
                                      DBUser          => "myUser",
                                      DBPassword      => "myPass");

        #
        # create FWS with SQLite connectivity
        #
        my $fws2 = FWS::V2->new(      DBType          => "SQLite",
                                      DBName          => "/home/user/your.db");



=head1 DESCRIPTION

Framework Sites version 2 common methods that connect, read, write, reorder or alter the database itself.


=head1 METHODS

=head2 connectDBH

Do the initial database connection via MySQL or SQLite.  This method will return back the DBH it creates, but it is only here for completeness and would normally never be used.  For FWS database routines this is not required as it will be implied when executing those methods..

        $fws->connectDBH();

=cut

sub connectDBH {
        my ($self) = @_;

        #
        # grab the DBI if we don't have it yet
        #
        if (!defined $self->{'_DBH'}) {

                #
                # hook up with some DBI
                #
                use DBI;

                #
                # default set to mysql
                #
                my $connectString = $self->{'DBType'}.":".$self->{'DBName'}.":".$self->{'DBHost'}.":3306";

                #
                # SQLite
                #
                if ($self->{'DBType'} =~ /SQLite/i) { $connectString = "SQLite:".$self->{'DBName'} }

                #
                # set the DBH for use throughout the script
                #
                $self->{'_DBH'} = DBI->connect("DBI:".$connectString,$self->{'DBUser'}, $self->{'DBPassword'});

                #
                # in case the user is going to do thier own thing, we will pass back the DBH
                #
                return $self->{'_DBH'};
        }
}



=head2 runSQL

Return an reference to an array that contains the results of the SQL ran.



        #
        # retrieve a reference to an array of data we asked for
        #
        my $dataArray = $fws->runSQL(SQL=>"select id,type from id_and_type_table");     # Any SQL statement or query

        #
        # loop though the array
        #
        while (@$dataArray) {

                #
                # collect the data each row at a time
                #
                my $id          = shift(@$dataArray);
                my $type        = shift(@$dataArray);

                #
                # display or do something with the data
                #
                print "ID: ".$id." - ".$type."\n";
        }


=cut

sub runSQL {
        my ($self,%paramHash) = @_;

        $self->connectDBH();

        #
        # Get this data array ready to slurp
        # and set the failFlag for future use to autocreate a dB schema
        # based on a default setting
        #
        my @data;
        my $errorResponse;

        #
        # use the dbh we were handed... if not use the default one.
        #
        if (!exists $paramHash{'DBH'}) {$paramHash{'DBH'} = $self->{'_DBH'}}

        #
        # once loging is turned on we can enable this
        #
        #$self->SQLLog($paramHash{'SQL'});

        #
        # prepare the SQL and loop though the arrays
        #

        my $sth = $paramHash{'DBH'}->prepare($paramHash{'SQL'});
        if ($sth ne '') {
                $sth->{PrintError} = 0;
                $sth->execute();

                #
                # clean way to get error response
                #
                if (defined $DBI::errstr) { $errorResponse .= $DBI::errstr }

                #
                # set the row variable ready to be populated
                #
                my @row;
                my @cleanRow;
                my $clean;

                #
                # SQL lite gathing and normilization
                #
                if ($self->{'DBType'} =~ /^SQLite$/i) {
                        while (@row = $sth->fetchrow) {
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        $clean =~ s/\\\\/\\/sg;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }

                #
                # Fault to MySQL if we didn't find another type
                #
                else {
                        while (@row = $sth->fetchrow) {
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }
        }

        #
        # check if myDBH has been blanked - if so we have an error
        # or I didn't have one to begin with
        #
        if ($errorResponse) {
                #
                # once FWSLog is enabled I can enable this
                #
                warn 'SQL ERROR: '.$paramHash{'SQL'}. ' - '.$errorResponse;
                #$self->FWSLog('SQL ERROR: '.$paramHash{'SQL'});
        }

        #
        # return this back as a normal array
        #
        return \@data;
}



=head2 alterTable

It is not recommended you would use the alterTable method outside of its intended core database creation and maintenance routines but is here for completeness.  Some of the internal table definitions alter data based on its context and will be unpredictable.  For work with table structures not directly tied to the FWS 2 core schema, use FWS::Lite in a non web rendered script.

        #
        # retrieve a reference to an array of data we asked for
        #
        # Note: It is not recommended to change the data structure of
        # FWS default tables
        #
        print $fws->alterTable( table   =>"table_name",         # case sensitive table name
                                field   =>"field_name",         # case sensitive field name
                                type    =>"char(255)",          # Any standard cross platform type
                                key     =>"",                   # MUL, PRIMARY KEY, FULL TEXT
                                default =>"");                  # '0000-00-00', 1, 'this default value'...

=cut


#
# param pushed version, used internally for code compability, Not for external consumption!!!
#
sub ATable {
        my ($self, $table,$field,$type,$key,$default)= @_;
	$self->alterTable(  	table   =>$table,
                                field   =>$field,
                                type    =>$type,          
                                key     =>$key,                   
                                default =>$default);                  
	}

sub alterTable {
        my ($self, %paramHash) =@_;

	#
	# because this is only called interanally and all data is static and known, we can be a little laxed on safety
	# there is no need to wrapper everything in safeSQL - even so in the context of some parts here we actually
	# might even been adding tics out of place on purpose.
	#

        #
        # set some vars we will flip depending on db type alot is defaulted to mysql, because that
        # is the norm, we will groom things that need to be groomed
        #
        my $sqlReturn;
        my $autoIncrement       = "AUTO_INCREMENT ";
        my $indexStatement      = "alter table ".$paramHash{'table'}." add INDEX ".$paramHash{'table'}."_".$paramHash{'field'}." (".$paramHash{'field'}.")";

        #
        # if default is timestamp lets not put tic's around it
        #
        if ($paramHash{'default'} ne 'CURRENT_TIMESTAMP') { 
		$paramHash{'default'} =
                                                "'".
                                                $paramHash{'default'}.
                                                "'" }

        my $addStatement        = "alter table ".$paramHash{'table'}." add ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};
        my $changeStatement     = "alter table ".$paramHash{'table'}." change ".$paramHash{'field'}." ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};


        #
        # add primary key if the table is not an ext field
        #
        my $primaryKey = "PRIMARY KEY";

        #
        # show tables statement
        #
        my $showTablesStatement = "show tables";

        #
        # do SQLLite changes
        #
        if ($self->DBType() =~ /^sqlite$/i) {
                $autoIncrement = "";
                $indexStatement = "create index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                $showTablesStatement = "select name from sqlite_master where type='table'";
        }


        #
        # do mySQL changes
        #
        if ($self->DBType() =~ /^mysql$/i) {
                if ($paramHash{'key'} eq 'FULLTEXT') {
                        $indexStatement = "create FULLTEXT index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                }
        }

  	#
        # FULTEXT is MUL if not mysql, and mysql returns them as MUL even if they are full text so we don't need to updated them if they are set to that
        # so lets change it to MUL to keep mysql and other DB's without FULLTEXT syntax happy
        #
        if ($paramHash{'key'} eq 'FULLTEXT') { $paramHash{'key'} = 'MUL' }

        #
        # blank by default because we use guid - enxt if we are trans we need order ids for easy to read transactions
        #
        my $idField = '';
        if ($paramHash{'table'} eq 'trans') { $idField = ", id INTEGER ".$autoIncrement.$primaryKey }

        #
        # if its the sessions table make it like this
        #
        if ($paramHash{'table'} eq 'fws_sessions') { $idField = ", id char(50) ".$primaryKey }

        #
        # compile the statement
        #
        my $createStatement = "create table ".$paramHash{'table'}." (site_guid char(16) NOT NULL default ''".$idField.")";


        #
        # get the table hash
        #
        my %tableHash;
        my @tableList = $self->openRS($showTablesStatement);
        while (@tableList) {
                my $fieldInc                       = shift(@tableList);
                $tableHash{$fieldInc} = '1';
        }

        #
        # create tht table if it does not exist
        #
        if ($tableHash{$paramHash{'table'}} ne '1') {
                $self->runSQL(SQL=>$createStatement);
                $sqlReturn .= $createStatement."; ";
        }

        #
        # get the table deffinition hash
        #
        my $tableFieldHash = $self->tableFieldHash($paramHash{'table'});

        #
        # make the field if its not there
        #
        if ($tableFieldHash->{$paramHash{'field'}}{"type"} eq "") {
                $self->runSQL(SQL=>$addStatement);
                $sqlReturn .= $addStatement."; ";
        }



        #
        # change the datatype if we are talking about MySQL for now if your SQLite
        # we still have to add support for that
        #
        if ($paramHash{'type'} ne $tableFieldHash->{$paramHash{'field'}}{"type"} && $self->DBType() =~ /^mysql$/i) {
                $self->runSQL(SQL=>$changeStatement);
                $sqlReturn .= $changeStatement."; ";
        }

        #
        # set any keys if not the same;
        #
        if ($tableFieldHash->{$paramHash{'table'}."_".$paramHash{'field'}}{"key"} ne "MUL" && $paramHash{'key'} ne "") {
                $self->runSQL(SQL=>$indexStatement);
                $sqlReturn .=  $indexStatement."; ";
        }

        return $sqlReturn;
}

=head2 tableFieldHash

Return a multi-dimensional hash of all the fields in a table with its properties.  This usually isn't used by anything but internal table alteration methods, but it could be useful for someone making conditionals to determine the data structure before adding or changing data.

        $tableFieldHashRef = $fws->tableFieldHash('the_table');

        #
        # the return dump will have the following structure
        #
        $hash->{field}{type}
        $hash->{field}{key}
        $hash->{field}{ord}
        $hash->{field}{null}
        $hash->{field}{default}
        $hash->{field}{extra}

        $hash->{field_2}{type}
        $hash->{field_2}{key}
        $hash->{field_2}{ord}
        $hash->{field_2}{null}
        $hash->{field_2}{default}
        $hash->{field_2}{extra}

        ...


=cut

sub tableFieldHash {
        my ($self,$table) = @_;

        #
        # set an order counter so we can sort by this if needed
        #
        my $fieldOrd = 0;

        #
        # TODO CACHE
        #
        my $tableFieldHash = {};

        #
        #  if we have a cached version, just return it
        #
        if (!keys %$tableFieldHash) {
                #
                # we are not pulling this from cache, lets start from scratch
                #
                my %tableFieldHash;


                #
                # grab the table def hash for mysql
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        my $tableData = $self->runSQL(SQL=>"desc ".$table);
                        while (@$tableData) {
                                $fieldOrd++;
                                my $fieldInc                                    = shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'type'}              = shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'ord'}               = $fieldOrd;
                                $tableFieldHash{$fieldInc}{'null'}              = shift(@$tableData);
                                $tableFieldHash{$table."_".$fieldInc}{'key'}    = shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'default'}           = shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'extra'}             = shift(@$tableData);
                        }
                }

                #
                # grab the table def hash for sqlite
                #
                if ($self->{'DBType'} =~ /^sqlite$/i) {
                        my $tableData = $self->runSQL(SQL=>"PRAGMA table_info(".$table.")");
                        while (@$tableData) {
                                                                        shift(@$tableData);
                                my $fieldInc =                          shift(@$tableData);
                                                                        shift(@$tableData);
                                                                        shift(@$tableData);
                                                                        shift(@$tableData);
                                $tableFieldHash{$fieldInc}{'type'} =    shift(@$tableData);

                                $fieldOrd++;
                                $tableFieldHash{$fieldInc}{'ord'}       = $fieldOrd;
                        }

                        $tableData = $self->runSQL(SQL=>"PRAGMA index_list(".$table.")");
                        while (@$tableData) {
                                                        shift(@$tableData);
                                my $fieldInc =          shift(@$tableData);
                                                        shift(@$tableData);

                                $tableFieldHash{$fieldInc}{"key"} = "MUL";
                        }
                }
                return \%tableFieldHash;
        }
        else {
                #
                # TODO SAVE CACHE
                #
        }
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Database


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Database
