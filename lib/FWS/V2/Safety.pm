package FWS::V2::Safety;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Safety - Framework Sites version 2 safe data wrappers

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

	#
	# each one of these statements will clean the string up to make it "safe"
	# depending on its context
	#	

	print $fws->safeDir("../../this/could/be/dangrous");
	
        print $fws->safeFile("../../i-am-trying-to-change-dir.ext");
	
        print $fws->safeSQL("this ' or 1=1 or ' is super bad");


=head1 DESCRIPTION

FWS version 2 safety methods are used for security when using unknown parameters that could be malicious.   Whenever data is passed to another method it should be wrapped in its appropriate safety wrapper under the guidance of each method.


=head1 METHODS

=head2 safeDir

All directories should be wrapped in this method before being applied.  It will remove any context that could change its scope to higher than its given location.  When using directories ALWAYS prepend them with $fws->{"fileDir"} or $fws->{"secureFileDir"} to ensure they root path is always in a known location to further prevent any tampering.  NEVER use a directory that is not prepended with a known depth!

        #
        # will return //this/could/be/dangerous
        #
        print $fws->safeDir("../../this/could/be/dangrous");

        #
        # will return this/is/fine
        #
        print $fws->safeDir("this/is/fine");

=cut

sub safeDir {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/(\.\.|\||;)//sg;
        return $incommingText;
}


=head2 safeFile

All files should be wrapped in this method before being applied.  It will remove any context that could change its scope to a different directory.

        #
        # will return ....i-am-trying-to-change-dir.ext
        #
        print $fws->safeFile("../../i-am-trying-to-change-dir.ext");

=cut


sub safeFile {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/(\/|\\|;|\|)//sg;
        return $incommingText;
}


=head2 safeSQL

All fields and dynamic content in SQL statements should be wrapped in this method before being applied.  It will add double tics and escape any escapes so you can not break out of a statement and inject anything not intended.

        #
        # will return this '' or 1=1 or '' is super bad
        #
        print $fws->safeSQL("this ' or 1=1 or ' is super bad");

=cut

sub safeSQL {
        my ($self, $incommingText) = @_;
        $incommingText =~ s/\'/\'\'/sg;
        $incommingText =~ s/\\/\\\\/sg;
        return $incommingText;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Safety


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

1; # End of FWS::V2::Safety
