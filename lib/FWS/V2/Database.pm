package FWS::V2::Database;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Database - Framework Sites version 2 data management

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';


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

=head2 addExtraHash

In FWS database tables there is a field named extra_value.  This field holds a hash that is to be appended to the return hash of the record it belongs to.
        
	#
        # If we have an extra_value field and a real hash lets combine them together
        #
        %dataHash = $fws->addExtraHash($extra_value,%dataHash);

Note: If anything but stored extra_value strings are passed, the method will throw an error

=cut


sub addExtraHash {
        my ($self,$extraValue,%addHash) = @_;

        #
        # lets use storable in comptabile nfreeze mode
        #
        use Storable qw(nfreeze thaw);

        #
        # pull the hash out
        #
        my %extraHash;

        #
        # only if its populated unthaw it
        #
        if ($extraValue ne '') { %extraHash = %{thaw($extraValue)} }

        #
        # return the two hashes combined together
        #
        my %mergedHash = (%addHash,%extraHash);
        return %mergedHash;
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
        my $createStatement = "create table ".$paramHash{'table'}." (site_guid char(36) NOT NULL default ''".$idField.")";


        #
        # get the table hash
        #
        my %tableHash;
        my @tableList = @{$self->runSQL(SQL=>$showTablesStatement)};
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
        my %tableFieldHash = $self->tableFieldHash($paramHash{'table'});

        #
        # make the field if its not there
        #
        if ($tableFieldHash{$paramHash{'field'}}{"type"} eq "") {
                $self->runSQL(SQL=>$addStatement);
                $sqlReturn .= $addStatement."; ";
        }



        #
        # change the datatype if we are talking about MySQL for now if your SQLite
        # we still have to add support for that
        #
        if ($paramHash{'type'} ne $tableFieldHash{$paramHash{'field'}}{"type"} && $self->DBType() =~ /^mysql$/i) {
                $self->runSQL(SQL=>$changeStatement);
                $sqlReturn .= $changeStatement."; ";
        }

        #
        # set any keys if not the same;
        #
	$self->FWSLog($paramHash{'table'}."_".$paramHash{'field'}." ". $tableFieldHash{$paramHash{'table'}."_".$paramHash{'field'}}{"key"}  );
        if ($tableFieldHash{$paramHash{'table'}."_".$paramHash{'field'}}{"key"} ne "MUL" && $paramHash{'key'} ne "") {
                $self->runSQL(SQL=>$indexStatement);
                $sqlReturn .=  $indexStatement."; ";
        }

        return $sqlReturn;
}


=head2 connectDBH

Do the initial database connection via MySQL or SQLite.  This method will return back the DBH it creates, but it is only here for completeness and would normally never be used.  For FWS database routines this is not required as it will be implied when executing those methods.
        
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
		# DBType for mysql is always lower case
		#
                if ($self->{'DBType'} =~ /mysql/i) { $self->{'DBType'} = lc($self->{'DBType'}) }

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


=head2 dataArray

Retrieve a hash array based on any combination of keywords, type, guid, or tags

	my @dataArray = $fws->dataArray(guid=>$someParentGUID);
	for my $i (0 .. $#dataArray) {
     		$valueHash{'html'} .= $dataArray[$i]{'name'}."<br/>";
	}

Any combination of the following parameters will restrict the results.  At least one is required.

=over 4

=item * guid: Retrieve any element whose parent element is the guid

=item * keywords: A space delimited list of keywords to search for

=item * tags: A comma delimited list of element tags to search for

=item * type: Match any element which this exact type

=item * containerId: Pull the data from the data container

=item * childGUID: Retrieve any element whose child element is the guid (This option can not be used with keywords attribute)

=item * showAll: Show active and inactive records. By default only active records will show

=back

Note: guid and containerId cannot be used at the same time, as they both specify the parent your pulling the array from

=cut

sub dataArray {
        my ($self,%paramHash) = @_;

        #
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {

                #
                # if we don't get one, we will fail on the next check because we won't have a guid
                #
                ($paramHash{'guid'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' LIMIT 1")};

        }

        #
        # if we don't have any data to search for get out so we don't get "EVERYTHING"
        #
        if ($paramHash{'childGUID'} eq '' && $paramHash{'guid'} eq '' && !$paramHash{'type'} && $paramHash{'keywords'} eq '' && $paramHash{'tags'} eq '') {
                  return ();
        }

        #
        # get the where and join builders ready for content
        #
        my $addToExtWhere       = "";
        my $addToDataWhere      = "";
        my $addToExtJoin        = "";
        my $addToDataXRefJoin   = "";

	#
        # bind by element Type could be a comma delemented List
        #
        if ($paramHash{'type'} ne '') {
                my @typeArray   = split(/,/,$paramHash{'type'});
                $addToDataWhere .= 'and (';
                $addToExtWhere  .= 'and (';
                while (@typeArray) {
                        my $type = shift(@typeArray);
                        $addToDataWhere .= "data.element_type like '".$type."' or ";
                }
                $addToExtWhere  =~ s/ or $//g;
                $addToExtWhere  .= ')';
                $addToDataWhere =~ s/ or $//g;
                $addToDataWhere .= ')';
        }

        #
        # data left join connector
        #
        my $dataConnector =  'guid_xref.child=data.guid';

        #
        # bind critera by child guid, so we are only seeing stuff who's child = #
        #
        if($paramHash{'childGUID'} ne '') {
                $addToExtWhere  .= "and guid_xref.child = '".$self->safeSQL($paramHash{'childGUID'})."' ";
                $addToDataWhere .= "and guid_xref.child = '".$self->safeSQL($paramHash{'childGUID'})."' ";
                $dataConnector  = 'guid_xref.parent=data.guid'
        }

        #
        # bind critera by array guid, so we are only seeing stuff who's parent = #
        #
        if ($paramHash{'guid'} ne '') {
                $addToExtWhere  .= "and guid_xref.parent = '".$self->safeSQL($paramHash{'guid'})."' ";
                $addToDataWhere .= "and guid_xref.parent = '".$self->safeSQL($paramHash{'guid'})."' ";
        }


	#
	# find data by tags
	#
        if ($paramHash{'tags'} ne '') {
                my @tagsArray = split(/,/,$paramHash{'tags'});
                my $tagGUIDs = '';
                while (@tagsArray) {
                        my $checkTag = shift(@tagsArray);

                        #
                        # bind by tags Type could be a comma delemented List
                        #
                        my %elementHash = $self->_fullElementHash();


			for my $elementType ( keys %elementHash ) {
                        my $incTags = $elementHash{$elementType}{"tags"};
                        if (            ($incTags =~/^$checkTag$/
                                                || $incTags =~/^$checkTag,/
                                                || $incTags =~/,$checkTag$/
                                                || $incTags =~/,$checkTag,$/
                                                )
                                                && $incTags ne '' && $checkTag ne '') {
                                        $tagGUIDs .= ',\''.$elementType.'\'';
                                        }
                                }
                        }

                $addToDataWhere .= 'and (data.element_type in (\'\''.$tagGUIDs.'))';
                $addToExtWhere  .= 'and (data.element_type in (\'\''.$tagGUIDs.'))';
                }


        #
        # add the keywordScore field response
        #
        my $keywordScoreSQL = '1';
        my $dataCacheSQL = '1';
        my $dataCacheJoin = '';

        #
        # if any keywords are added,  and create an array of ID's and join them into comma delmited use
        #
        if ($paramHash{'keywords'} ne '') {

                #
                # build the field list we will search against
                #
                my @fieldList = ("data_cache.title","data_cache.name");
                for my $key ( keys %{$self->{"dataCacheFields"}} ) { push(@fieldList,"data_cache.".$key) }

                #
                # set the cache and join statement starters
                #
                $dataCacheSQL   = 'data_cache.pageIdOfElement';
                $dataCacheJoin  = 'left join data_cache on (data_cache.guid=child)';

                #
                # do some last minute checking for keywords stablity
                #
                $paramHash{'keywords'} =~ s/[^a-zA-Z0-9 \.\-]//sg;

                #
                # build the actual keyword chains
                #
                $addToDataWhere .= " and data.active='1' and (";
                $addToDataWhere .= $self->_getKeywordSQL($paramHash{'keywords'},@fieldList);
                $addToDataWhere .= ")";

                #
                # if we are on mysql lets do some fuzzy matching
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        $keywordScoreSQL = "(";
                        while (@fieldList) {
                                $keywordScoreSQL .= "(MATCH (".$self->safeSQL(shift(@fieldList)).") AGAINST ('".$self->safeSQL($paramHash{'keywords'})."'))+"
                                }
                        $keywordScoreSQL =~ s/\+$//sg;
                        $keywordScoreSQL =  $keywordScoreSQL.")+1 as keywordScore";
                        }
                }

        my @hashArray;
        my $recordData = $self->runSQL(SQL=>"select distinct ".$keywordScoreSQL.",".$dataCacheSQL.",data.extra_value,data.guid,data.created_date,data.lang,guid_xref.site_guid,data.site_guid,data.active,data.friendly_url,data.title,data.disable_title,data.default_element,data.disable_edit_mode,data.element_type,data.nav_name,data.name,guid_xref.parent,guid_xref.layout from guid_xref ".$dataCacheJoin."  left join data on (guid_xref.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."') and ".$dataConnector." ".$addToDataXRefJoin." ".$addToExtJoin."   left join element on (element.guid = data.element_type or data.element_type = element.type) where guid_xref.parent != '' and guid_xref.site_guid is not null ".$addToDataWhere." order by guid_xref.ord");


        #
        # for speed we will add this to here so we don't have to ask it EVERY single time we loop though the while statemnent
        #
        my $showMePlease = 0;
        if (($paramHash{'showAll'} eq '1' || $self->formValue('editMode') eq '1' || $self->formValue('p') =~ /^fws_/) ) { $showMePlease =1 }

	#
	# move though the data records creating the individual hashes
	#
        while (@{$recordData}) {
                my %dataHash;

                my $keywordScore                = shift(@{$recordData});
                my $pageIdOfElement             = shift(@{$recordData});

                my $extraValue                  = shift(@{$recordData});

                $dataHash{'guid'}               = shift(@{$recordData});
                $dataHash{'createdDate'}        = shift(@{$recordData});
                $dataHash{'lang'}               = shift(@{$recordData});
                $dataHash{'guid_xref_site_guid'}= shift(@{$recordData});
                $dataHash{'site_guid'}          = shift(@{$recordData});
                $dataHash{'active'}             = shift(@{$recordData});
                $dataHash{'pageFriendlyURL'}    = shift(@{$recordData});
                $dataHash{'title'}              = shift(@{$recordData});
                $dataHash{'disableTitle'}       = shift(@{$recordData});
                $dataHash{'defaultElement'}     = shift(@{$recordData});
                $dataHash{'disableEditMode'}    = shift(@{$recordData});
                $dataHash{'type'}               = shift(@{$recordData});
                $dataHash{'navigationName'}     = shift(@{$recordData});
                $dataHash{'name'}               = shift(@{$recordData});
                $dataHash{'parent'}             = shift(@{$recordData});
                $dataHash{'layout'}             = shift(@{$recordData});

                if ($dataHash{'active'} || ($showMePlease && $dataHash{'site_guid'} eq $paramHash{'siteGUID'}) || ($paramHash{'siteGUID'} ne $dataHash{'site_guid'} && $dataHash{'active'})) {

                        #
                        # twist our legacy statements around.  titleOrig isn't legacy - but I don't
                        # know why its here either.  We will attempt to deprecate it on the next version
                        #
                        $dataHash{'element_type'}               = $dataHash{'type'};
                        $dataHash{'titleOrig'}                  = $dataHash{'title'};

                        #
                        # if the title is blank lets dump the name into it
                        #
                        if ($dataHash{'title'} eq '') { $dataHash{'title'} =  $dataHash{'name'} }

                        #
                        # add the extended fields and create the hash
                        #
                        %dataHash = $self->addExtraHash($extraValue,%dataHash);

                        #
                        # overwriting these, just in case someone tried to save them in the extended hash
                        #
                        $dataHash{'keywordScore'}       = $keywordScore;
                        $dataHash{'pageIdOfElement'}    = $pageIdOfElement;

                        #
                        # push the hash into the array
                        #
                        push(@hashArray,{%dataHash});
                }
        }

	#
	# return the reference or the array
	#
        if ($paramHash{'ref'} eq '1') { return \@hashArray } else {return @hashArray }
}

=head2 dataHash

Retrieve a hash or hash reference for a data matching the passed guid.  This can only be used after setSiteValues() because it required $fws->{'siteGUID'} to be defined.

	#
	# get the hash itself
	#
        my %dataHash 	= $fws->dataHash(guid=>'someguidsomeguidsomeguid');
       
	#
	# get a reference to the hash
	# 
	my $dataHashRef = $fws->dataHash(guid=>'someguidsomeguidsomeguid',ref=>1);

=cut

sub dataHash {
        my ($self,%paramHash) = @_;
        
	#
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }


        my $recordData =  $self->runSQL(SQL=>"select data.extra_value,data.element_type,'lang',lang,'guid',data.guid,'pageFriendlyURL',friendly_url,'defaultElement',data.default_element,'guid_xref_site_guid',data.site_guid,'showLogin',data.show_login,'showResubscribe',data.show_resubscribe,'groupId',data.groups_guid,'disableEditMode',data.disable_edit_mode,'site_guid',data.site_guid,'title',data.title,'disableTitle',data.disable_title,'active',data.active,'navigationName',nav_name,'name',data.name from data left join site on site.guid=data.site_guid where data.guid='".$self->safeSQL($paramHash{'guid'})."' and (data.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' or site.sid='fws')");

        #
        # pull off the first two fields because we need to manipulate them
        #
        my $extraValue  = shift(@$recordData);
        my $dataType    = shift(@$recordData);

        #
        # convert it to a hash
        #
        my %dataHash                    = @$recordData;

        #
        # do some legacy data type switching around.  some call it type (wich it should be, and some call it element_type
        #
        $dataHash{"type"}               = $dataType;
        $dataHash{"element_type"}       = $dataType;

        #
        # combine the hash
        #
        %dataHash                       = $self->addExtraHash($extraValue,%dataHash);

        #
        # Overwrite the title with the name if it is blank
        #
        if ($dataHash{'title'} eq '') { $dataHash{'title'} =  $dataHash{'name'} }

        #
        # return the hash or hash reference
        #
        if ($paramHash{'ref'} eq '1') { return \%dataHash } else {return %dataHash }
}

=head2 deleteData

Delete something from the data table.   %dataHash must contain guid and either containerId or parent. By passing noOrphanDelete with a value of 1, any data ophaned from the act of this delete will also be deleted.

	my %dataHash;
	$dataHash{'noOrphanDelete'}	= '0';
	$dataHash{'guid'}		= 'someguid123123123';
	$dataHash{'parent'}		= 'someparentguid';
        my %dataHash $fws->deleteData(%dataHash);

=cut

sub deleteData {
        my ($self, %paramHash) = @_;
        %paramHash = $self->runScript('preDeleteData',%paramHash);

        #
        # get the sid if one wasn't passed
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {
                ($paramHash{'parent'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' LIMIT 1")};
        }

        #
        # Kill the xref
        #
        $self->_deleteXRef($paramHash{'guid'},$paramHash{'parent'},$paramHash{'siteGUID'});

        #
        # Kill any data recrods now orphaned from this process
        #
	$self->_deleteOrphanedData("guid_xref","child","data","guid");
	
	#
	# if we are cleaning orphans continue
	#	
	if ($paramHash{'noOrphanDelete'} ne '1') {
	        #
	        # loop though till we don't see anything dissapear
	        #
	        my $keepGoing = 1;
	
	        while ($keepGoing) {
			#
			# set up the tests
			#
	                my ($firstTest)         = @{$self->runSQL(SQL=>"select count(1) from guid_xref")};
	                my ($firstTestData)     = @{$self->runSQL(SQL=>"select count(1) from data")};

	                #
	                # get rid of any parent that no longer has a perent
	                #
	                $self->_deleteOrphanedData('guid_xref','parent','data','guid',' and guid_xref.parent <> \'\'');
	
	                #
	                # get rid of any data records that are now orphaned from the above process's
	                #
	                $self->_deleteOrphanedData("data","guid","guid_xref","child");
	
			#
			# if we are not deleting orphans do the checks
			#
			if ($paramHash{'noOrphanDelete'} ne '1') {
	
	                        #
	                        # grab a second test to match against
	                        #
	                        my ($secondTest)        = @{$self->runSQL(SQL=>"select count(1) from guid_xref")};
	                        my ($secondTestData)    = @{$self->runSQL(SQL=>"select count(1) from data")};
	
	                        #
	                        # now that we have a first and second pass.  if they have changed keep going, but if nothing happened
	                        # lets ditch out of here
	                        #
	                        if ($secondTest eq $firstTest && $secondTestData eq $firstTestData) { $keepGoing = 0 } else { $keepGoing = 1 }
	                }
	        }
        	#
	        # Kill any data recrods now orphaned from the cleansing
	        #
		$self->_deleteOrphanedData("guid_xref","child","data","guid");
	}

	#
	# run any post scripts and return what we were passed
	#
        %paramHash = $self->runScript('postDeleteData',%paramHash);
        return %paramHash;
}

=head2 flushSearchCache

Delete all cached data and rebuild it from scratch.  Will return the number of records it optimized.  If no siteGUID was passed then the one from the current site being rendered is used

        print $fws->flushSearchCache($fws->{'siteGUID'});

=cut

sub flushSearchCache {
        my ($self,$siteGUID) = @_;

	#
	# set the site guid if it wasn't passed
	#
        if ($siteGUID eq '') { $siteGUID = $self->{'siteGUID'} }

        #
        # before we do anything lets get the cache fields reset
        #
        $self->setCacheIndex();

        #
        # drop the current data
        #
        $self->runSQL(SQL=>"delete from data_cache where site_guid='".$self->safeSQL($siteGUID)."'");

        #
        # have a counter so we can see how much work we did
        #
        my $dataUnits = 0;

        #
        # get a list of the current data, and update the cache for each one
        #
        my $dataArray = $self->runSQL(SQL=>"select guid from data where site_guid='".$self->safeSQL($siteGUID)."'");
        while (@$dataArray) {
                my $guid = shift(@$dataArray);
                $self->updateDataCache($self->dataHash(guid=>$guid));
                $dataUnits++;
        }
        return $dataUnits;
}

=head2 fwsGUID

Retrieve the GUID for the fws site. If it does not yet exist, make a new one.

        print $fws->fwsGUID();

=cut

sub fwsGUID {
        my ($self) = @_;

        #
        # if is not set, set it and create the site id
        #
        if ($self->siteValue('fwsGUID') eq '') {

                #
                # get the sid for the fws site
                #
                my ($fwsGUID) = $self->getSiteGUID('fws');

                #
                # if its blank make a new one
                #
                if ($fwsGUID eq '') {
                        $fwsGUID = $self->createGUID('f');
                        my ($adminGUID) = $self->getSiteGUID('admin');
                        $self->runSQL(SQL=>"insert into site set sid='fws',guid='".$fwsGUID."',site_guid='".$self->safeSQL($adminGUID)."'");
                }

                #
                # add it as a siteValue and return the result
                #
                $self->siteValue('fwsGUID',$fwsGUID) ;
                return $fwsGUID;
        }

        #
        # I already know it, just return the result
        #
        else { return $self->siteValue('fwsGUID') }
}


=head2 getSiteGUID

Get the site GUID for a site by passing the SID of that site.  If the SID does not exist it will return an empty string.

        print $fws->getSiteGUID('somesite');

=cut

sub getSiteGUID {
        my ($self,$sid) = @_;
        #
        # get the ID to the sid for site ids these always match the corrisponding sid
        #
        my ($guid) = @{$self->runSQL(SQL=>"select guid from site where sid='".$self->safeSQL($sid)."'")};
        return $guid;
}

=head2 getPageGUID

Get the GUID for a site by passing a guid of an item on a page.  If the guid is referenced in more than one place, the page it will be passed could be random.

        my $pageGUID =  $fws->getPageGUID($valueHash{'elementId'},10);

Note: This procedure is very database extensive and should be used lightly.  The default depth to look before giving up is 5, the example above shows searching for 10 depth before giving up. 

=cut

sub getPageGUID {
        my ($self,$guid,$depth) = @_;

	#
	# set the depth to how far you will look before giving up
	#
	if ($depth eq '') { $depth = 10 }

	#
	# set the cap counter
	#
        my $recurCap = 0;

        #
        # get the inital type
        #
        my $recId = -1;
        my ($type) = @{$self->runSQL(SQL=>"select element_type from data where guid='".$self->safeSQL($guid)."'")};

        #
        # recursivly head down till you get "page" or "" as refrence.
        #
        while ($type ne 'page' && $type ne 'home' && $guid ne '') {
                my @idsAndTypes = @{$self->runSQL(SQL=>"select parent,element_type from guid_xref left join data on data.guid=parent where child='".$self->safeSQL($guid)."'")};
                while (@idsAndTypes) {
                        $guid           = shift(@idsAndTypes);
                        my $listType    = shift(@idsAndTypes);
                        if ($listType eq 'page') {
                                $recId = $guid;
                                $type = 'page';
                        }
                }

                #
                # give up after 5 
                #
                if ($recurCap > 5) { $type = 'page'; $recId =  -1 }
                $recurCap++;
        }
        return $recId;
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
        my @data = ();
        my $errorResponse;

        #
        # send this off to the log
        #
        $self->SQLLog($paramHash{'SQL'});

        #
        # prepare the SQL and loop though the arrays
        #

        my $sth = $self->{'_DBH'}->prepare($paramHash{'SQL'});
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
                my $clean;

                #
                # SQL lite gathing and normilization
                #
                if ($self->{'DBType'} =~ /^SQLite$/i) {
                        while (my @row = $sth->fetchrow) {
                		my @cleanRow;
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
                        while (my @row = $sth->fetchrow) {
                		my @cleanRow;
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
		$self->FWSLog('SQL ERROR: '.$paramHash{'SQL'});

		#
		# run update DB on an error to fix anything that was broke
		#
		$self->FWSLog('UPDATED DB: '.$self->updateDatabase());
		}

        #
        # return this back as a normal array
        #
        return \@data;
}




=head2 saveData

Update or create a new data record.  If guid is not provided then a new record will be created.   If you pass "newGUID" as a parameter for a new record, the new guid will not be auto generated, newGUID will be used.

        %dataHash = $fws->saveData(%dataHash);

Required hash keys if the data is new:

=over 4

=item * parent: This is the reference to where the data belongs

=item * name: This is the reference id for the record

=item * type: A valid element type

=back

Not required hash keys:

=over 4

=item * $active: 0 or 1. Default is 0 if not specified

=item * newGUID: If this is a new record, use this guid (Note: There is no internal checking to make sure this is unique)

=item * lang: Two letter language definition. (Not needed for most multi-lingual sites, only if the code has a requirement that it is splitting language based on other criteria in the control)

=item * ... Any other extended data fields you want to save with the data element

=back


Example of adding a data record

	my %paramHash;
	$paramHash{'parent'} 		= $fws->formValue('guid');
	$paramHash{'active'} 		= 1;
	$paramHash{'name'}   		= $fws->formValue('name');
	$paramHash{'title'}  		= $fws->formValue('title');
	$paramHash{'type'}   		= 'site_myElement';
	$paramHash{'color'}  		= 'red';

	%paramHash = $fws->saveData(%paramHash);

Example of adding the same data record to a "data container"

	my %paramHash;
	$paramHash{'containerId'} 	= 'thisReference';
	$paramHash{'active'}		= 1;
	$paramHash{'name'}   		= $fws->formValue('name');
	$paramHash{'type'}   		= 'site_thisType';
	$paramHash{'title'}  		= $fws->formValue('title');
	$paramHash{'color'}  		= 'red';

	%paramHash = $fws->saveData(%paramHash);

Note: If the containerId does not match or exist, then one will be created in the root of your site, and the data will be added to the new one.

Example of updating a data record:

	$guid = 'someGUIDaaaaabbbbccccc';
 
	#
	# get the original hash
	#
	my %dataHash = $fws->dataHash(guid=>$guid);
 
	#
	# make some changes
	#
	$dataHash{'name'} 	= "New Reference Name";
	$dataHash{'color'} 	= "blue";
 
	#
	# Give the altered hash to the update procedure
	# 
	$fws->saveData(%dataHash);

=cut


sub saveData {
        my ($self, %paramHash) = @_;

        #
        # if site_guid is blank, lets set it to the site we are looking at
        #
        if ($paramHash{'site_guid'} eq '') { $paramHash{'site_guid'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {
                #
                # if we don't have a container for it already, lets make one!
                #
                ($paramHash{'parent'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' LIMIT 1")};
                if ($paramHash{'parent'} eq '') {

                        #
                        # recursive!!!! but because containerId isn't passed we are good :)
                        #
                        my %parentHash = $self->saveData(name=>$paramHash{'containerId'},type=>'data',parent=>$self->{'homeGUID'},layout=>'0');

                        #
                        # set the =parent to the new guid
                        #
                        $paramHash{'parent'} = $parentHash{'guid'};
                }

                #
                # get rid of the containerId, and lets continue with a normal update
                #
                delete($paramHash{'containerId'});
        }

        #
        # check to see if its already used;
        #
        my %usedHash = $self->dataHash(guid=>$paramHash{'guid'});

        #
        # Lets check the "new guid" if there is one, if it matches, this is an update also
        #
        if ($usedHash{'guid'} eq '' && $paramHash{'newGUID'} ne '') {
                %usedHash = $self->dataHash(guid=>$paramHash{'newGUID'});
                if ($usedHash{'guid'} ne '') {$paramHash{'guid'} = $paramHash{'newGUID'} }
        }

        #
        # if there is no ID this is an add, else, its really just an updateData
        #
        if ($usedHash{'guid'} eq '') {
                #
                # set the active to false if its not specified
                #
                if ($paramHash{'active'} eq '') { $paramHash{'active'} = '0' }

                #
                # get the intial ID and insert the record
                #
                if ($paramHash{'newGUID'} ne '') {$paramHash{'guid'} = $paramHash{'newGUID'} }
                elsif ($paramHash{'guid'} eq '') {$paramHash{'guid'} = $self->createGUID('d')}

                #
                # if title is blank make it the name;
                #
                if ($paramHash{'title'} eq '') {$paramHash{'title'} = $paramHash{'name'} }


                #
                # insert the record
                #
                $self->runSQL(SQL=>"insert into data (guid,site_guid,created_date) values ('".$self->safeSQL($paramHash{'guid'})."','".$self->safeSQL($paramHash{'site_guid'})."','".$self->dateTime(format=>"SQL")."')");
        }

        #
        # get the next in the org, so it will be at the end of the list
        #
        if ($paramHash{'ord'} eq '') { ($paramHash{'ord'}) = @{$self->runSQL(SQL=>"select max(ord)+1 from guid_xref where site_guid='".$self->safeSQL($paramHash{'site_guid'})."' and parent='".$self->safeSQL($paramHash{'parent'})."'")}}

        #
        # if we are talking a type of page or home, set layout to 0 because it should not be used
        #
        if ($paramHash{'type'} eq 'page' || $paramHash{'type'} eq 'home') { $paramHash{'layout'} = '0' }

        #
        # if layout is ever blank, set it to main as a default
        #
        if ($paramHash{'layout'} eq '') { $paramHash{'layout'} = 'main' }

        #
        # add the xref record if it needs to... BUT!  only pages are aloud to have blank parents, everything else needs a parent
        #
	if ($paramHash{'type'} eq 'home' || $paramHash{'parent'} ne '') {
	        $self->_saveXRef($paramHash{'guid'},$paramHash{'layout'},$paramHash{'ord'},$paramHash{'parent'},$paramHash{'site_guid'});
	}

	#
	# if we are talking about a home page, then we actually need to set this as "page"
	#
	if ($paramHash{'type'} eq 'home') { $paramHash{'type'} ='page' }
	
        #
        # now before we added something new we might need a new index, lets reset it for good measure
        #
        $self->setCacheIndex();

        #
        # Save the data minus the extra fields
        #
        $self->runSQL(SQL=>"update data set extra_value='',show_login='".$self->safeSQL($paramHash{'showLogin'})."',default_element='".$self->safeSQL($paramHash{'default_element'})."',disable_title='".$self->safeSQL($paramHash{'disableTitle'})."',disable_edit_mode='".$self->safeSQL($paramHash{'disableEditMode'})."',disable_title='".$self->safeSQL($paramHash{'disableTitle'})."',lang='".$self->safeSQL($paramHash{'lang'})."',friendly_url='".$self->safeSQL($paramHash{'pageFriendlyURL'})."', active='".$self->safeSQL($paramHash{'active'})."',nav_name='".$self->safeSQL($paramHash{'navigationName'})."',name='".$self->safeSQL($paramHash{'name'})."',title='".$self->safeSQL($paramHash{'title'})."',element_type='".$self->safeSQL($paramHash{'type'})."' where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'site_guid'})."'");

        #
        # loop though and update every one that is diffrent
        #
        for my $key ( keys %paramHash ) {
                if ($key !~ /^(ord|pageIdOfElement|keywordScore|navigationName|showResubscribe|guid_xref_site_guid|groupId|lang|pageFriendlyURL|type|guid|siteGUID|newGUID|name|element_type|active|title|disableTitle|disableEditMode|defaultElement|showLogin|parent|layout|site_guid)$/) {
                        $self->saveExtra(table=>'data',siteGUID=>$paramHash{'site_guid'},guid=>$paramHash{'guid'},field=>$key,value=>$paramHash{$key});
                }
        }

        #
        # update the modified stamp
        #
        $self->updateModifiedDate(%paramHash);

        #
        # update the cache data directly
        #
        $self->updateDataCache(%paramHash);

        #
        # return anything created in the paramHash that was changed and already present
        #
        return %paramHash;
}



=head2 saveExtra

Save data that is part of the extra hash for a FWS table.

        $self->saveExtra(	table		=>'table_name',
				siteGUID	=>'site_guid_not_required',
				guid		=>'some_guid',
				field		=>'table_field','the value we are setting it to');

=cut

sub saveExtra {
        my ($self,%paramHash) = @_;

        #
        # make sure we are on a compatable table
        #
        if ($paramHash{'table'} eq "data" || $paramHash{'table'} eq "directory" || $paramHash{'table'} eq "collection" || 
		$paramHash{'table'} eq "profile" || $paramHash{'table'} eq "cart" ||  $paramHash{'table'} eq "topic" ||
                ($paramHash{'table'} eq "admin_user" && $self->userValue('isAdmin') eq '1') ||
                $paramHash{'table'} eq "trans" || $paramHash{'table'} eq "trans_item" || $paramHash{'table'} eq "coupon" || $paramHash{'table'} eq "site") {

                #
                # set up the site_sid restriction... but user type tables don't use
                #
                my $addToWhere = " and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'";
                if ($paramHash{'table'} eq 'admin_user' || $paramHash{'table'} eq "directory" || $paramHash{'table'} eq 'site' ||
			$paramHash{'table'} eq 'profile' || $paramHash{'table'} eq 'trans' || $paramHash{'table'} eq 'trans_item' || 
			$paramHash{'table'} eq 'collection' ) { $addToWhere = '' }

                #
                # get the hash from the id we are pulling from
                #
                my ($extraValue) = @{$self->runSQL(SQL=>"select extra_value from ".$self->safeSQL($paramHash{'table'})." where guid='".$self->safeSQL($paramHash{'guid'})."'".$addToWhere)};

                #
                # decrypt if we are the trans table
                #
                if ($paramHash{'table'} eq 'trans') { $extraValue = $self->FWSDecrypt($extraValue)}

                #
                # pull the hash out
                #
                use Storable qw(nfreeze thaw);
                my %extraHash;
                if ($extraValue ne '') { %extraHash = %{thaw($extraValue)} }

                #
                # add the new one
                #
                $extraHash{$paramHash{'field'}} = $paramHash{'value'};

                #
                # convert back to a hash string
                #
                my $hash = nfreeze(\%extraHash);

                #
                # encrypt if we are the trans table
                #
                if ($paramHash{'table'} eq 'trans') { $hash = $self->FWSEncrypt($hash)}

                #
                # update the hash in the db
                #
                $self->runSQL(SQL=>"update ".$self->safeSQL($paramHash{'table'})." set extra_value='".$self->safeSQL($hash)."' where guid='".$self->safeSQL($paramHash{'guid'})."'".$addToWhere);

                #
                # update the cache table if we are on the data table
                #
                if ($paramHash{'table'} eq 'data') {

                        #
                        # pull the data has, update it, then send it to the cache
                        #
                        $self->updateDataCache($self->dataHash(guid=>$paramHash{'guid'}));
                }
        }
}



=head2 schemaHash

Return the schema hash for an element.  You can pass either the guid or the element type.

        my %dataSchema = $fws->schemaHash('someGUIDorType');

=cut

sub schemaHash {
        my ($self,$guid) = @_;

        #
        # maek sure dataSchema is defined before we run the code
        #
        my %dataSchema;

        #
        # get the schemaHash
        #
        my ($schemaCode) = @{$self->runSQL(SQL=>"select schema_devel from element where guid='".$self->safeSQL($guid)."' or type='".$self->safeSQL($guid)."'")};

        #
        # copy the self object to fws
        #
        my $fws = $self;

        #
        # run the eval and populate the hash (Including the title)
        #
        eval $schemaCode;
        my $errorCode = $@;
        if ($errorCode) { $self->FWSLog('SCHEMA ERROR: '.$guid.' - '.$errorCode) }

        #
        # now put it back
        #
        $self = $fws;

        return %dataSchema;
        }


=head2 setCacheIndex

Set a sites cache index for its site.  you can bas a siteGUID as a hash parameter if you wish to update the index for a site not currently being rendered.

        $fws->setCacheIndex();

=cut

sub setCacheIndex {
        my ($self,%paramHash) = @_;
        
	#
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # get a list of the elements for the sid
        #
        my (@usedElements) = @{$self->runSQL(SQL=>"select distinct element_type from data where site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};

        my @indexArray;

        while (@usedElements) {

                #
                # get the schema for the element
                #
                my %schemaHash = $self->schemaHash(shift(@usedElements));

                #
                #  loop though each one and if the index is set to one, add it to the index list
                #
                for my $key ( keys %schemaHash) {
                        if ($schemaHash{$key}{index} eq '1') { push (@indexArray,$key) }
                }
        }

        #
        # create a comma delemited list that is the inexed fields
        #
        my $cacheValue = join(',',@indexArray);

        #
        # update the extra table of what the cacheIndex is
        #
        $self->saveExtra(table=>'site',guid=>$paramHash{'siteGUID'},field=>'dataCacheIndex',$cacheValue);
        }

=head2 tableFieldHash

Return a multi-dimensional hash of all the fields in a table with its properties.  This usually isn't used by anything but internal table alteration methods, but it could be useful if you are making conditionals to determine the data structure before adding or changing data.  The method is CPU intensive so it should only be used when performance is not a requirement.

        $tableFieldHashRef = $fws->tableFieldHash('the_table');

The return dump will have the following structure:

        $tableFieldHashRef->{field}{type}
        $tableFieldHashRef->{field}{ord}
        $tableFieldHashRef->{field}{null}
        $tableFieldHashRef->{field}{default}
        $tableFieldHashRef->{field}{extra}
        
If the field is indexed it will return a unique table field combination key equal to MUL or FULLTEXT:
	
	$tableFieldHashRef->{thetable_field}{key} 

=cut

sub tableFieldHash {
        my ($self,$table) = @_;

        #
        # set an order counter so we can sort by this if needed
        #
        my $fieldOrd = 0;

        #
        # if we have a cached version lets make one
        #
        if (!keys %{$self->{'_'.$table.'FieldCache'}}) {

                #
                # grab the table def hash for mysql
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        my $tableData = $self->runSQL(SQL=>"desc ".$self->safeSQL($table));
                        while (@$tableData) {
                                $fieldOrd++;
                                my $fieldInc  			                                  = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'type'}              = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'ord'}               = $fieldOrd;
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'null'}              = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$table."_".$fieldInc}{'key'}    = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'default'}           = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'extra'}             = shift(@$tableData);
                        }
                }

                #
                # grab the table def hash for sqlite
                #
                if ($self->{'DBType'} =~ /^sqlite$/i) {
                        my $tableData = $self->runSQL(SQL=>"PRAGMA table_info(".$self->safeSQL($table).")");
                        while (@$tableData) {
                                $fieldOrd++;
        		                                                                shift(@$tableData);
                                my $fieldInc =  		                        shift(@$tableData);
                       		                                	                shift(@$tableData);
                               		                                	        shift(@$tableData);
                                       		                                	shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'type'} =  shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'ord'}  = $fieldOrd;
                        }

                        $tableData = $self->runSQL(SQL=>"PRAGMA index_list(".$self->safeSQL($table).")");
                        while (@$tableData) {
                                                        				shift(@$tableData);
                                my $fieldInc =          				shift(@$tableData);
                                                        				shift(@$tableData);

                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{"key"} = 	"MUL";
                        }
                }
        }
	return %{$self->{'_'.$table.'FieldCache'}};

}



=head2 updateDataCache

Update the cache version of the data record.  This is called automatically when saveData is called.

        $fws->updateDataCache(%theDataHash);

=cut


sub updateDataCache {
        my ($self,%dataHash) = @_;

        #
        # get the field hash so we don't have to try to add fields that might not be there EVERY time
        #
        my %tableFieldHash = $self->tableFieldHash("data_cache");

        #
        # set the page id of the guid for easy access on search pages
        #
        $dataHash{'pageIdOfElement'} = $self->getPageGUID($dataHash{'guid'});

        #
        # get the page hash of the page, and update the page description to the data for easy access on search pages
        #
        my %pageHash = $self->dataHash(guid=>$dataHash{'pageIdOfElement'});
        $dataHash{'pageDescription'} = $pageHash{'pageDescription'};

        #
        # get what fields we are aloud to use
        #
        my %dataCacheFields = %{$self->{"dataCacheFields"}};

        #
        # we will be building these up while we loop
        #
        my $fields = '';
        my $values = '';

        #
        # make any fields that "might" be needed
        #
        foreach my $key ( keys %dataHash ) {
                if ($dataCacheFields{$key} eq '1' || $key eq 'site_guid' || $key eq 'guid' || $key eq 'name' || $key eq 'title' || $key eq 'pageIdOfElement' || $key eq 'pageDescription') {

                        #
                        # if the type is blank, then this is new
                        #
                        if ($tableFieldHash{$key}{'type'} eq '') {
                                #
                                # alter tha table
                                #
                                $self->alterTable(table=>"data_cache",field=>$key,type=>"text",key=>"FULLTEXT",default=>"");
                        }



                        #
                        # append the new data to the strings we are using to create the insert statement
                        #
                        $fields .= $self->safeSQL($key).',';
                        $values .= "'".$self->safeSQL($dataHash{$key})."',";
		}
        }

        #
        # clean up the commas at the end of values and fields
        #
        $fields =~ s/,$//sg;
        $values =~ s/,$//sg;

        #
        # remove the one that "might" be there
        #
        $self->runSQL(SQL=>"delete from data_cache where guid='".$self->safeSQL($dataHash{'guid'})."'");

        #
        # add the the new one
        #
        $self->runSQL(SQL=>"insert into data_cache (".$fields.") values (".$values.")");
}


=head2 updateDatabase

Alter the database to match the schema for FWS 2.   The return will print the SQL statements used to adjust the tables.

	print $fws->updateDatabase()."\n";

This method is automatically called when on the web optimized version of FWS when rendering the 'System' screen.

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
                "element","script_devel"                ,$self->{'scriptTextSize'},""   ,"",
                "element","script_live"                 ,$self->{'scriptTextSize'},""   ,"",
                "element","schema_devel"                ,'text',	""   		,"",
                "element","schema_live"                 ,'text',	""   		,"",

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
        # loop though the records and make or update the tables
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


=head2 updateModifiedDate

Update the modified date of the page a dataHash element resides on.

        $fws->updateModifiedDate(%dataHash);

Note: By updating anything that is persistant against multiple pages all pages will have thier date updated as it is considered a site wide change.

=cut

sub updateModifiedDate {
        my ($self,%paramHash) = @_;

        #
        # it is default or not
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # set the type to page if the id itself is a page
        #
        my ($type) = @{$self->runSQL(SQL=>"select element_type from data where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};

        #
        # if its not page loop though till it finds what page its on
        #
        my $isDefault = 0;
        my $recurCap = 0;
        while ($paramHash{'guid'} ne '' && ($type ne 'page' || $type ne 'home') && $recurCap < 100) {
                my ($defaultElement) = @{$self->runSQL(SQL=>"select default_element from data where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};
                ($paramHash{'guid'},$type) = @{$self->runSQL(SQL=>"select parent,data.element_type from guid_xref left join data on data.guid=parent where child='".$self->safeSQL($paramHash{'guid'})."' and guid_xref.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};
                if (!$isDefault && $defaultElement) { $isDefault = 1 }
                $recurCap++;
        }

        #
        # if id is blank that means we are updating a home page element
        #
        if ($type eq '' || $isDefault > 0 || $isDefault < 0) {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},field=>'dateUpdated',value=>time);
        }

        #
        # if is default then update ALL pages
        #
        if ($isDefault) {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},field=>'dateUpdated',value=>time);
                my @pageList = @{$self->runSQL(SQL=>"select guid from data where data.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' and (data.element_type='page' or data.element_type='home')")};
                while (@pageList) {
                        my $pageId = shift(@pageList);
                        $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$pageId,field=>'dateUpdated',value=>time);
                }
        }

        #
        # if the type is page, then just update that page
        #
        if ($type eq 'page' || $type eq 'home') {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$paramHash{'guid'},field=>'dateUpdated',value=>time);
        }
}


############################################################################################
# DATA: Delete a orphened data
############################################################################################

sub _deleteOrphanedData {
        my ($self,$table,$field,$refTable,$refField,$extraWhere) = @_;

        #
        # get the vars set for pre-processing
        #
        my $keepDeleting = 1;

        #
        # keep looping till either we are endless or
        #
        while ($keepDeleting) {

		#
		# create the SQL that will be used for the delete and the reflective query
		#
                my $fromSQL = "from ".$table." where ".$table.".".$field." in (select ".$field." from (select distinct ".$table.".".$field." from ".$table." left join ".$refTable." on ".$refTable.".".$refField." = ".$table.".".$field." where ".$refTable.".".$refField." is null ".$extraWhere.") as delete_list)";

		#
		# do the actual delete
		#
                $self->runSQL(SQL=>"delete ".$fromSQL);

		#
		# if we are talking about the data field, lets do the same thing to the data cache table
		#
                if ($table eq 'data') {
                        $self->runSQL(SQL=>"delete from ".$table."_cache where ".$table."_cache.".$field." in (select ".$field." from (select distinct ".$table."_cache.".$field." from ".$table."_cache left join ".$refTable." on ".$refTable.".".$refField." = ".$table."_cache.".$field." where ".$refTable.".".$refField." is null ".$extraWhere.") as delete_list)");
                }

		#
		# run the same fromSQL and see if anything is left
		#
                ($keepDeleting) = @{$self->runSQL(SQL=>"select 1 ".$fromSQL)};
        }
}

############################################################################################
# DATA: Delete a guid XRef
############################################################################################

sub _deleteXRef {
        my ($self,$child,$parent,$site_guid) = @_;
        $self->runSQL(SQL=>"delete from guid_xref where child='".$self->safeSQL($child)."' and parent='".$self->safeSQL($parent)."' and site_guid='".$self->safeSQL($site_guid)."'");
}

############################################################################################
# DATA: Lookup all the elements and return the hash
############################################################################################

sub _fullElementHash {
        my ($self,%paramHash) = @_;

        if (!keys %{$self->{'_fullElementHashCache'}}) {

                #
                # set the site guid depending on the context
                #
                my $site_guid = $self->{'siteGUID'};

                #
                # if your in an admin page, you will need this so you can see the stuff in scope for the tree views
                # it doesn't matter if it caches it, because these are ajax calls limited only to themselves
                #
                my $addToWhere = "(site_guid=\"".$self->safeSQL($self->fwsGUID())."\" and public=\"1\") or ";
                if ($self->formValue('site_guid') ne "") { $addToWhere = ""; $site_guid = $self->formValue("site_guid") }


                #
                # get the elementArray
                #
                my $elementArray = $self->runSQL(SQL=>"select guid,type,class_prefix,css_devel,css_live,js_devel,js_live,schema_devel,title,tags,parent,ord,site_guid,root_element,public,script_live,script_devel,checkedout from element where ".$addToWhere." site_guid='".$self->safeSQL($site_guid)."' order by title");
                my $alphaOrd = 0;
                while (@$elementArray) {
                        $alphaOrd++;
                        my $guid                                                        = shift(@$elementArray);
                        my $type                                                        = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'alphaOrd'}           = $alphaOrd;
                        $self->{'_fullElementHashCache'}->{$guid}{'class_prefix'}       = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'css_devel'}          = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'css_live'}           = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'js_devel'}           = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'js_live'}            = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'data_schema'}        = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'type'}               = $type;
                        $self->{'_fullElementHashCache'}->{$guid}{'title'}              = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'tags'}               = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'parent'}             = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'ord'}                = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'site_guid'}          = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'root_element'}       = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'public'}             = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'script_live'}                = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'script_devel'}       = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'checkedout'}         = shift(@$elementArray);



                        if ($type ne '') {
                                $self->{'_fullElementHashCache'}->{$type}{'guid'}       = $guid;
                                $self->{'_fullElementHashCache'}->{$type}{'parent'}     = $self->{'_fullElementHashCache'}->{$guid}{'parent'};
                        }
                }
        }
        return %{$self->{'_fullElementHashCache'}};
}


############################################################################################
# FORMAT: Pass keywords and field list, and create a wellformed where statement for keyword
#         searches
############################################################################################

sub _getKeywordSQL {
        my ($self,$keywords,@likeFields) = @_;
        #
        # Grab everything that is in quotes
        #
        my @exactMatches = ();
        while ($keywords =~ /"/) {
                $keywords =~ /(".*?")/g;
                my $currentMatch = $1;
                $keywords =~ s/$currentMatch//g;
                $currentMatch =~ s/"//g;
                push (@exactMatches,$currentMatch);
        }

        #
        # split them up and add the exact matches
        #
        my @keywordsSplit = split(' ',$keywords);
        push (@keywordsSplit,@exactMatches);


        #
        # build the SQL
        #
        my $keywordSQL ='';
        foreach my $keyword (@keywordsSplit) {
                if ($keyword ne '') {
                        my $fieldSQL = '';
                        foreach my $likeField (@likeFields) {
                                $fieldSQL .= $self->safeSQL($likeField)." LIKE '%".
                                $self->safeSQL($keyword)."%' or ";
                                }
                        $fieldSQL =~ s/ or $//sg;
                        if ($fieldSQL ne '') {
                                $keywordSQL .= "( ".$fieldSQL." )";
                                $keywordSQL .= " and ";
                        }
                }
        }

        #
        # kILL THE last and and then wrap it in parans so it will fit will in sql statements
        #
        $keywordSQL =~ s/ and $//sg;
        return $keywordSQL;
}

############################################################################################
# DATA: Save a guid XRef
############################################################################################

sub _saveXRef {
        my ($self,$child,$layout,$ord,$parent,$site_guid) = @_;

	#
	# delete the old one if its there
	#
        $self->_deleteXRef($child,$parent,$site_guid);

	#
	# add the new one
	#
        $self->runSQL(SQL=>"insert into guid_xref (child,layout,ord,parent,site_guid) values ('".$self->safeSQL($child)."','".$self->safeSQL($layout)."','".$self->safeSQL($ord)."','".$self->safeSQL($parent)."','".$self->safeSQL($site_guid)."')");

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
