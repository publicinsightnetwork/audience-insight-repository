AIR2
====

> An open source Audience Insight Repository

> Copyright (c) 2010 - 2013, American Public Media Group

--------


Overview
--------

AIR2 (the **Audience Insight Repository**, version 2) serves as the analyst-facing component and primary infrastructure for a system supporting interactions between specialized analysts (AIR2 Users) and a larger audience of people (AIR2 Sources).

AIR2 was designed to be a reporters notebook, facilitating the searching, annotating, grouping and contacting of Sources.  It also serves as a storage hub for tracking and searching journalistic work product, including information submitted by the Source (Submissions), and stories the Source has been involved in (Outcomes).

AIR2 also provides an organizational heirarchy for its users, to establish authorization rules around Sources and Submissions.  Users across organinizations are able to collaborate via shared projects.

In addition to the AIR2 application functionality, the AIR2 API is designed to be extremely modular, supporting the possible use of any number of plugins.  Examples of possible plugins include form-generating software, audience-facing data gathering applications, email consumers, social media consumers, and transcription services, to name a few.


System Requirements
-------------------

AIR2 runs on a standard LAMP stack, with a little bit of Perl to spice things up.

* Unix-flavored OS (Linux or OSX are your best bet)
* Apache 2
* MySQL 5
* PHP 5
* Perl 5


Installation
------------

To install AIR2, place the code somewhere in your Unix filesystem.  Then create a symlink from your webserver's DocumentRoot directory to `public_html`.

    ln -s ~/code/AIR2/public_html /var/www/air2

Then create a mysql database and user for your AIR2 application to use.

    mysql> CREATE DATABASE air2;
    mysql> GRANT ALL PRIVILEGES ON air2.* TO "air2user"@"localhost" IDENTIFIED BY "air2isthegreatest";
    mysql> FLUSH PRIVILEGES;

Copy the example config file to customize for your environment.

    cp etc/profiles.ini.example etc/profiles.ini

Create a profile for yourself in `etc/profiles.ini`, filling in your connection info.  There's a whole bunch more stuff you can put in here... see `app/config/air2_constants.php` for a list of them and their default values.

    [my_server_name]
    hostname = localhost
    username = air2user
    password = air2isthegreatest
    dbname   = air2
    driver   = mysql
    server_time_zone = America/Chicago

Then tell AIR2 which server to use by putting the name of your profile in `etc/my_profile`.

    echo "my_server_name" > etc/my_profile

Now setup the database, fixtures, and assets.  This will also check your installed Perl modules, and determine what you're lacking.

    make install
    # lots of things happen here...

    cd lib/perl
    cpan -i Module::Install
    perl Makefile.PL
    # missing dependencies will be identified, install them from CPAN

Contact
-------

For more information, visit <http://www.publicinsightnetwork.org>, or contact <support@publicinsightnetwork.org>.


License
-------

AIR2 is an Open Source application licensed under the GNU GPL (General Public License) version 3.
