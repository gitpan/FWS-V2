package FWS::V2::Format;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Format - Framework Sites version 2 text and html formatting methods

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';

=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

        my $tempPassword = $fws->createPassword( lowLength => 6, highLength => 8);

	my $newGUID = $fws->createGUID();



=head1 DESCRIPTION

Framework Sites version 2 methods that use or manipulate text either for rendering or default population.

=head1 METHODS

=head2 createGUID

Return a non repeatable Globally Unique Identifier to be used to populate the guid field that is default on all FWS tables.

        #
        # retrieve a guid to use with a new record
        #
        my $guid = $fws->createGUID();

In version 2 all GUID's have a prefix, if not specified it will be set to 'd'.  There should be no reason to use another prefix, but if you wish you can add it as the only parameter it will be used.  In newer versions of FWS the prefix will eventually be deprecated and is only still present for compatibility.

=cut

sub createGUID {
        my ($self,$guid) =@_;

	#
	# Version 2 guids are always prefixed with a character, if you don't pass one
	# lets make it 'd'
	#
        if ($guid eq '') { $guid = 'd' }

        use Digest::SHA1 qw(sha1);
        return $guid . join('', unpack('H8 H4 H4 H4 H12', sha1( shift().shift().time().rand().$<.$$)));
}

=head2 createPassword

Return a random password or text key that can be used for temp password or unique configurable small strings.

        #
        # retrieve a password that is 6-8 characters long and does not contain commonly mistaken letters
        #
        my $tempPassword = $fws->createPassword(
                                        composition     => "abcedef1234567890",
                                        lowLength       => 6,
                                        highLength      => 8);

If no composition is given, a vocal friendly list will be used: qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789

=cut

sub createPassword {
        my ($self, %paramHash) = @_;

	#
	# PH for return
	#
	my $returnString;

	#
	# set the composition to the easy say set if its blank
	#
	if ($paramHash{'composition'} eq '') { $paramHash{'composition'} = "qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789" }

        my @pass = split //,$paramHash{'composition'};
        my $length = int(rand($paramHash{'highLengthy'} - $paramHash{'lowLength'} + 1)) + $paramHash{'lowLength'};
        for(1..$length) { $returnString .= $pass[int(rand($#pass))] }
        return $returnString;
}

=head2 dateTime

Return the date time in a given format.  By passing epochTime, SQLTime you can do a time conversion from that date/time to what ever format is set to.  If you do not pass epoch or SQL time the server time will be used.

        #
        # get the current Date in SQL format
        #
        my $currentDate = $fws->dateTime(format=>'date');
        
	#
        # convert SQL formated date time to a human form
        #
        my $humanDate = $fws->dateTime(SQLTime=>'2012-10-12 10:09:33',format=>'date');

By passing monthMod you can adjust the month forward or backwards by the given number of months

	#
	# 3 months from today (negative numbers are ok)
	#
	my $threeMonths = $fws->dateTime(format=>'date',monthMod=>3);

The following types of formats are valid:

=over 4

=item * date : mm-dd-yyyy

=item * time : hh:mmAM XXX

=item * fancyDate : weekdayName, monthName dd[st|nd|rd] of yyyy

=item * cookie : cookie compatible date/time

=item * apache : apache web server compatible date/time

=item * number : yyyymmddhhmmss

=item * dateTime : mm-dd-yyyy hh:mmAM XXX

=item * dateTimeFull : mm-dd-yyyy hh:mm:ss XXX

=item * SQL : yyyy-mm-dd hh:mm:ss

=item * epoch : Standard epoch number

=item * yearFirstDate : yyyy-mm-dd

=back

=cut

sub dateTime {
        my ($self,%paramHash) = @_;
        my $format      = $paramHash{'format'};
        my $monthMod    = $paramHash{'monthMod'};
        my $POSIXTime   = $paramHash{'POSIXTime'};
        my $epochTime   = $paramHash{'epochTime'};
        my $GMTOffset   = $paramHash{'GMTOffset'};
        my $SQLTime     = $paramHash{'SQLTime'};


        if ($SQLTime ne '') {
                my @timeSplit = split(/[ \-:]/,$SQLTime);
                if ( $timeSplit[0] < 1970) {$timeSplit[0] = '1970';}
                if ( $timeSplit[1] eq '' || $timeSplit[1] == 0) {$timeSplit[1] = '1'}
                if ( $timeSplit[2] eq '' || $timeSplit[2] == 0) {$timeSplit[2] = '1'}
                if ( $timeSplit[3] eq '') {$timeSplit[3] = '0'}
                if ( $timeSplit[4] eq '') {$timeSplit[4] = '0'}
                if ( $timeSplit[5] eq '') {$timeSplit[5] = '0'}
                $timeSplit[1]--;
                require Time::Local;
                Time::Local->import();
                $epochTime = timelocal(reverse(@timeSplit));
        }

        #
        # $format = odbc, date, time, dateAndTime, SQL, number
        #
        if ($epochTime eq '') { $epochTime = time() }
        my $timeZoneOffSetSeconds = $GMTOffset * 3600;
        $epochTime += $timeZoneOffSetSeconds;

        #
        # get the localtime
        #
        my ($sec,$min,$hr,$mday,$mon,$annum,$wday,$yday,$isdst) = localtime($epochTime);

        #
        # we want months to go from 1-12 with the mod adjustment
        #
        $mon += $monthMod + 1;

        #
        # and we want to use four-digit years
        #
        my $year = 1900 + $annum;

        #
        # min and second is always leading zero
        #
        $min = ("0" x (2 - length($min))).$min;
        $sec = ("0" x (2 - length($sec))).$sec;

        #
        # lets grab minute before we PM/AM it
        #
        my $minute = $min;

	#
        #grab the hour before we am/pm it
        #
        my $hour = $hr;

        #
        # turn military time time to AM/PM time
        # hr is the AM PM version hour is military
        #
        if ($hr > 12) {
                $hr = $hr-12;
                $min .= "PM";
        }
        else {
                if ($hr == 12)          { $min .= "PM" }
                else                    { $min .= "AM" }
        }


        #
        # if the $month is less than 1 then shift them off to the year slots
        # if the monthmod is more than 12 shift them off to the year slots positivly
        #
        while ($mon < 1) {
                $mon += 12;
                $year--;
        }
        while ($mon > 12 ) {
                $mon -= 12;
                $year++;
        }

        #
        # adjust the number of months by the mod
        #
        my $month = ("0" x (2 - length($mon))) . $mon;

        #
        # leading zero our minute
        #
        $hour = ("0" x (2 - length($hour))).$hour;
        my $monthDay = ("0" x (2 - length($mday))) . $mday;

        #
        # this is what we will return
        #
        my $showDateTime = '';

        if ($format =~ /^number$/i) {
                $showDateTime = $year.$month.$monthDay.$hour.$minute.$sec;
        }

        if ($format =~ /^cookie$/i) {
                my @dayName = qw(Sun Mon Tue Wed Thu Fri Sat);
                my @monthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
                $showDateTime = $dayName[$wday].", ".$monthDay."-".$monthName[$mon-1]."-".$year." ".$hour.":".$minute.":".$sec." GMT";
        }


        if ($format =~ /^fancyDate$/i) {
                my @dayName = qw(Sunday Monday Tueday Wednesday Thursday Friday Saturday);
                my @monthName = qw(January Febuary March April May June July August September October November December);
                my $numberCap = 'th';
                $monthDay =~ s/^0//sg;
                if ($monthDay =~ /^2$/) { $numberCap = "nd" }
                if ($monthDay =~ /^3$/) { $numberCap = "rd" }
                if ($monthDay =~ /^1$/) { $numberCap = "st" }
                $showDateTime = $dayName[$wday].", ".$monthName[$mon-1]." ".$monthDay.$numberCap." of ".$year;
        }

        if ($format =~ /^apache$/i) {
                my @monthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
                my @dayName = qw(Sun Mon Tue Wed Thu Fri Sat);
                my $timeZoneOffSetSeconds = $GMTOffset * 3600;
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($epochTime+$timeZoneOffSetSeconds);
                $year=$year+1900;
                $showDateTime = $dayName[$wday].", ".$mday." ".$monthName[$mon]." ".$year." ".$hour.":".$minute.":".$sec." GMT";
        }

        if ($format =~ /^odbc$/i|| $format =~ /SQL/i) {
                $showDateTime = $year."-".$month."-".$monthDay." ".$hour.":".$minute.":".$sec;
        }

        if ($format =~ /^date$/i) {
                $showDateTime = $month."-".$monthDay."-".$year;
        }

        if ($format =~ /^time$/i) {
                $showDateTime = $hr.":".$min." EST";
        }

        if ($format =~ /^dateTime$/i) {
                $showDateTime = $month."-".$monthDay."-".$year." ".$hr.":".$min." EST";
        }

        if ($format =~ /^dateTimeFull$/i) {
                $showDateTime = $month."-".$monthDay."-".$year." ".$hour.":".$minute.":".$sec." EST";
        }

        if ($format =~ /^yearFirstDate$/i) {
                $showDateTime = $year."-".$month."-".$monthDay;
        }

        if ($format =~ /^firstOfMonth$/i) {
                $showDateTime = $month."-01-".$year;
        }

        if ($format =~ /^epoch$/i) {
                $showDateTime = $epochTime;
        }

        return $showDateTime;
}





=head2 jqueryEnable

Add FWS core distribution jQuery modules and corresponding CSS files to the CSS and JS cached files.  These are located in the /fws/jquery directory.  The naming convention for jQuery files are normalized and only the module name and version is required.

	#
	# if the module you were loadings file name is:
	# jquery-WHATEVERTHEMODULEIS-1.1.1.min.js
	# it would be loaded via jqueryEnable as follows:
        #
        $fws->jqueryEnable('WHATEVERTHEMODULEIS-1.1.1');

This method ensures jQuery files are only loaded once, and the act of any jQuery module being enabled will auto-activate the core jQuery library.  They will be loaded in the order they were called  from any element in the rendering process.

=cut

sub jqueryEnable {
        my ( $self, $jqueryEnable ) = @_;

        #
        # get the current hash
        #
        my %jqueryHash = %{$self->{'_jqueryHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($jqueryHash{$jqueryEnable} eq '') { $jqueryHash{$jqueryEnable} = keys %jqueryHash }

        #
        # pass the new hash back into the jqueryHash
        #
        %{$self->{'_jqueryHash'}} = %jqueryHash;
}



############################################################################################
# HELPER: organize JS scripts to be used
############################################################################################

sub _jsEnable {
        my ( $self, $jsEnable,$modifier ) = @_;

        #
        # get the current hash
        #
        my %jsHash = %{$self->{'_jsHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($jsHash{$jsEnable} eq '') { $jsHash{$jsEnable} = (keys %jsHash)+$modifier }

        #
        # pass the new hash back into the jsHash
        #
        %{$self->{'_jsHash'}} = %jsHash;
}


############################################################################################
# HELPER: organize CSS files to be used
############################################################################################

sub _cssEnable {
        my ( $self, $cssEnable,$modifier ) = @_;
	
        #
        # get the current hash
        #
        my %cssHash = %{$self->{'_cssHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($cssHash{$cssEnable} eq '') { $cssHash{$cssEnable} = (keys %cssHash)+$modifier }

        #
        # pass the new hash back into the cssHash
        #
        %{$self->{'_cssHash'}} = %cssHash;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Format


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

1; # End of FWS::V2::Format
