package FWS::V2::File;

use 5.006;
use strict;

=head1 NAME

FWS::V2::File - Framework Sites version 2 text and image file methods

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();
	
	#
        # retrieve a reference to an array of data we asked for
        #
        my $fileArrayRef = $fws->fileArray( directory   =>"/home/directory" );



=head1 DESCRIPTION

Framework Sites version 2 file writing, reading and manipulation methods.

=head1 METHODS

=head2 createSizedImages

Create all of the derived images from a file upload based on its schema definition

	my %dataHashToUpdate = $fws->dataHash(guid=>'someGUIDThatHasImagesToUpdate');
	$fws->createSizedImages(%dataHashToUpdate);

If the data hash might not be correct because it is actually stored in a different table you can pass the field name you wish to update

	$fws->createSizedImages(guid=>'someGUID',image_1=>'/someImage/image.jpg');

=cut

sub createSizedImages {
        my ($self,%paramHash) = @_;

        #
        # going to need the current hash plus its derived schema to figure out what we should be making
        #
        my %dataHash    = (%paramHash,$self->dataHash(guid=>$paramHash{'guid'}));
        my %schemaHash  = $self->schemaHash($dataHash{'type'});

        #
        # if siteGUID is blank, lets get the one of the site we are on
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # bust though all the fields and see if we need to do anything with them
        #
        for my $field ( keys %dataHash ) {

                #
                # for non secure files lets prune the 640,custom, and thumb fields
                #
                my $dataType = $schemaHash{$field}{fieldType};
                if ($dataType eq 'file' || $dataType eq 'secureFile') {
		

                        #
                        # get just the file name... we will use this a few times
                        #
                        my $fileName = $self->justFileName($dataHash{$field});

                        #
                        # set the file path based on secure or not
                        #
                        my $dirPath = $self->{'filePath'};
                        if ($dataType eq 'secureFile') { $dirPath = $self->{'fileSecurePath'} }

			#
                        # check for thumb creation... if so lets do it!
                        #
                        for my $fieldName ( keys %schemaHash ) {
                                if ($schemaHash{$fieldName}{'fieldParent'} eq $field && $schemaHash{$fieldName}{'fieldParent'} ne '' ){



                                        #
                                        # A directive to create a new image exists!  lets figure out where and how, and do it
                                        #
                                        my $directory           = $self->safeDir($dirPath.'/'.$paramHash{'siteGUID'}.'/'.$paramHash{'guid'});
                                        my $newDirectory        = $self->safeDir($dirPath.'/'.$paramHash{'siteGUID'}.'/'.$paramHash{'guid'}.'/'.$fieldName);
                                        my $newFile             = $newDirectory."/".$fileName;
                                        my $webFile             = $self->{'fileWebPath'}.'/'.$paramHash{'siteGUID'}.'/'.$paramHash{'guid'}.'/'.$fieldName.'/'.$fileName;


                                        #
                                        # make the image width 100, if its not specified
                                        #
                                        if ($schemaHash{$fieldName}{'imageWidth'} < 1) { $schemaHash{$fieldName}{'imageWidth'} = 100 }

                                        #
                                        # Make the subdir if its not already there
                                        #
                                        $self->makeDir($newDirectory ,0755);

                                        #
                                        # create the new image
                                        #
                                        $self->saveImage(sourceFile=>$directory.'/'.$fileName,fileName=>$newFile,width=>$schemaHash{$fieldName}{'imageWidth'});

                                        #
                                        # if its a secure file, we only save it from site guid on...
                                        #
                                        if ($dataType eq 'secureFile') { $webFile = '/'.$paramHash{'siteGUID'}.'/'.$paramHash{'guid'}.'/'.$fileName }

                                        #
                                        # if the new image is not there, then lets blank out the file
                                        #
                                        if (!-e $newFile) { $webFile = '' }
				
					if ($paramHash{'guid'} ne '') {
	                                        #
	                                        # save a blank one, or save a good one
	                                        #
	                                        $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$paramHash{'guid'},field=>$fieldName,value=>$webFile);
                                	}
                                }
                        }
                }
        }
}

=head2 fileArray

Return a directory listing into a FWS hash array reference.

        #
        # retrieve a reference to an array of data we asked for
        #
        my $fileArray = $fws->fileArray( directory   =>"/home/directory" );

        #
        # loop though the array printing the files we found
        #
        for my $i (0 .. $#$fileArray) {
                print $fileArray->[$i]{"file"}. "\n";
        }

=cut

sub fileArray {
        my ($self,%paramHash) =@_;

        #
        # ensure nothing scary is in the directory
        #
        $paramHash{'directory'} = $self->safeDir($paramHash{'directory'});

        #
        # pull the directory into an array
        #
        opendir(DIR, $paramHash{'directory'});
        my @getDir = grep(!/^\.\.?$/,readdir(DIR));
        closedir(DIR);

        my @fileHashArray;
        foreach my $dirFile (@getDir) {
                if (-f $paramHash{'directory'}.'/'.$dirFile) {

                        my %fileHash;
                        $fileHash{'file'}           = $dirFile;
                        $fileHash{'fullFile'}       = $paramHash{'directory'}.'/'.$dirFile;
                        $fileHash{'size'}           = (stat $fileHash{'fullFile'})[7];
                        $fileHash{'date'}           = (stat $fileHash{'fullFile'})[9];

                        #
                        # push it to the array
                        #
                        push (@fileHashArray,{%fileHash});
                }
        }
        return \@fileHashArray;
}

=head2 getEncodedBinary

Retrive a file and convert it into a base 64 encoded binary.

        #
        # Get the file
        #
        my $base64String = $fws->getEncodedBinary($someFileWeWantToConvert);

=cut

sub getEncodedBinary {
        my ($self,$fileName) = @_;

        #
        #convert file to base64
        #
        use MIME::Base64;
        my $rawFile;

        open (FILE, $fileName) or die "Can not open file:". $fileName;
        binmode FILE;
        while ( read (FILE, my $buffer, 1)) { $rawFile .= $buffer }
        close (FILE);

	my $rawfile =encode_base64($rawFile);
	return $rawfile;
}


=head2 packDirectory

MIME encode a directory ready for a FWS export.

        #
        # Get the file
        #
        my $packedFileString = $fws->packDirectory($someDirectory);

=cut

sub packDirectory {
        my ($self,$dir) = @_;
	
	#
	# this will need some MIME and file find action
	#
	use File::Find;
        use MIME::Base64;

	#
	# PH for the return
	#
	my $packFile;

        finddepth(sub {
                #
                # clean up the name so it will always be consistant
                #
                my $fullFileName = $File::Find::name;
                my $file = $fullFileName;
                my $dirPath = $self->{'filePath'};
                #my $dirSecurePath = $self->{'fileSecurePath'};
	
		#
		# set FILE or SECUREFILE as type
		#
		my $fileType = 'FILE';
		#if ($file =~ /^$dirSecurePath/) { $fileType = 'SECUREFILE' }

		#
		# get rid of either
		#
		$file =~ s/^$dirPath//sg;
		#$file =~ s/^$dirSecurePath//sg;

		#
		# move though the files
		#
                if (-f $fullFileName) {
                                #
                                # print the header of the file "FILE|fileName";
                                #
                                $packFile .= $fileType.'|'.$file."\n";

                                #
                                # get the file
                                #
                                my $rawFile;
                                open (FILE, $fullFileName) or die "Can not open file:". $!;
                                binmode FILE;
                                while ( read (FILE, my $buffer, 1)) { $rawFile .= $buffer }
                                close (FILE);

                                #
                                # encode it
                                #
                                $packFile .= encode_base64($rawFile);

                                #
                                # footer around the file
                                #
                                $packFile .= $fileType.'_END|'.$file."\n";
                                }
                }, $dir);
	return $packFile;
	}


=head2 saveEncodedBinary

Decode a base 64 encoded string and save it as its file.

        #
        # Save the file
        #
        $fws->saveEncodedBinary($someFileWeWantToSave,$theBase64EcodedString);

=cut

sub saveEncodedBinary {
        my ($self,$fileName,$rawFile)= @_;
        use MIME::Base64;
        #
        # take a base64 text string, and save it to filesystem
        #
        open (FILE, ">".$fileName);
        binmode FILE;
        $rawFile = decode_base64($rawFile);
        print FILE $rawFile;
        close (FILE);
}


=head2 getPluginVersion

Extract the version from a FWS plugin.  If no version is labeled or exists it will return 0.0000.

	#
	# The version line in FWS plugins will look like this:
	#
	# our $VERSION = '0.0001';
	#
        
	my $version = $fws->getPluginVersion($somePluginFile);

=cut

sub getPluginVersion {
	my ($self,$pluginFile) = @_;

	#
	# set the default
	#
	my $version = '0.0000';

	#
	# open the file and extract it
	#
	open (FILE, $self->safeDir($pluginFile));
        while (<FILE>) {
        	my $line = $_ ;
	        $line =~ /\$VERSION(\s*)=(\s*)'(.*?)'/;
    		my $verCheck = $3;
        	if ($verCheck ne '') { $version = $verCheck }
	}
	return $version
}



=head2 makeDir

Make a new directory with built in safety mechanics.   If the directory is not under the filePath or fileSecurePath then nothing will be created.

        $fws->makeDir( $self->{'filePath'}.'/thisNewDir' );

=cut

sub makeDir {
        my ($self,$directory) = @_;

        #
        # to make sure nothing fishiy is going on, you should only be making dirs under this area
        #
        my $filePath = $self->{'filePath'};
        my $fileSecurePath  = $self->{'fileSecurePath'};
        if ($directory =~ /^$filePath/ || $directory =~ /^$fileSecurePath/ ) {

                #
                # kill double ..'s so noobdy tries to leave our tight environment of security
                #
                $directory = $self->safeDir($directory);

                #
                # eat the leading / if it exists ... and it should (this is for the split
                #
                $directory =~ s/^\///sg;

                #
                # create an array we can loop though to rebuild it making them on the fly
                #
                my @directories = split(/\//,$directory);

                #
                # delete the $directory because we will rebuild it
                #
                $directory = '';

                #
                # loop though each one making them if they need to
                #
                foreach my $thisDir (@directories) {
                        #
                        # make the dir and send a debug message
                        #
                        $directory .= '/'.$thisDir;
                        mkdir($directory ,0755);
                        $self->debug($directory ,'makeDir');
                }
        }

        else { $self->FWSLog("MKDIR trying to make directory not in tree: ".$directory) }
}

=head2 runInit

Run init scripts for a site.  This can only be used after setSiteValues() or setSiteFiendly() is called.

        $fws->runInit();

=cut

sub runInit {
        my ($self) = @_;
	$self->runScript('init');
}	

=head2 runScript

Run a FWS element script.  This should not be used outside of the FWS core.  There is no recursion or security checking and should not be used inside of elements to perfent possible recursion.   Only use this if you are absolutly sure of the script content and its safety.

        %valueHash = $fws->runScript('scriptName',%valueHash);

=cut

sub runScript {
        my ($self,$guid,%valueHash) = @_;

	#
	# if this is blank, lets just not do it
	#
	if ($guid ne '') {
		#
	        # copy the self object to fws
	        #
	        my $fws = $self;

		#
		# get the short hand hash to see whats up
		#	
		my %fullElementHash = $self->_fullElementHash();
	        
		for my $fullGUID ( sort { $fullElementHash{$a}{'alphaOrd'} <=> $fullElementHash{$b}{'alphaOrd'} } keys %fullElementHash) {

                        #
                        # lets see if we have a match
                        #
                        my $liveGUID;
                        if ($fullGUID eq $guid) { $liveGUID = $fullElementHash{$fullGUID}{guid} }
                        if ($fullElementHash{$fullGUID}{type} eq $guid) { $liveGUID = $fullElementHash{$fullGUID}{guid} }

                        #
                        # we snagged one!  lets do it!
                        #
                        if ($liveGUID ne "") {
                                my %elementHash = $fws->elementHash(guid=>$liveGUID);

				if ($elementHash{'scriptDevel'} ne '') {
					eval $elementHash{'scriptDevel'};
			                my $errorCode = $@;
			                if ($errorCode) { $self->FWSLog($guid,$errorCode) }
				}
			}
		}	
	
		#
		# now put it back
		#
		$self = $fws;
		
	}
        #
        # return the valueHash back in case the script altered it
        #
        return %valueHash;
}


=head2 saveImage

Save an image with a unique width or height.  The file will be converted to extensions graphic type of the fileName passed.   Source, fileName and either width or height is required.

	#
	# convert this png, to a jpg that is 110x110
	#
        $fws->saveImage(	sourceFile=>'/somefile.png',
				fileName=>'/theNewFile.jpg',
				width=>'110',
				height=>'110');

=cut

sub saveImage {
        my ($self,%paramHash) = @_;

        #
        # use GD in trueColor mode
        #
        use GD();
        GD::Image->trueColor(1);

        #
        # create new image
        #
	my $image;
	if (! ($image =  GD::Image->new($paramHash{'sourceFile'}) ) )  {
		$self->FWSLog('Image cannot be opened by GD for resizing, it might be currupt: '.$paramHash{'sourceFile'});
	}

        #
        # if we truely have an image lets continue if not, lets pretend this didn't even happen
        #
	else {

                #
                # get current widht/height for mat to resize
                #
                my ($width,$height) = $image->getBounds();

                #
                # do math to get new width/height
                #
                if (!$paramHash{'height'}) { $paramHash{'height'} = $paramHash{'width'} / $width * $height }
                if (!$paramHash{'width'}) { $paramHash{'width'} = $paramHash{'height'} / $height * $width }

                #
                # make sure size is at least 1
                #
                if ($paramHash{'width'} < 1) { $paramHash{'width'} = 1 }
                if ($paramHash{'height'} < 1) { $paramHash{'height'} = 1 }

                #
                # Resize image and save to a file using proper mime type
                #
                my $resizedImage = new GD::Image($paramHash{'width'},$paramHash{'height'});
                $resizedImage->copyResampled($image,0,0,0,0,$paramHash{'width'},$paramHash{'height'},$width,$height);
                open    IMG, ">".$paramHash{'fileName'} or die "Error:". $!;
                binmode IMG;

                #
                # save as what ever extnesion was passed for the name
                #
                if ($paramHash{'fileName'} =~ /\.(jpg|jpeg|jpe)$/i) {   print IMG $resizedImage->jpeg() }
                if ($paramHash{'fileName'} =~ /\.png$/i) {              print IMG $resizedImage->png() }
                if ($paramHash{'fileName'} =~ /\.gif$/i) {              print IMG $resizedImage->gif() }
                close   IMG;

        }
}

=head2 FWSDecrypt

Decrypt data if a site has the proper configuration

        my $decryptedData = $fws->FWSDecrypt('alsdkjfalkj230948lkjxldkfj');

=cut

sub FWSDecrypt {
        my ($self,$encData)= @_;

        if ($self->{'encryptionType'} =~ /blowfish/i) {
                require Crypt::Blowfish;
                Crypt::Blowfish->import();
                my $cipher1 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},0,56));
                my $cipher2 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},57,56));
                my $cipher3 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},111,56));
                my $data = pack("H*",$encData);
                my $dec = '';
                while (length($data) > 0)  {
                        my $len = length($data);
                        $dec .= $cipher3->decrypt(substr($data,0,8));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ""}
                }
                $data = $dec;
                $dec = '';
                while (length($data) > 0)  {
                        my $len = length($data);
                        $dec .= $cipher2->decrypt(reverse(substr($data,0,8)));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ""}
                }
                $data = $dec;
                $dec = '';
                my $size = substr($data,0,8);
                $data = substr($data,8);
                while (length($data) > 0)  {
                        my $len = length($data);
                        $dec .= $cipher1->decrypt(substr($data,0,8));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ""}
                }
                $encData = substr($dec, 0, $size);
        }
        return $encData;
}



=head2 FWSEncrypt

Encrypt data if a site has the proper configuration

	my $encryptedData = $fws->FWSEncrypt('encrypt this stuff');

=cut

sub FWSEncrypt {
        my ($self,$data)= @_;
        my $enc = '';

        if ($self->{'encryptionType'} =~ /blowfish/i) {
                require Crypt::Blowfish;
                Crypt::Blowfish->import();
                my $cipher1 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},0,56));
                my $cipher2 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},57,56));
                my $cipher3 = Crypt::Blowfish->new(substr($self->{'encryptionKey'},111,56));
                my $fullLength = length($data);
                while (length($data) > 0)  {
                        my $len = length($data);
                        if ($len < 8) { $data .= "\000"x(8-$len) }
                        $enc .= $cipher1->encrypt(substr($data,0,8));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ''}
                }
                $fullLength = sprintf("%8d", $fullLength);
                $fullLength=~ tr/ /0/;
                $data = $fullLength.$enc;
                $enc = '';
                while (length($data) > 0)  {
                        my $len = length($data);
                        $enc .= $cipher2->encrypt(reverse(substr($data,0,8)));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ''}
                }
                $data = $enc;
                $enc = '';
                while (length($data) > 0)  {
                        my $len = length($data);
                        $enc .= $cipher3->encrypt(substr($data,0,8));
                        if ($len > 8) {$data = substr($data,8)} else {$data = ''}
                }
                $data = unpack("H*",$enc);
        }
        return $data;
}


=head2 FWSLog

Append something to the FWS.log file if FWSLogLevel is set to 1 which is default.

        #
        # Soemthing is happening
        #
        $fws->FWSLog("this is happening\nthis is a new log line");

If a multi line string is passed it will break it up in to more than one log entries.

=cut

sub FWSLog{
        my ($self,$module,$errorText) = @_;
        if ($self->{'FWSLogLevel'} > 0) {
                open(FILE, ">>".$self->{'fileSecurePath'}."/FWS.log");

                #
                # if you only pass it one thing, lets set it up so it will display
                #
                if (!defined $errorText) {
                        $errorText = $module;
                        $module = 'FWS';
                }

                #
                # split up the lines so we can pass a whole bunch and have them format each on one line
                #
                my @resultLines = split /\n/, $errorText;
                foreach my $resultLine (@resultLines) {
                        if ($resultLine ne '') {
                                print FILE $ENV{"REMOTE_ADDR"}." - [".$self->dateTime(format=>"apache"). "] ".$module.": ".$resultLine." [".$ENV{"SERVER_NAME"}.$ENV{"REQUEST_URI"}."]\n";
                        }
                }
                close(FILE);
        }
}


=head2 SQLLog

Append something to the SQL.log file if SQLLogLevel is set to 1 or 2.   Level 1 will log anything that updates a database record, and level 2 will log everything.  In good practice this should not be used, as all SQL statements are ran via the runSQL method which applies SQLLog.

        #
        # Soemthing is happening
        #
        $fws->SQLLog($theSQLStatement);

=cut


sub SQLLog{
        my ($self,$SQL) = @_;
        if ($self->{'SQLLogLevel'} > 0) {
                open(FILE, ">>".$self->{'fileSecurePath'}."/SQL.log");
                if (($self->{'SQLLogLevel'} eq '1' && ($SQL =~/^insert/i || $SQL=~/^delete/i || $SQL=~/^update/i || $SQL=~/^alter/i)) || $self->{'SQLLogLevel'} eq '2') {
                        print FILE $ENV{"REMOTE_ADDR"}." - [".$self->dateTime(format=>"apache"). "] ".$SQL." [".$ENV{"SERVER_NAME"}.$ENV{"REQUEST_URI"}."]\n";
                }
                close(FILE);
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

    perldoc FWS::V2::File


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


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::File
