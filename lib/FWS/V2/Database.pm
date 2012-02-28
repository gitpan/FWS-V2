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


=head2 updateDatabase

Alter the database to match the schema for FWS 2.   The return will print the SQL statements used to adjust the tables.

	print $fws->updateDatabase()."\n";

=cut


sub updateDatabase {
        my ($self) = @_;
        my $db = "";

	#
	# build an array that we will process field by field
	#
        my @defs = (
                "queue_history","guid"                  ,"char(36)"     ,"MUL"          ,"",
                "queue_history","profile_guid"          ,"char(36)"     ,"MUL"          ,"",
                "queue_history","directory_guid"        ,"char(36)"     ,"MUL"          ,"",
                "queue_history","type"                  ,"char(50)"     ,"MUL"          ,"",
                "queue_history","queue_from"            ,"char(255)"    ,"MUL"          ,"",
                "queue_history","from_name"             ,"char(255)"    ,""             ,"",
                "queue_history","queue_to"              ,"char(255)"    ,"MUL"          ,"",
                "queue_history","subject"               ,"char(255)"    ,""             ,"",
                "queue_history","success"               ,"int(1)"       ,""             ,"0",
                "queue_history","body"                  ,"text"         ,""             ,"",
                "queue_history","hash"                  ,"text"         ,""             ,"",
                "queue_history","failure_code"          ,"char(255)"    ,""             ,"",
                "queue_history","response"              ,"char(255)"    ,""             ,"",
                "queue_history","sent_date"             ,"datetime"     ,""             ,"0000-00-00 00:00:00",
                "queue_history","scheduled_date"        ,"datetime"     ,""             ,"0000-00-00 00:00:00",


                "queue","guid"                          ,"char(36)"     ,"MUL"          ,"",
                "queue","profile_guid"                  ,"char(36)"     ,"MUL"          ,"",
                "queue","directory_guid"                ,"char(36)"     ,"MUL"          ,"",
                "queue","type"                          ,"char(50)"     ,"MUL"          ,"",
                "queue","queue_from"                    ,"char(255)"    ,"MUL"          ,"",
                "queue","queue_to"                      ,"char(255)"    ,"MUL"          ,"",
                "queue","draft"                         ,"int(1)"       ,""             ,"0",
                "queue","from_name"                     ,"char(255)"    ,""             ,"",
                "queue","subject"                       ,"char(255)"    ,""             ,"",
                "queue","mime_type"                     ,"char(100)"    ,""             ,"",
                "queue","transfer_encoding"             ,"char(100)"    ,""             ,"",
                "queue","digital_assets"                ,"text"         ,""             ,"",
                "queue","body"                          ,"text"         ,""             ,"",
                "queue","hash"                          ,"text"         ,""             ,"",
                "queue","scheduled_date"                ,"datetime"     ,""             ,"0000-00-00 00:00:00",


                "events","site_guid"                    ,"char(36)"     ,"MUL"          ,"",
                "events","guid"                         ,"char(36)"     ,"MUL"          ,"",
                "events","price"                        ,"double"       ,"MUL"          ,"0",
                "events","profile_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "events","name"                         ,"char(255)"    ,"FULLTEXT"     ,"",
                "events","title"                        ,"char(255)"    ,"FULLTEXT"     ,"",
                "events","city"                         ,"char(255)"    ,"MUL"          ,"",
                "events","state"                        ,"char(255)"    ,"MUL"          ,"",
                "events","address"                      ,"char(255)"    ,""             ,"",
                "events","address2"                     ,"char(255)"    ,""             ,"",
                "events","zip"                          ,"char(255)"    ,""             ,"",
                "events","location"                     ,"char(255)"    ,""             ,"",
                "events","website"                      ,"char(255)"    ,""             ,"",
                "events","phone"                        ,"char(255)"    ,""             ,"",
                "events","date_from"                    ,"datetime"     ,"MUL"          ,"0000-00-00",
                "events","date_to"			,"datetime"     ,"MUL"          ,"0000-00-00",
                "events","created_date"                 ,"datetime"     ,""             ,"0000-00-00",
                "events","description"                  ,"text"         ,"FULLTEXT"     ,"",
                "events","latitude"                     ,"float"        ,"MUL"          ,"0",
                "events","longitude"                    ,"float"        ,"MUL"          ,"0",
                "events","directory_guid"               ,"char(36)"     ,"MUL"          ,"",
                "events","extra_value"                  ,"text"         ,""             ,"",

                "history","site_guid"                   ,"char(36)"     ,"MUL"          ,"",
                "history","created_date"                ,"datetime"     ,""             ,"0000-00-00",
                "history","guid"                        ,"char(36)"     ,"MUL"          ,"",
                "history","type"                        ,"char(1)"      ,"MUL"          ,"",
                "history","name"                        ,"char(255)"    ,"FULLTEXT"     ,"",
                "history","url"                         ,"char(255)"    ,""             ,"",
                "history","title"                       ,"char(255)"    ,"FULLTEXT"     ,"",
                "history","latitude"                    ,"float"        ,"MUL"          ,"0",
                "history","longitude"                   ,"float"        ,"MUL"          ,"0",
                "history","hash"                        ,"text"         ,""             ,"",
                "history","description"                 ,"text"         ,"FULLTEXT"     ,"",
                "history","referrer_guid"               ,"char(36)"     ,"MUL"          ,"",
                "history","directory_guid"              ,"char(36)"     ,"MUL"          ,"",
                "history","profile_guid"                ,"char(36)"     ,"MUL"          ,"",

                "deal","site_guid"                      ,"char(36)"     ,"MUL"          ,"",
                "deal","created_date"                   ,"datetime"     ,""             ,"0000-00-00",
                "deal","guid"                           ,"char(36)"     ,"MUL"          ,"",
                "deal","active"                         ,"int(1)"       ,"MUL"          ,"0",
                "deal","type"                           ,"char(1)"      ,"MUL"          ,"",
                "deal","name"                           ,"char(255)"    ,"FULLTEXT"     ,"",
                "deal","latitude"                       ,"float"        ,"MUL"          ,"0",
                "deal","longitude"                      ,"float"        ,"MUL"          ,"0",
                "deal","price"                          ,"double"       ,"MUL"          ,"0",
                "deal","get_amount"                     ,"double"       ,"MUL"          ,"0",
                "deal","spend_amount"                   ,"double"       ,"MUL"          ,"0",
                "deal","qty_sold"                       ,"int(11)"      ,""             ,"0",
                "deal","qty_available"                  ,"int(11)"      ,""             ,"0",
                "deal","date_from"                      ,"datetime"     ,"MUL"          ,"0000-00-00",
                "deal","date_to"			,"datetime"     ,"MUL"          ,"0000-00-00",
                "deal","date_use_by"                    ,"datetime"     ,"MUL"          ,"0000-00-00",
                "deal","description"                    ,"text"         ,"FULLTEXT"     ,"",
                "deal","fine_print"                     ,"text"         ,"FULLTEXT"     ,"",
                "deal","image_1"                        ,"char(255)"    ,""             ,"",
                "deal","directory_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "deal","profile_guid"                   ,"char(36)"     ,"MUL"          ,"",
                "deal","extra_value"                    ,"text"         ,""             ,"",

                "directory","site_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "directory","guid"			,"char(36)"     ,"MUL"          ,"",
                "directory","pin"			,"char(6)"      ,"MUL"          ,"",
                "directory","created_date"              ,"datetime"     ,""             ,"0000-00-00",
                "directory","active"			,"int(1)"       ,"MUL"          ,"0",
                "directory","url"			,"char(255)"    ,"MUL"          ,"",
                "directory","name"			,"char(255)"    ,"FULLTEXT"     ,"",
                "directory","video_1"			,"char(255)"    ,""             ,"",
                "directory","video_2"			,"char(255)"    ,""             ,"",
                "directory","image_1"			,"char(255)"    ,""             ,"",
                "directory","image_2"			,"char(255)"    ,""             ,"",
                "directory","image_3"			,"char(255)"    ,""             ,"",
                "directory","image_4"			,"char(255)"    ,""             ,"",
                "directory","image_5"			,"char(255)"    ,""             ,"",
                "directory","category_1"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_2"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_3"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_4"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_5"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_6"                ,"char(255)"    ,"MUL"          ,"",
                "directory","address"			,"char(255)"    ,""             ,"",
                "directory","full_address"              ,"char(255)"    ,""             ,"",
                "directory","coupon_array"              ,"text"         ,""             ,"",
                "directory","deal_array"                ,"text"         ,""             ,"",
                "directory","address2"                  ,"char(255)"    ,""             ,"",
                "directory","phone"			,"char(20)"     ,""             ,"",
                "directory","website"			,"char(255)"    ,""             ,"",
                "directory","cost_rating"               ,"float"        ,""             ,"0",
                "directory","cost_rating_count"         ,"int(11)"      ,""             ,"0",
                "directory","rating"			,"float"        ,""             ,"0",
                "directory","rating_count"              ,"int(11)"      ,""             ,"0",
                "directory","city"			,"char(255)"    ,"MUL"          ,"",
                "directory","state"			,"char(255)"    ,"MUL"          ,"",
                "directory","zip"			,"char(255)"    ,"MUL"          ,"",
                "directory","country"			,"char(255)"    ,""             ,"",
                "directory","facebook_id"               ,"char(255)"    ,""             ,"",
                "directory","twitter_id"                ,"char(255)"    ,""             ,"",
                "directory","email"			,"char(255)"    ,""             ,"",
                "directory","description"               ,"text"         ,"FULLTEXT"     ,"",
                "directory","latitude"                  ,"float"        ,"MUL"          ,"0",
                "directory","longitude"                 ,"float"        ,"MUL"          ,"0",
                "directory","level"			,"int(3)"       ,"MUL"          ,"0",
                "directory","charity"			,"int(1)"       ,"MUL"          ,"0",
                "directory","claimed"			,"int(1)"       ,"MUL"          ,"0",
                "directory","claimed_profile_guid"      ,"char(36)"     ,"MUL"          ,"",
                "directory","claimed_validator_guid"    ,"char(36)"     ,"MUL"          ,"",
                "directory","extra_value"               ,"text"         ,""             ,"",

                "topic","site_guid"                     ,"char(36)"     ,"MUL"          ,"",
                "topic","guid"                          ,"char(36)"     ,"MUL"          ,"",
                "topic","created_date"                  ,"datetime"     ,""             ,"0000-00-00",
                "topic","name"                          ,"char(255)"    ,"MUL"          ,"",
                "topic","title"                         ,"char(255)"    ,"MUL"          ,"",
                "topic","tags"                          ,"char(255)"    ,"MUL"          ,"",
                "topic","description"			,"text"         ,"FULLTEXT"     ,"",
                "topic","content"                       ,"text"         ,"FULLTEXT"     ,"",
                "topic","content_1"                     ,"text"         ,"FULLTEXT"     ,"",
                "topic","content_2"                     ,"text"         ,"FULLTEXT"     ,"",
                "topic","fb_content"			,"text"         ,"FULLTEXT"     ,"",
                "topic","twitter_content"               ,"text"         ,"FULLTEXT"     ,"",
                "topic","directory_guid"                ,"char(36)"     ,"MUL"          ,"",
                "topic","active"                        ,"int(1)"       ,"MUL"          ,"0",
                "topic","draft"                         ,"int(1)"       ,"MUL"          ,"0",
                "topic","url"				,"char(255)"    ,""             ,"",
                "topic","image_1"                       ,"char(255)"    ,""             ,"",
                "topic","date_to"			,"date",        ,"MUL"          ,"0000-00-00",
                "topic","date_from"			,"date",        ,"MUL"          ,"0000-00-00",
                "topic","extra_value"                   ,"text"         ,""             ,"",

                "collection","site_guid"                ,"char(36)"     ,"MUL"          ,"",
                "collection","guid"                     ,"char(36)"     ,"MUL"          ,"",
                "collection","created_date"             ,"datetime"     ,""             ,"0000-00-00",
                "collection","campaignId"               ,"char(36)"     ,"MUL"          ,"0",
                "collection","dateLastVisited"          ,"datetime"     ,""             ,"0000-00-00",
                "collection","dateFirstVisited"         ,"datetime"     ,""             ,"0000-00-00",
                "collection","dateComplete"             ,"datetime"     ,"MUL"          ,"0000-00-00",
                "collection","source"                   ,"char(36)"     ,"MUL"          ,"",
                "collection","ip"			,"char(50)"     ,""             ,"",
                "collection","language"                 ,"char(2)"      ,""             ,"",
                "collection","session"                  ,"char(32)"     ,""             ,"",
                "collection","referrer"                 ,"char(255)"    ,""             ,"",
                "collection","firstName"                ,"char(255)"    ,"MUL"          ,"",
                "collection","lastName"                 ,"char(255)"    ,"MUL"          ,"",
                "collection","address"                  ,"char(255)"    ,""             ,"",
                "collection","address2"                 ,"char(255)"    ,""             ,"",
                "collection","city"                     ,"char(255)"    ,""             ,"",
                "collection","state"                    ,"char(255)"    ,""             ,"",
                "collection","zip"                      ,"char(255)"    ,""             ,"",
                "collection","email"                    ,"char(255)"    ,"MUL"          ,"",
                "collection","country"                  ,"char(255)"    ,""             ,"",
                "collection","purl"                     ,"char(255)"    ,""             ,"",
                "collection","synced"                   ,"int(1)"       ,""             ,"0",
                "collection","extra_value"              ,"text"         ,""             ,"",

                "auto","make"    			,"char(255)"    ,"MUL"          ,"",
                "auto","model"                          ,"char(255)"    ,"MUL"          ,"",
                "auto","year"      			,"char(4)"      ,"MUL"          ,"",

                "country","name"                        ,"char(255)"    ,""             ,"",
                "country","twoCharacter"                ,"char(2)"      ,""             ,"",
                "country","threeCharacter"              ,"char(3)"      ,""             ,"",

                "zipcode","zipCode"                     ,"char(7)"      ,"MUL"          ,"",
                "zipcode","zipType"                     ,"char(1)"      ,""             ,"",
                "zipcode","stateAbbr"                   ,"char(2)"      ,""             ,"",
                "zipcode","city"                        ,"char(255)"    ,"FULLTEXT"     ,"",
                "zipcode","areaCode"                    ,"char(3)"      ,""             ,"",
                "zipcode","timeZone"                    ,"char(12)"     ,""             ,"",
                "zipcode","UTC"                         ,"int(10)"      ,""             ,"0",
                "zipcode","DST"                         ,"char(1)"      ,""             ,"",
                "zipcode","latitude"                    ,"float"        ,"MUL"          ,"0",
                "zipcode","longitude"                   ,"float"        ,"MUL"          ,"0",
                "zipcode","loc_id"                      ,"int(11)"      ,"MUL"          ,"0",

                "geo_block","start_ip"                  ,"int(11)"      ,"MUL"          ,"0",
                "geo_block","end_ip"                    ,"int(11)"      ,"MUL"          ,"0",
                "geo_block","loc_id"                    ,"int(11)"      ,"MUL"          ,"0",

                "templates","site_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "templates","guid"                      ,"char(36)"     ,"MUL"          ,"",
                "templates","title"                     ,"char(255)"    ,""             ,"",
                "templates","default_template"          ,"int(1)"       ,""             ,"0",
                "templates","template_live"             ,"text"         ,""             ,"",
                "templates","template_devel"            ,"text"         ,""             ,"",
                "templates","css_live"                  ,"int(1)"       ,""             ,"0",
                "templates","css_devel"                 ,"int(1)"       ,""             ,"0",
                "templates","js_live"                   ,"int(1)"       ,""             ,"0",
                "templates","js_devel"                  ,"int(1)"       ,""             ,"0",

                "data_cache","site_guid"                ,"char(36)"     ,"MUL"          ,"",
                "data_cache","guid"                     ,"char(36)"     ,"MUL"          ,"",
                "data_cache","name"			,"char(255)"    ,"FULLTEXT"     ,"",
                "data_cache","title"			,"char(255)"    ,"FULLTEXT"     ,"",
                "data_cache","pageIdOfElement"          ,"char(36)"     ,""             ,"",
                "data_cache","pageDescription"          ,"text"         ,"FULLTEXT"     ,"",

                "data","site_guid"                      ,"char(36)"     ,"MUL"          ,"",
                "data","guid"                           ,"char(36)"     ,"MUL"          ,"",
                "data","name"                           ,"char(255)"    ,""             ,"",
                "data","title"                          ,"char(255)"    ,""             ,"",
                "data","nav_name"                       ,"char(255)"    ,""             ,"",
                "data","active"                         ,"int(1)"       ,"MUL"          ,"0",
                "data","lang"                           ,"char(2)"      ,"MUL"          ,"",
                "data","disable_title"                  ,"int(1)"       ,"MUL"          ,"0",
                "data","element_type"                   ,"char(50)"     ,"MUL"          ,"",
                "data","groups_guid"                    ,"char(36)"     ,""             ,"",
                "data","created_date"                   ,"datetime"     ,""             ,"0000-00-00",
                "data","disable_edit_mode"              ,"int(1)"       ,""             ,"0",
                "data","default_element"                ,"int(2)"       ,""             ,"0",
                "data","show_login"                     ,"int(1)"       ,""             ,"1",
                "data","show_resubscribe"               ,"int(1)"       ,""             ,"1",
                "data","friendly_url"                   ,"char(255)"    ,""             ,"",
                "data","extra_value"                    ,"text"         ,""             ,"",

                "admin_user","site_guid"                ,"char(36)"     ,"MUL"          ,"",
                "admin_user","guid"                     ,"char(36)"     ,"MUL"          ,"",
                "admin_user","user_id"                  ,"char(50)"     ,"MUL"          ,"",
                "admin_user","name"			,"char(255)"    ,""             ,"",
                "admin_user","email"			,"char(255)"    ,""             ,"",
                "admin_user","admin_user_password"      ,"char(50)"     ,"MUL"          ,"",
                "admin_user","active"			,"int(1)"       ,"MUL"          ,"1",
                "admin_user","extra_value"              ,"text"         ,""             ,"",

                "profile_groups_xref","site_guid"       ,"char(36)"     ,"MUL"          ,"",
                "profile_groups_xref","profile_guid"    ,"char(36)"     ,"MUL"          ,"",
                "profile_groups_xref","groups_guid"     ,"char(36)"     ,"MUL"          ,"",

                "profile","site_guid"			,"char(36)"     ,"MUL"          ,"",
                "profile","guid"			,"char(36)"     ,"MUL"          ,"",
                "profile","pin" 			,"char(6)"      ,"MUL"          ,"",
                "profile","profile_password"            ,"char(255)"    ,""             ,"",
                "profile","fb_access_token"             ,"char(255)"    ,""             ,"",
                "profile","fb_id"			,"char(255)"    ,""             ,"",
                "profile","email"			,"char(255)"    ,"MUL"          ,"",
                "profile","name" 			,"char(255)"    ,""             ,"",
                "profile","active"			,"int(1)"       ,""             ,"1",
                "profile","google_id"  			,"char(255)"    ,""             ,"",
                "profile","extra_value"                 ,"text"         ,""             ,"",

                "cart","site_guid"   			,"char(36)"     ,"MUL"          ,"",
                "cart","guid" 				,"char(36)"     ,"MUL"          ,"",
                "cart","name"   			,"char(255)"    ,""             ,"",
                "cart","qty"				,"int(11)"      ,""             ,"0",
                "cart","data_guid"			,"char(36)"     ,""             ,"",
                "cart","session"			,"char(32)"     ,""             ,"",
                "cart","created_date"  			,"datetime"     ,""             ,"0000-00-00",
                "cart","price"				,"double"       ,""             ,"0",
                "cart","sku"				,"char(50)"     ,""               ,"",
                "cart","extra_value"			,"text"         ,""             ,"",

                "fws_sessions","site_guid"              ,"char(36)"     ,"MUL"          ,"",
                "fws_sessions","ip"			,"char(50)"     ,"MUL"          ,"",
                "fws_sessions","b"                      ,"char(255)"    ,""             ,"",
                "fws_sessions","l"                      ,"char(50)"     ,""             ,"",
                "fws_sessions","bs"                     ,"char(50)"     ,""             ,"",
                "fws_sessions","e"                      ,"int(1)"       ,""             ,"0",
                "fws_sessions","s"                      ,"int(1)"       ,""             ,"0",
                "fws_sessions","a"                      ,"char(50)"     ,""             ,"",
                "fws_sessions","a_exp"                  ,"int(11)"      ,""             ,"0",
                "fws_sessions","extra"                  ,"text"         ,""             ,"",
                "fws_sessions","created"                ,"timestamp"    ,""             ,"CURRENT_TIMESTAMP",

                "guid_xref","site_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "guid_xref","child"                     ,"char(36)"     ,"MUL"          ,"",
                "guid_xref","parent"                    ,"char(36)"     ,"MUL"          ,"",
                "guid_xref","ord"                       ,"int(11)"      ,""             ,"0",
                "guid_xref","layout"                    ,"char(50)"     ,""             ,"",

                "element","site_guid"                   ,"char(36)"     ,"MUL"          ,"",
                "element","guid"                        ,"char(36)"     ,"MUL"          ,"",
                "element","type"                        ,"char(50)"     ,"MUL"          ,"",
                "element","parent"                      ,"char(36)"     ,"MUL"          ,"",
                "element","title"                       ,"char(255)"    ,""             ,"",
                "element","tags"                        ,"char(255)"    ,""             ,"",
                "element","class_prefix"                ,"char(255)"    ,""             ,"",
                "element","admin_group"                 ,"char(50)"     ,""             ,"",
                "element","ord"                         ,"int(11)"      ,""             ,"0",
                "element","public"                      ,"int(1)"       ,""             ,"0",
                "element","css_live"                    ,"int(1)"       ,""             ,"0",
                "element","js_live"                     ,"int(1)"       ,""             ,"0",
                "element","css_devel"                   ,"int(1)"       ,""             ,"0",
                "element","js_devel"                    ,"int(1)"       ,""             ,"0",
                "element","active"                      ,"int(1)"       ,""             ,"0",
                "element","checkedout"                  ,"int(1)"       ,""             ,"0",
                "element","root_element"                ,"int(1)"       ,""             ,"0",
                "element","script_devel"                ,"text"         ,""             ,"",
                "element","script_live"                 ,"text"         ,""             ,"",
                "element","schema_devel"                ,"text"         ,""             ,"",
                "element","schema_live"                 ,"text"         ,""             ,"",

                "groups","site_guid"                    ,"char(36)"     ,"MUL"          ,"",
                "groups","guid"                         ,"char(36)"     ,"MUL"          ,"",
                "groups","name"                         ,"char(50)"     ,""             ,"",
                "groups","description"                  ,"char(255)"    ,""             ,"",

                "site","site_guid"                      ,"char(36)"     ,""             ,"",
                "site","guid"                           ,"char(36)"     ,"MUL"          ,"",
                "site","email"                          ,"char(255)"    ,""             ,"",
                "site","name"                           ,"char(255)"    ,""             ,"",
                "site","sid"                            ,"char(50)"     ,"MUL"          ,"",
                "site","created_date"                   ,"datetime"     ,""             ,"0000-00-00",
                "site","gateway_type"                   ,"char(10)"     ,""             ,"",
                "site","gateway_user_id"                ,"char(150)"    ,""             ,"",
                "site","gateway_password"               ,"char(150)"    ,""             ,"",
                "site","home_guid"                      ,"char(36)"     ,""             ,"",
                "site","js_devel"                       ,"int(1)"       ,""             ,"0",
                "site","js_live"                        ,"int(1)"       ,""             ,"0",
                "site","css_devel"			,"int(1)"       ,""             ,"0",
                "site","css_live"			,"int(1)"       ,""             ,"0",
                "site","default_site"			,"int(1)"       ,""             ,"0",
                "site","extra_value"			,"text"         ,""             ,"",

                "coupon","site_guid"                    ,"char(36)"     ,"MUL"          ,"",
                "coupon","created_date"                 ,"datetime"     ,""             ,"0000-00-00",
                "coupon","name"                         ,"char(255)"    ,"MUL"          ,"",
                "coupon","date_to"			,"date",        ,"MUL"          ,"0000-00-00",
                "coupon","date_from"			,"date",        ,"MUL"          ,"0000-00-00",
                "coupon","persistent"			,"int(1)",      ,"MUL"          ,"0",
                "coupon","type"                         ,"char(1)"      ,"MUL"          ,"f",
                "coupon","amount"			,"double"       ,""             ,"0",
                "coupon","code"                         ,"char(255)"    ,"MUL"          ,"",
                "coupon","guid"				,"char(36)"     ,"MUL"          ,"",

                "trans","site_guid"                     ,"char(36)"     ,"MUL"          ,"",
                "trans","guid"				,"char(36)"     ,"MUL"          ,"",
                "trans","name"   			,"char(255)"    ,"MUL"          ,"",
                "trans","total"    			,"double"       ,""             ,"0",
                "trans","total_cost"    		,"double"       ,""             ,"0",
                "trans","created_date"                  ,"datetime"     ,""             ,"0000-00-00",
                "trans","paid_date"			,"datetime"     ,""             ,"0000-00-00",
                "trans","session"			,"char(32)"     ,""             ,"",
                "trans","email"				,"char(255)"    ,"MUL"          ,"",
                "trans","billing_email"                 ,"text"         ,""             ,"",
                "trans","tracking_number"               ,"char(255)"    ,""             ,"",
                "trans","recurring_key"                 ,"char(255)"    ,"MUL"          ,"",
                "trans","affiliate_id"                  ,"char(32)"     ,"MUL"          ,"",
                "trans","affiliate_id_2"                ,"char(32)"     ,"MUL"          ,"",
                "trans","referer"			,"char(255)"    ,"MUL"          ,"",
                "trans","archived"			,"int(1)",      ,"MUL"          ,"0",
                "trans","recurring"			,"int(1)",      ,"MUL"          ,"0",
                "trans","status"			,"int(11)",     ,"MUL"          ,"0",
                "trans","paid"    			,"int(1)",      ,"MUL"          ,"0",
                "trans","type"				,"char(2)",     ,"MUL"          ,"c",
                "trans","date_to"			,"date",        ,"MUL"          ,"0000-00-00",
                "trans","date_from"			,"date",        ,"MUL"          ,"0000-00-00",
                "trans","extra_value"			,"text",        ,""             ,"",

                "trans_item","site_guid"                ,"char(36)"     ,"MUL"          ,"",
                "trans_item","guid"			,"char(36)"     ,"MUL"          ,"",
                "trans_item","trans_guid"               ,"char(36)"     ,"MUL"          ,"",
                "trans_item","name"			,"char(255)"    ,""             ,"",
                "trans_item","qty"			,"int(11)"      ,""             ,"0",
                "trans_item","data_guid"                ,"char(36)"     ,""             ,"",
                "trans_item","price"			,"double"       ,""             ,"0",
                "trans_item","cost"			,"double"       ,""             ,"0",
                "trans_item","sku"                      ,"char(50)"     ,""             ,"",
                "trans_item","extra_value"              ,"text"         ,""             ,"");

        #
        # loop though the records and make the tables
        #
        my $dbResponse;
        while (@defs) {
                my $table       = shift(@defs);
                my $field       = shift(@defs);
                my $type        = shift(@defs);
                my $key         = shift(@defs);
                my $default     = shift(@defs);
                $dbResponse .= $self->alterTable(table=>$table,field=>$field,type=>$type,key=>$key,default=>$default);
        }


        #
        # get what fields we are aloud to use for data_cache
        # and make any fields that "might" be needed
        #
        foreach my $key ( keys %{$self->{"dataCacheFields"}} ) { $dbResponse .= $self->alterTable(table=>"data_cache",field=>$key,type=>"text",key=>"FULLTEXT",default=>"") }

        return $dbResponse;
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
