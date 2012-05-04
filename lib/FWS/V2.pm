package FWS::V2;

use 5.006;
use strict;


#
# not everything will be defined by nature
#
no warnings 'uninitialized';


=head1 NAME

FWS::V2 - Framework Sites version 2

=head1 VERSION

Version 0.007

=cut

our $VERSION = '0.007';


=head1 SYNOPSIS

    use FWS::V2;
    my $fws = FWS::V2->new(	DBName		=> 'myDB',
				DBUser		=> 'theUser',
				DBPassword	=> 'superSecret',
				DBHost		=> 'localhost',
				DBType		=> 'MySQL');
	
=head1 DESCRIPTION

Framework Sites version 2 content management, eCommerce and web based development platform.

=head1 METHODS AND PARAMETERS

=head2 new

Construct a FWS version 2 object. Like the highly compatible web optimized distribution this will initiate access to all the FWS methods to access data, file, session, formatting and network methods. You can pass a variety of different parameters which could be required depending on what methods you are using and the context of your usage. MySQL and SQLite are supported with FWS 2, but MySQL should always be used if it is available. On medium or high traffic sites and sites with any significance of a data footprint, you will see quite a bit of latency with SQLite. 

Example of using FWS with MySQL:

        #
        # Create FWS with MySQL connectivity
        #
	use FWS::V2;
        my $fws = FWS::V2->new(       DBName          => "theDBName",
                                      DBUser          => "myUser",
                                      DBPassword      => "myPass");

Example of using FWS with SQLite:

        #
        # create FWS with SQLite connectivity
        #
	use FWS::V2;
        my $fws = FWS::V2->new(      DBType          => "SQLite",
                                     DBName          => "/home/user/your.db");

Any variable passed or derived can be accessed with the following syntax:

	print $fws->{'someParameter'}."\n";

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

=item * sessionCookieName

If there could be conflict with the cookie name, you can change the name of the cookie from its default of fws_session to something else.

=item * FWSLogLevel

Set how verbose logging is for FWS is.  Logging will be appended: $fws->{'fileSecurePath'}.'/FWS.log'
0 - off , 1 (default)- Display errors

=item * FWSKey

This is the domain key from your frameworksites.com account. This is used to share content from different installs using frameworksites.com as your distribution hub.  This is only used if your a FWS plugin developer or a developer has given you this key to install a plugin they created. 

=item * FWSPluginServer

The server used to plublish and intall plugins.  Defaults to https://www.frameworksites.com

=item * FWSServer

The server used to download the FWS Core updates.  Defaults to http://www.frameworksites.com

=item * SQLLogLevel

Set how verbose logging is for SQL statements ran.  Logging will be appended: $fws->{'fileSecurePath'}.'/SQL.log'
0 - off (default), 1 - updates/deletes/inserts only, 2 - everything (This file will grow fast if set to 2)

=back

=head1 DERIVED VARIABLES AND METHODS

=head2 Accessable after getFormValues() is called

=over 4

=item * formValue()

All passed variables.  The value is not set, it will return as blank.

=item * formArray()

An array of form values passed.

=back

=head2 Accessable after setSiteFiendly() is called

=over 4

=item * {'siteId'}

The site id of the site currently being rendered.  Version 1 of FWS refered to this as the SID.  This will be set via setSiteValues('yourSiteId') if setSiteFriendly is not being used.

=item * formValue('p')

The current page friendly or if not available the page guid.

=back 

=head2 Accessable after setSession() is called

=over 4

=item * {'affiliateId'}

Is set by passing a value to 'a' as a form value. Can be accessed via $fws->{'affiliateId'}

=item * {'affiliateExp'}

The time in epoch that the affiliate code will expire for the current session.

=item * formValue('session')

The current session ID.

=back

=head2 Accessable after setSiteValues() is called

=over 4

=item * {'email'}

The default email address for the site being rendered.  This is set via 'Site Settings' in the administration.

=item * {'fileFWSPath'}

The file location of FWS packaged distrubution files.  This is normaly not used except internally as the files in this directory could change with an upgrade.

=item * {'homeGUID'}

The guid of the home page.  The formValue 'p' will be set to this if no 'p' value is passed.

=item * {'siteGUID'}

The guid of the site currently being rendered.

=item * {'siteName'}

The site name of the site currently being rendered.

=item * {'queryHead'}

The query head used for links that will maintain session and have a unique random cache key.  Example return: ?fws_noCache=asdqwe&session=abc....123&s=site&  It is important not to use this in a web rendering that will become static though caching.   If the session= is cached on a static page it will cause a user who clicks the cached link to be logged out.  queryHead is only to ment to be used in situations when you are passing from one domain to another and wish to maintain the same session ID.

=back

=head2 Accessable after processLogin() is called

=over 4

=item * {'adminLoginId'}

The current user id for the admin user logged in.  Extra warning: This should never be set externally!

=item * {'userLoginId'}

The current user id for the site user logged in.  Extra warning: This should never be set externally!

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

sub new {
	my ($class, %params) = @_;
	my $self = bless \%params, $class;

        #
        # set the FWS version we are using
        #
        $self->{'FWSVersion'} = '2.1.0';

        #
        # Major version parse
        #
        my @loadVerSplit = split(/\./,$self->{'FWSVersion'});
        $self->{'FWSMajorVersion'} = $loadVerSplit[0].'.'.$loadVerSplit[1];

        #
        # fake common ENV vars if we don't have them
        #
        if (!exists $ENV{"REMOTE_ADDR"}) { $ENV{"REMOTE_ADDR"}  = 'localhost' }
        if (!exists $ENV{"SERVER_NAME"}) { $ENV{"SERVER_NAME"}  = 'localhost' }
        if (!exists $ENV{"REQUEST_URI"}) { $ENV{"REQUEST_URI"}  = '' }


        #
        # set the default security hash
        #
        $self->{'securityHash'}->{'isAdmin'}{'title'}           = 'Super User Account';
        $self->{'securityHash'}->{'isAdmin'}{'note'}            = 'This user has access to all FWS features, and has the ability to add and remove admin users.  All installations should have one user of this type for security reasons.  Having a user of this type will disable the embedded admin account.';

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

        #
        # set defaults
        #

        #
        # TODO rewrite this section to reverse defaults and overload passed parameter.  Would be slightly more efficient
        #

        #
        # if the admin ID is blank, set it to admin so users can access it via /admin
        #
        if ($self->{'adminURL'} eq '')          { $self->{'adminURL'} = 'admin' }

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
        # if the admin ID is blank, set it to admin so users can access it via /admin
        #
        if ($self->{'FWSPluginServer'} eq '')   { $self->{'FWSPluginServer'} = 'https://www.frameworksites.com' }
        #
        # the FWS auto update server
        #
        if ($self->{'FWSServer'} eq '')         { $self->{'FWSServer'} = 'http://www.frameworksites.com/downloads' }

        #
        # set the default seconds to how long a affiliate code will last once it is recieved
        #
        if ($self->{"affiliateExpMax"} eq '')   { $self->{"affiliateExpMax"} = 295200 }

        #
        # set the default FWS log level
        #
        if ($self->{"FWSLogLevel"} eq '')       { $self->{"FWSLogLevel"} = 1 }

        #
        # set the default SQL log level
        #
        if ($self->{"SQLLogLevel"} eq '')       { $self->{"SQLLogLevel"} = 0 }

        #
        # set the default location for sendmail
        #
        if ($self->{"sendmailBin"} eq '')       { $self->{"sendmailBin"} = '/usr/sbin/sendmail' }

        #
        # prepopulate a few things that might be needed so they are not undefined
        #
        %{$self->{'_cssHash'}}                  = ();
        %{$self->{'_jsHash'}}                   = ();
        %{$self->{'_jqueryHash'}}               = ();
        %{$self->{'_saveWithSessionHash'}}      = ();
        %{$self->{'_fullElementHashCache'}}     = ();
        %{$self->{'_tableFieldHashCache'}}      = ();
        %{$self->{'_siteScriptCache'}}          = ();
        %{$self->{'_subscriberCache'}}          = ();

        $self->{'_language'}                    = '';
        $self->{'_languageArray'}               = '';

	@{$self->{'pluginCSSArray'}}		= ();
	@{$self->{'pluginJSArray'}}		= ();

        #
        # cache fields will be populated on setSiteValues
        # but in case we need a ph before then
        #
        %{$self->{'dataCacheFields'}}           = ();
        %{$self->{'plugins'}}           = ();

        #
        # this will store the currently logged in userHash
        #
        %{$self->{'profileHash'}}               = ();
        
	#
        # For plugin added, and cached elementHashes lets predefine this
        #
        %{$self->{'elementHash'}}               = ();


        #
        # set this to false, it might be turned on at any time by admin or elements
        #
        $self->{'tinyMCEEnable'}                = 0;


        #
        # core database schema
        #
        @{$self->{'dataSchema'}} = (
                "queue_history","guid"                  ,"char(36)"     ,"MUL"          ,"",
                "queue_history","site_guid"             ,"char(36)"     ,"MUL"          ,"",
                "queue_history","created_date"          ,"datetime"     ,""             ,"0000-00-00",
                "queue_history","queue_guid"            ,"char(36)"     ,"MUL"          ,"",
                "queue_history","profile_guid"          ,"char(36)"     ,"MUL"          ,"",
                "queue_history","directory_guid"        ,"char(36)"     ,"MUL"          ,"",
                "queue_history","type"                  ,"char(50)"     ,"MUL"          ,"",
                "queue_history","queue_from"            ,"char(255)"    ,"MUL"          ,"",
                "queue_history","from_name"             ,"char(255)"    ,""             ,"",
                "queue_history","queue_to"              ,"char(255)"    ,"MUL"          ,"",
                "queue_history","subject"               ,"char(255)"    ,""             ,"",
                "queue_history","success"               ,"int(1)"       ,""             ,"0",
                "queue_history","synced"                ,"int(1)"       ,""             ,"0",
                "queue_history","body"                  ,"text"         ,""             ,"",
                "queue_history","hash"                  ,"text"         ,""             ,"",
                "queue_history","failure_code"          ,"char(255)"    ,""             ,"",
                "queue_history","response"              ,"char(255)"    ,""             ,"",
                "queue_history","sent_date"             ,"datetime"     ,""             ,"0000-00-00 00:00:00",
                "queue_history","scheduled_date"        ,"datetime"     ,""             ,"0000-00-00 00:00:00",


                "queue","guid"                          ,"char(36)"     ,"MUL"          ,"",
                "queue","site_guid"                     ,"char(36)"     ,"MUL"          ,"",
                "queue","created_date"                  ,"datetime"     ,""             ,"0000-00-00",
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
                "events","date_to"                      ,"datetime"     ,"MUL"          ,"0000-00-00",
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
                "deal","date_to"                        ,"datetime"     ,"MUL"          ,"0000-00-00",
                "deal","date_use_by"                    ,"datetime"     ,"MUL"          ,"0000-00-00",
                "deal","description"                    ,"text"         ,"FULLTEXT"     ,"",
                "deal","fine_print"                     ,"text"         ,"FULLTEXT"     ,"",
                "deal","image_1"                        ,"char(255)"    ,""             ,"",
                "deal","directory_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "deal","profile_guid"                   ,"char(36)"     ,"MUL"          ,"",
                "deal","extra_value"                    ,"text"         ,""             ,"",

                "directory","site_guid"                 ,"char(36)"     ,"MUL"          ,"",
                "directory","guid"                      ,"char(36)"     ,"MUL"          ,"",
                "directory","pin"                       ,"char(6)"      ,"MUL"          ,"",
                "directory","created_date"              ,"datetime"     ,""             ,"0000-00-00",
                "directory","active"                    ,"int(1)"       ,"MUL"          ,"0",
                "directory","url"                       ,"char(255)"    ,"MUL"          ,"",
                "directory","name"                      ,"char(255)"    ,"FULLTEXT"     ,"",
                "directory","video_1"                   ,"char(255)"    ,""             ,"",
                "directory","video_2"                   ,"char(255)"    ,""             ,"",
                "directory","image_1"                   ,"char(255)"    ,""             ,"",
                "directory","image_2"                   ,"char(255)"    ,""             ,"",
                "directory","image_3"                   ,"char(255)"    ,""             ,"",
                "directory","image_4"                   ,"char(255)"    ,""             ,"",
                "directory","image_5"                   ,"char(255)"    ,""             ,"",
                "directory","category_1"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_2"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_3"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_4"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_5"                ,"char(255)"    ,"MUL"          ,"",
                "directory","category_6"                ,"char(255)"    ,"MUL"          ,"",
                "directory","address"                   ,"char(255)"    ,""             ,"",
                "directory","full_address"              ,"char(255)"    ,""             ,"",
                "directory","coupon_array"              ,"text"         ,""             ,"",
                "directory","deal_array"                ,"text"         ,""             ,"",
                "directory","address2"                  ,"char(255)"    ,""             ,"",
                "directory","phone"                     ,"char(20)"     ,""             ,"",
                "directory","website"                   ,"char(255)"    ,""             ,"",
                "directory","cost_rating"               ,"float"        ,""             ,"0",
                "directory","cost_rating_count"         ,"int(11)"      ,""             ,"0",
                "directory","rating"                    ,"float"        ,""             ,"0",
                "directory","rating_count"              ,"int(11)"      ,""             ,"0",
                "directory","city"                      ,"char(255)"    ,"MUL"          ,"",
                "directory","state"                     ,"char(255)"    ,"MUL"          ,"",
                "directory","zip"                       ,"char(255)"    ,"MUL"          ,"",
                "directory","country"                   ,"char(255)"    ,""             ,"",
                "directory","facebook_id"               ,"char(255)"    ,""             ,"",
                "directory","twitter_id"                ,"char(255)"    ,""             ,"",
                "directory","email"                     ,"char(255)"    ,""             ,"",
                "directory","description"               ,"text"         ,"FULLTEXT"     ,"",
                "directory","latitude"                  ,"float"        ,"MUL"          ,"0",
                "directory","longitude"                 ,"float"        ,"MUL"          ,"0",
                "directory","level"                     ,"int(3)"       ,"MUL"          ,"0",
                "directory","charity"                   ,"int(1)"       ,"MUL"          ,"0",
                "directory","claimed"                   ,"int(1)"       ,"MUL"          ,"0",
                "directory","claimed_profile_guid"      ,"char(36)"     ,"MUL"          ,"",
                "directory","claimed_validator_guid"    ,"char(36)"     ,"MUL"          ,"",
                "directory","extra_value"               ,"text"         ,""             ,"",

                "topic","site_guid"                     ,"char(36)"     ,"MUL"          ,"",
                "topic","guid"                          ,"char(36)"     ,"MUL"          ,"",
                "topic","created_date"                  ,"datetime"     ,""             ,"0000-00-00",
                "topic","name"                          ,"char(255)"    ,"MUL"          ,"",
                "topic","title"                         ,"char(255)"    ,"MUL"          ,"",
                "topic","tags"                          ,"char(255)"    ,"MUL"          ,"",
                "topic","description"                   ,"text"         ,"FULLTEXT"     ,"",
                "topic","content"                       ,"text"         ,"FULLTEXT"     ,"",
                "topic","content_1"                     ,"text"         ,"FULLTEXT"     ,"",
                "topic","content_2"                     ,"text"         ,"FULLTEXT"     ,"",
                "topic","fb_content"                    ,"text"         ,"FULLTEXT"     ,"",
                "topic","twitter_content"               ,"text"         ,"FULLTEXT"     ,"",
                "topic","directory_guid"                ,"char(36)"     ,"MUL"          ,"",
                "topic","active"                        ,"int(1)"       ,"MUL"          ,"0",
                "topic","draft"                         ,"int(1)"       ,"MUL"          ,"0",
                "topic","url"                           ,"char(255)"    ,""             ,"",
                "topic","image_1"                       ,"char(255)"    ,""             ,"",
                "topic","date_to"                       ,"date",        ,"MUL"          ,"0000-00-00",
                "topic","date_from"                     ,"date",        ,"MUL"          ,"0000-00-00",
                "topic","extra_value"                   ,"text"         ,""             ,"",

                "auto","make"                           ,"char(255)"    ,"MUL"          ,"",
                "auto","model"                          ,"char(255)"    ,"MUL"          ,"",
                "auto","year"                           ,"char(4)"      ,"MUL"          ,"",

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
                "data_cache","name"                     ,"char(255)"    ,"FULLTEXT"     ,"",
                "data_cache","title"                    ,"char(255)"    ,"FULLTEXT"     ,"",
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
                "admin_user","name"                     ,"char(255)"    ,""             ,"",
                "admin_user","email"                    ,"char(255)"    ,""             ,"",
                "admin_user","admin_user_password"      ,"char(50)"     ,"MUL"          ,"",
                "admin_user","active"                   ,"int(1)"       ,"MUL"          ,"1",
                "admin_user","extra_value"              ,"text"         ,""             ,"",

                "profile_groups_xref","site_guid"       ,"char(36)"     ,"MUL"          ,"",
                "profile_groups_xref","profile_guid"    ,"char(36)"     ,"MUL"          ,"",
                "profile_groups_xref","groups_guid"     ,"char(36)"     ,"MUL"          ,"",

                "profile","site_guid"                   ,"char(36)"     ,"MUL"          ,"",
                "profile","guid"                        ,"char(36)"     ,"MUL"          ,"",
                "profile","pin"                         ,"char(6)"      ,"MUL"          ,"",
                "profile","profile_password"            ,"char(255)"    ,""             ,"",
                "profile","fb_access_token"             ,"char(255)"    ,""             ,"",
                "profile","fb_id"                       ,"char(255)"    ,""             ,"",
                "profile","email"                       ,"char(255)"    ,"MUL"          ,"",
                "profile","name"                        ,"char(255)"    ,""             ,"",
                "profile","active"                      ,"int(1)"       ,""             ,"1",
                "profile","google_id"                   ,"char(255)"    ,""             ,"",
                "profile","extra_value"                 ,"text"         ,""             ,"",

                "cart","site_guid"                      ,"char(36)"     ,"MUL"          ,"",
                "cart","guid"                           ,"char(36)"     ,"MUL"          ,"",
                "cart","name"                           ,"char(255)"    ,""             ,"",
                "cart","qty"                            ,"int(11)"      ,""             ,"0",
                "cart","data_guid"                      ,"char(36)"     ,""             ,"",
                "cart","session"                        ,"char(32)"     ,""             ,"",
                "cart","created_date"                   ,"datetime"     ,""             ,"0000-00-00",
                "cart","price"                          ,"double"       ,""             ,"0",
                "cart","sku"                            ,"char(50)"     ,""               ,"",
                "cart","extra_value"                    ,"text"         ,""             ,"",

                "fws_sessions","site_guid"              ,"char(36)"     ,"MUL"          ,"",
                "fws_sessions","ip"                     ,"char(50)"     ,"MUL"          ,"",
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
                "element","schema_devel"                ,'text',        ""              ,"",
                "element","schema_live"                 ,'text',        ""              ,"",

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
                "site","css_devel"                      ,"int(1)"       ,""             ,"0",
                "site","css_live"                       ,"int(1)"       ,""             ,"0",
                "site","default_site"                   ,"int(1)"       ,""             ,"0",
                "site","extra_value"                    ,"text"         ,""             ,"",

                "coupon","site_guid"                    ,"char(36)"     ,"MUL"          ,"",
                "coupon","created_date"                 ,"datetime"     ,""             ,"0000-00-00",
                "coupon","name"                         ,"char(255)"    ,"MUL"          ,"",
                "coupon","date_to"                      ,"date",        ,"MUL"          ,"0000-00-00",
                "coupon","date_from"                    ,"date",        ,"MUL"          ,"0000-00-00",
                "coupon","persistent"                   ,"int(1)",      ,"MUL"          ,"0",
                "coupon","type"                         ,"char(1)"      ,"MUL"          ,"f",
                "coupon","amount"                       ,"double"       ,""             ,"0",
                "coupon","code"                         ,"char(255)"    ,"MUL"          ,"",
                "coupon","guid"                         ,"char(36)"     ,"MUL"          ,"",
		);

        return $self;
}


############### END HIDE #################### Web optimized import block flag

=head1 FWS PLUGINS

=head2 registerPlugin

If server wide plugins are being added for this instance they will be under the FWS::V2 Namespace, if not they can be added just as the plugin name.

	#
	# register plugins that are available server wide 
	#
        $fws->registerPlugin('FWS::V2::SomePlugin');
	
	#
	# register some plugin added via the FWS 2.1 Plugin manager
        #
	$fws->registerPlugin('somePlugin');

=cut

sub registerPlugin {
        my ($self, $plugin) = @_;

        eval 'use lib "'.$self->{'fileSecurePath'}.'/plugins";';
        
	#
        # get the plugin name if it is a server wide plugin
        #
        my $pluginName = $plugin;
        $pluginName =~ s/.*:://sg;

        #
        # add the plugin and register the init for it
        #
        eval 'use '.$plugin.';';

        if($@){ $self->FWSLog($plugin." could not be loaded\n".$@) }

        eval $plugin.'->pluginInit($self);';
        
	if($@){ $self->FWSLog($plugin." pluginInit failed\n".$@) }
	else { $self->{plugins}->{$plugin} = 1 }
}


=head1 WEB BASED RENDERING SEQUENCE

With the full web optimized version of FWS, the following sequence can be executed in this order to render web based content after new() is called:

	#
	# Get the form values from the environment
	#
	$fws->getFormValues();
	
	#
	# 404 page descisions
	#
	$fws->setSiteFriendly();
	
	#
	# run any site specific init scripts
	#
	$fws->runInit();
	
	#
	# get or set the session ID and restore retained information
	#
	$fws->setSession();
	
	#
	# set site values based on what we know now
	#
	$fws->setSiteValues();

	#
	# Do login procedures and set permissions
	#
	$fws->processLogin();
	
	#
	# Download files procedures if we are here to send a file
	#
	$fws->processDownloads();
	
	#
	# Run site actions that don't require security to use
	#
	$fws->runSiteActions();
	
	#
	# Run admin actions that require security to access
	#
	$fws->runAdminAction();
	
	#
	# Display the content we just created to the browser
	#
	$fws->displayContent();

NOTE: At this time, all required methods are not available for web based rendering in this distrubution.

=cut

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
