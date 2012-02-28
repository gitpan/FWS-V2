package FWS::V2::File;

use 5.006;
use strict;
use warnings;

=head1 NAME

FWS::V2::File - Framework Sites version 2 file methods

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';


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
