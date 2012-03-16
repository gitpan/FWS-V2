package FWS::V2;

use 5.006;
use strict;

=head1 NAME

FWS::V2 - Framework Sites Version 2

=head1 VERSION

Version 0.006

=cut

our $VERSION = '0.006';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new(	DBName		=> 'myDB',
				DBUser		=> 'theUser',
				DBPassword	=> 'superSecret',
				DBHost		=> 'localhost',
				DBType		=> 'MySQL');
	

=head1 DESCRIPTION

Framework Sites Version 2 content management, eCommerce and web based development platform.

=head1 METHODS AND PARAMETERS

=head2 new

Construct a FWS Version 2 object. Like the highly compatible web optimized distribution this will initiate access to all the FWS methods to access data, file, session, formatting and network methods. You can pass a variety of different parameters which could be required depending on what methods you are using and the context of your usage. MySQL and SQLite are supported with FWS 2, but MySQL should always be used if it is available. On medium or high traffic sites and sites with any significance of a data footprint, you will see quite a bit of latency with SQLite. 

Example of using FWS with MySQL:

	use FWS::V2;

        #
        # Create FWS with MySQL connectivity
        #
        my $fws = FWS::V2->new(       DBName          => "theDBName",
                                      DBUser          => "myUser",
                                      DBPassword      => "myPass");

Example of using FWS with SQLite:
	
	use FWS::V2;

        #
        # create FWS with SQLite connectivity
        #
        my $fws = FWS::V2->new(      DBType          => "SQLite",
                                     DBName          => "/home/user/your.db");


Any variable passed or derived can be accessed with the following syntax:

	print $fws->{'someParameter'}."\n

With common uses of FWS, you should never need to change any of these settings.  If for some reason, although it is NOT recommended you can set any of these variables with the following syntax:
	
	$fws->{'someParameter'} = 'new settings';

=head2 Required Parameters

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

=head2 Non-Required Parameters

Non-required parameters for FWS installations can be added, but depending on the scope of your task they usually are not needed unless your testing code, or interacting with web elements that display rendered content from a stand alone script.

=over 4

=item * adminPassword

For new installations this is the admin password until the first super admin account is created.  After an admin account is created this password is disabled.

=item * adminURL

The url defined to get to the typical /admin log in screen.  Default: 'admin'

=item * affiliateExpMax

The number of seconds an affiliate code will stay active after it has been received.  Default: 295200

=item * cookieDomainName

The domain to use for cookies.  Almost always it would be: '.whatEverYourDomainIs.com'  For more complex scenario with host names you would want to make this more specific.

=item * domain

Full domain name with http prefix.  Example: http://www.example.com

=item * encryptionKey

The encryption key to be used if encryptionType is set to 'blowfish'.

=item * encryptionType

If set this will set what encryption method to use on sensitive data.  The only supported type is 'blowfish'.

=item * filePath

Full path name of common files. Example: /home/user/www/files

=item * fileSecurePath

Full path name of non web accessible files. Example: /home/user/secureFiles

=item * fileWebPath

Web path for the same place filePath points to.  Example: /files

=item * googleAppsKeyFile

For google apps support for standard login modules this is required

=item * scriptTextSize

If your element scripts are larger than 'text' and get truncated you might want to set this to 'mediumtext'

=item * secureDomain

Secure domain name with https prefix. For non-secure sites that do not have an SSL cert you can use the http:// prefix to disable SSL.  Example: https://www.example.com

=item * sendmailBin

The location of the sendmail bin. Default: /usr/sbin/sendmail

=item * sendMethod

The method used to process queue requests internal or custom.   Default: sendmail

=item * FWSLogLevel

Set how verbose logging is for FWS is.  Logging will be appended: $fws->{'fileSecurePath'}.'/FWS.log'
0 - off , 1 (default)- Display errors

=item * SQLLogLevel

Set how verbose logging is for SQL statements ran.  Logging will be appended: $fws->{'fileSecurePath'}.'/SQL.log'
0 - off (default), 1 - updates/deletes/inserts only, 2 - everything

=back

=head2 Accessible after setSiteFiendly() is called

These should not be set directly.  They are set by calling other methods that discover what the values should be.

=over 4

=item * siteId

The site id of the site currently being rendered.  Version 1 of FWS refered to this as the SID.  This will be set via setSiteValues('yourSiteId') if setSiteFriendly is not being used.

=back 

=head2 Accessible after setSiteValues() is called

The following variables should never be passed or set externaly

=over 4

=item * email

The default email address for the site being rendered.  This is set via 'Site Settings' in the administration.

=item * fileFWSPath

The file location of FWS packaged distrubution files.  This is normaly not used except internally as the files in this directory could change with an upgrade.

=item * homeGUID

The guid of the home page.  The formValue 'p' will be set to this if no 'p' value is passed.

=item * siteGUID

The guid of the site currently being rendered

=item * sessionCookieName

If there could be conflict with the cookie name, you can change the name of the cookie from its default of fws_session to something else.

=item * siteName

The site name of the site currently being rendered

=item * queryHead

The query head used for links that will maintain session and have a unique random cache key.  Example return: ?fws_noCache=asdqwe&session=abc....123&s=site&

=back

=head2 Accessible after setSession() is called

=over 4

=item * affiliateId

Is set by passing a value to 'a' as a form value. Can be accessed via $fws->{'affiliateId'};

=item * affiliateExp

The time in epoch that the affiliate code will expire for the current session

=back


=cut

#########################################################################
#
#                      CODING AND STYLE HINTS
#
#            If you going to touch the code,  read this first!
#
#########################################################################
#
# WEB OPTIMIZED COMPATABILITY VERSION
# The compatability version of this code base is derived from these
# modules and in a couple spots you will see a HIDE and END HIDE
# block which is used by the compatability processor.  Leave these
# in tact to maintain compatability with that processor.
#
# INHERITANCE
# The compatibility version of this code has one package.  To maintain
# consistancy between the two versions everything is inherited, always.
#
# ELSE CUDDLING
# Use non cuddled elses unless its all on the same line with the if. 
#
# CONDITIONALS PERFER 'ne' 'eq'
# All conditionals that can be, are treated like strings and in very 
# limited cases is 'exists', and 'defined' used.  This is due to the
# anonymous hash structure and creating consistant logic for hashes
# that might not yet be defined depending on scope.
#
# HASH ARRAYS (An array of hashes)
# If your unfamiliar wit this technique read up on it.  The data model
# for FWS is based on the idea of arrays of anonymous hashes.  It is
# everywhere you get data!
#
# REFERENCES
# The original version of FWS did not use extensive references for data
# in an attempt to make things simple.  By default hash arrays will come
# back in this way unless you specify ref=>1 in the whateverArray or 
# whateverHash call.  In future versions this will be reversed so doing
# ref=>1 in all calls hash/Array methods would be considered good form. 
#
# LEGACY GET/SET SUBROUTINES
# A lot of get/set type functions were also in the original source
# those are getting phased out to only use the $fws->{'theSetting'} = '1'
# syntax.   Make note of the legacy functions in the POD and use the
# more current syntax when available#
#
#########################################################################

################## HIDE ##################### Web optimized import block flag
BEGIN {
        our @ISA = (	"FWS::V2::Database",
                        "FWS::V2::Check",
                        "FWS::V2::File",
                        "FWS::V2::Format",
                        "FWS::V2::Net",
                        "FWS::V2::Legacy",
                        "FWS::V2::Session",
                        "FWS::V2::Safety");
   
	use FWS::V2::Database;
	use FWS::V2::Check;
	use FWS::V2::File;
	use FWS::V2::Format;
	use FWS::V2::Net;
	use FWS::V2::Legacy;
	use FWS::V2::Session;
	use FWS::V2::Safety;
}
############### END HIDE #################### Web optimized import block flag

sub new {
        my $class = shift;
        my $self = {@_};

	#
	# set the FWS Version we are using
	#
	$self->{'FWSVersion'} = '2.0.0';

	#
	# Major version parse
	# 
        my @loadVerSplit = split(/\./,$self->{'FWSVersion'});
	$self->{'FWSMajorVersion'} = $loadVerSplit[0].'.'.$loadVerSplit[1];
	
	#
	# fake common ENV vars if we don't have them
	#
	if (!exists $ENV{"REMOTE_ADDR"}) { $ENV{"REMOTE_ADDR"} 	= 'localhost' }
	if (!exists $ENV{"SERVER_NAME"}) { $ENV{"SERVER_NAME"} 	= 'localhost' }
	if (!exists $ENV{"REQUEST_URI"}) { $ENV{"REQUEST_URI"} 	= '' }


	#
	# set the default security hash
	#
        $self->{'securityHash'}->{'isAdmin'}{'title'}           = 'Super User Account';
        $self->{'securityHash'}->{'isAdmin'}{'note'}            = 'All installations should have one user of this type for security reasons.  Having a user of this type will disable the embedded admin account.';

        $self->{'securityHash'}->{'showContent'}{'title'}       = 'Full Edit Mode Access';
        $self->{'securityHash'}->{'showContent'}{'note'}        = 'Access to view and change the content in edit mode.';

        $self->{'securityHash'}->{'showDesign'}{'title'}        = 'Designer Access';
        $self->{'securityHash'}->{'showDesign'}{'note'}         = 'Add and delete pages, layouts, design css, javascript, and files.';

        $self->{'securityHash'}->{'showDeveloper'}{'title'}     = 'Developer Access';
        $self->{'securityHash'}->{'showDeveloper'}{'note'}      = 'Access to developer controls, element custom element creation and site creation and deletion.';

        $self->{'securityHash'}->{'showQueue'}{'title'}         = 'Email Queue Access';
        $self->{'securityHash'}->{'showQueue'}{'note'}          = 'Access to view email sending queue, and message history.';

        $self->{'securityHash'}->{'showSEO'}{'title'}           = 'SEO Controls';
        $self->{'securityHash'}->{'showSEO'}{'note'}            = 'Access to view SEO Defaults and page properties.';

        $self->{'securityHash'}->{'showSiteSettings'}{'title'}  = 'Site Settings Menu';
        $self->{'securityHash'}->{'showSiteSettings'}{'note'}   = 'Generic site settings and 3rd party connector configurations.';

        $self->{'securityHash'}->{'showECommerce'}{'title'}     = 'Full eCommerce User';
        $self->{'securityHash'}->{'showECommerce'}{'note'}      = 'View and manage eCommerce orders, oroduct matrix and subscription invoices.';

        $self->{'securityHash'}->{'showSiteUsers'}{'title'}     = 'User Account Access';
        $self->{'securityHash'}->{'showSiteUsers'}{'note'}      = 'Access to create, delete and modify high level information for site accounts';

        $self->{'securityHash'}->{'showAdminUsers'}{'title'}    = 'Admin User Account Access';
        $self->{'securityHash'}->{'showAdminUsers'}{'note'}     = 'Give users access to add, remove and change admin users. (This area)';

	#
	# set defaults
	#

	#
	# TODO rewrite this section to reverse defaults and overload passed parameter.  Would be slightly more efficient 
	#

	#
        # if the admin ID is blank, set it to admin so users can access it via /admin
        #
        if ($self->{'adminURL'} eq '') 		{ $self->{'adminURL'} = 'admin' }

	#
	# set the secure domain to a non https because it probably does not have a cert if it was not set 
	#
        if ($self->{'secureDomain'} eq '')      { $self->{'secureDomain'} = 'http://'.$ENV{"SERVER_NAME"} }

	#
	# Sometimes sites need bigger thatn text blob, 'mediumtext' might be needed
	#
        if ($self->{'scriptTextSize'} eq '')    { $self->{'scriptTextSize'} = 'text' }
	
	#
	# set the domains to the environment version if it was not set
	#
        if ($self->{'sessionCookieName'} eq '')  { $self->{'sessionCookieName'} = 'fws_session' }
	#
	# set the domains to the environment version if it was not set
	#
        if ($self->{'domain'} eq '')            { $self->{'domain'} = 'http://'.$ENV{"SERVER_NAME"} }

	#
	# the FWS auto update server
	#
        if ($self->{'FWSServer'} eq '')         { $self->{'FWSServer'} = 'http://www.frameworksites.com/downloads' }

	#
	# set the default seconds to how long a affiliate code will last once it is recieved
	#
	if ($self->{"affiliateExpMax"} eq '') 	{ $self->{"affiliateExpMax"} = 295200 }

	#
	# set the default FWS log level
	#
	if ($self->{"FWSLogLevel"} eq '') 	{ $self->{"FWSLogLevel"} = 1 }

	#
	# set the default SQL log level
	#
	if ($self->{"SQLLogLevel"} eq '') 	{ $self->{"SQLLogLevel"} = 0 }
	
	#
	# set the default location for sendmail
	#
	if ($self->{"sendmailBin"} eq '') 	{ $self->{"sendmailBin"} = '/usr/sbin/sendmail' }

	#
	# prepopulate a few things that might be needed so they are not undefined
	#
	%{$self->{'_cssHash'}} 			= ();
	%{$self->{'_jsHash'}} 			= ();
	%{$self->{'_jqueryHash'}} 		= ();
        %{$self->{'_saveWithSessionHash'}}	= ();
	%{$self->{'_fullElementHashCache'}}	= ();
	%{$self->{'_tableFieldHashCache'}}	= ();
	%{$self->{'_siteScriptCache'}}		= ();
	%{$self->{'_subscriberCache'}}		= ();

	$self->{'_language'}			= '';
	$self->{'_languageArray'}		= '';

	#
	# cache fields will be populated on setSiteValues
	# but in case we need a ph before then
	#
	%{$self->{'dataCacheFields'}}		= ();

	#
	# this will store the currently logged in userHash
	#
	%{$self->{'profileHash'}}		= ();

	
	#
	# set this to false, it might be turned on at any time by admin or elements
	#
	$self->{'tinyMCEEnable'}          	= 0;

	
	#
	# add self
	#
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
