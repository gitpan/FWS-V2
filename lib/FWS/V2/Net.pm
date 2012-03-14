package FWS::V2::Net;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Net - Framework Sites version 2 network access methods

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.002';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

	my $responseRef = $fws->HTTPRequest(url=>'http://www.thiswebsite.com');


=head1 DESCRIPTION

FWS version 2 core network methods 

=head1 METHODS

=head2 HTTPRequest

Post HTTP or HTTPS and return the result to a hash reference containing the results plus the parameters provided.

        my $responseRef = $fws->HTTPRequest(	url	=>'http://www.cpan.org' # only required parameter
						type	=>'get'			# default is get [get|post]
						user	=>'theUser'		# if needed for auth
						password=>'thePass'		# if needed for auth 
						ip	=>'1.2.3.4');		# show that I am from this ip

	print $responseRef->{'url'}."\n";		# what was passed to HTTPRequest
	print $responseRef->{'success'}."\n";		# will be a 1 or a 0
	print $responseRef->{'content'}."\n";		# the content returned
	print $responseRef->{'status'}."\n";		# the status returned

=cut

sub HTTPRequest {
        my ($self,%paramHash) = @_;

	#
	# lets use the LWP to get this done
	#
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new();

	#
	# lets get our request obj ready
	#
        my $req;

        #
        # force an IP if needed
        #
        if ($paramHash{'ip'} ne '') { $ua->local_address($paramHash{'ip'}) }

        #
        # this is a post... but we get the stuff just like a get - but do the work
        #
        if ($paramHash{'type'} =~ /post/i) {
                my ($postURL,$content) = split(/\?/,$paramHash{'url'});
                $req = HTTP::Request->new(POST => $postURL);
                $req->content_type('application/x-www-form-urlencoded');
                $req->content($content);
        }
        else { $req = HTTP::Request->new(GET => $paramHash{'url'}) }

        #
        # if auth is set, lets set it!
        #
        if ($paramHash{'user'} ne '' && $paramHash{'password'} ne '') { $req->authorization_basic($paramHash{'user'}, $paramHash{'password'}) }

        #
        # do the request and see what happens
        #
	my $response = $ua->request($req);
	$paramHash{'content'} = $response->content;
        if ($response->is_success) { $paramHash{'success'} = 1 }
        else { $paramHash{'success'} = 0 }

	#
	# return the reference
	#
	return \%paramHash;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Net


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

1; # End of FWS::V2::Net
