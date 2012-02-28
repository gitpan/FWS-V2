package FWS::V2;

use 5.006;
use strict;

=head1 NAME

FWS::V2 - Framework Sites Version 2

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new();

=head1 DESCRIPTION

Framework Sites Version 2 content management, eCommerce and web based development platform.

=head1 METHODS

=head2 new

Construct the FWS Version 2 core. Like the highly compatible web optimized distribution this will initiate access to all the FWS methods to access data, files, formatting and network methods. You can pass a variety of different parameters which could be required depending on what methods you are using and the context of your usage. MySQL and SQLite are supported with FWS 2, but MySQL should always be used if it is available. On medium or high traffic sites and sites with large data footprints, you will see quite a bit of latency with SQLite. 

=over 4

=item * DBName (MySQL and SQLite Required)

For MySQL this is the DB Name.  For SQLite this is the DB file path and file name.
MySQL example:  user_fws
SQLite example: /home/user/secureFiles/user_fws.db

=item * DBUser (MySQL Required)

Required for MySQL and is the database user that has full grant access to the database.

=item * DBPassword (MySQL Required)

The DBUser's password.

=item * DBHost (MySQL Required if your database is not on localhost)

The DBHost will default to 'localhost' if not specified, but can be what ever is configured for the database environment.


=item * DBType (SQLite Required)

The DBType will default to 'MySQL' if not specified, but needs to be added if you are connecting to SQLite.

=back

Non-required parameters for FWS installations can be added, but depending on the scope of your task they usually are not needed unless your testing code, or interacting with web elements that display rendered content from a stand alone script.

=over 4

=item * domain

Full domain name with http prefix.  Example: http://www.example.com

=item * filePath

Full path name of common files. Example: /home/user/www/files

=item * fileSecurePath

Full path name of non web accessible files. Example: /home/user/secureFiles

=item * fileWebPath

Web path for the same place filePath points to.  Example: /files

=item * secureDomain

Secure domain name with https prefix. For non-secure sites that do not have an SSL cert you can use the http:// prefix to disable SSL.  Example: https://www.example.com

=back

=cut

BEGIN {
        our @ISA = (
                        "FWS::V2::Database",
                        "FWS::V2::Check",
                        "FWS::V2::File",
                        "FWS::V2::Format",
                        "FWS::V2::Safety");
   
	use FWS::V2::Database;
	use FWS::V2::Check;
	use FWS::V2::File;
	use FWS::V2::Format;
	use FWS::V2::Safety;
}

sub new {
        my $class = shift;
        my $self = {@_};
        bless $self, $class;
        return $self;
}

=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2


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

1; # End of FWS::V2
