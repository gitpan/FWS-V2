package FWS::V2::Format;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Format - Framework Sites version 2 text formatting methods

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

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

In version 2 all GUID's have a prefix, if not specified it will be set to 'd'.  There should be no reason to use another prefix, but if you wish you could add it as the only parameter and will be used instead of the letter d.  In newer versions of FWS the prefix will eventually be deprecated and is only still present for compatibility.

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
