
AIR2
====

> An open source Audience Insight Repository

> Copyright (c) 2010 - 2012, American Public Media

--------

So you're ready to make AIR2 your own then, huh?  Well, you've come to the right place.


1. Directory Structure
----------------------

AIR2 is built primarily as a CodeIgniter stack, and you'll see that reflected in the application layout.

### app/

The primary AIR2 framework code.  Primarily PHP.  There's so much stuff in here, it warrants breaking it down.

* **app/api/** - home of the Rframe API, the building blocks of AIR2. Many resource requests will get routed here instead of going to the controllers directory. See the Libraries section for more info.
* **app/config/** - mostly CodeIgniter configuration, but there are some mystical AIR2-specific files, like environment constants in `air2_constants.php`, and authorization configurations in `actions.ini` and `roles.ini`.
* **app/controllers/** - CodeIgniter controllers, for requests that don't route directly into app/api.
* **app/errors/** - deprecated
* **app/fixtures/** - yaml files containing database fixtures. Loaded via a `make db-fixtures`.
* **app/libraries/** - AIR2-specific CodeIgniter extensions and helpers.
* **app/models/** - Doctrine models - read more in the Libraries section.
* **app/views/** - Views rendered by AIR2. Since this is mostly a javascript-driven application, there's actually very little markup to be found here. Additionally, most application pages just render some json into `app/views/html.php`, and leave it up to the javascript to create the interface.

### assets/

This directory is not in svn, but after running `make assets`, it is the default location of file/image assets that AIR2 may use.  (Unless you customized those directories in your profile).

### bin/

Executable scripts

### client/

3rd-party (non-AIR2-interface) clients for the AIR2 API.

### cron/

Examples of cron setups, to maintain the health of AIR2.

### doc/

Location of documentation, built by a `make docs` command.  This is all stored in xml docbook format.  Also contains some schema information.

### etc/

AIR2 site-specific configuration files, most notably `profiles.ini`.

### lib/

Server side external libraries and customizations for AIR2.  The base directory contains some util classes, and some Doctrine overridden classes.

* **lib/codeigniter/** - home of CodeIgniter source
* **lib/dbconv/** - 1-off database conversion/cleanup scripts
* **lib/doctrine/** - home of Doctrine source
* **lib/formbuilder/** - formbuilder perl library, to give various AIR importer/exporter scripts access to formbuilder database/stuff
* **lib/lyris/** - lyris perl library, to give various AIR importer/exporter scripts access to lyris database-cache/API stuff
* **lib/mover/** - PHP helpers for quickly moving data in and out of mysql (TODO: is this deprecated?)
* **lib/perl/** - the Perl side of AIR (TODO: elaborate)
* **lib/phperl/** - middle-ware for calling perl routines from PHP code
* **lib/querybuilder/** - future home of the querybuilder lib
* **lib/rframe/** - API framework used in app/api.  Also contains some custom AIR extensions of the lib.
* **lib/shared/** - shared PIN libs/files/things
* **lib/tank/** - deprecated

### public_html/

Web root directory, containing all sorts of fun css/js.

* **public_html/css/** - Css files, organized mostly by view.  And static image assets.
* **public_html/files/** - Static files
* **public_html/img/** - symlink created to your uploaded-image directory after the `make assets` command is run
* **public_html/js/** - heirarchically organized javascript files, reminiscent of a poor mans object oriented language
* **public_html/lib/** - javascript libraries (notably ExtJS)

### report/

1-off reporting scripts

### schema/

TAP (test-anything-protocol) scripts to validate/fix your database schema.  Run with the `make schema` command.

### tests/

TAP (test-anything-protocol) unit tests for AIR2.  Run with the `make test` command.

### var/

Not used yet, apparently.


2. Libraries
------------

### CodeIgniter 1.7.2

AIR2 is mainly a CodeIgniter app, with some customization.  First and foremost, we put the CodeIgniter lib in `lib/codeigniter`, and just made sure that `app/init.php` knows where to find it.  This way, if we ever wanted to, we could swap out CodeIgniter for a newer version with minimal hassle.

There are also a bunch of overridden base classes, located in `app/libraries`.  The default CI-router has been overridden to be RESTful when dealing with API routes.  (That's why the routes in `app/config/routes.php` looks different than a default CI-setup).  Some of the CI error handling is also customized, and there are various CI-helpers in this directory (they look like `AirSomething`).  And there are several AIR-flavors of controllers, including:

* `Base_Controller` provides some generic, useful extensions to a regular CI controller
* `AIR2_Controller` to provide basic AIR security
* `AIR2_APIController` for translating routes to rframe resources in `app/api`
* `AIR2_HTMLController` gives a generic way to represent API routes as an html view

AIR also does some interesting things with `app/views/`.  Instead of the normal CI way of rendering markup in views, AIR tends to let the javascript layer render most of the actual markup.  And the views mainly represent different content types.  For instance, if you requested `air2/project/1234.html`, the view `app/views/html.php` would be rendered.  And `air2/project/1234.json` would render `app/views/json.php`.  For a list of format to view mappings, see `app/config/config/formats.php`.

### Doctrine 1.2.1

Doctrine usage is pretty much out-of-the-box, with a few minor customizations in `lib/AIR2_Record`, `lib/AIR2_Query` and `lib/AIR2_Table`.  Models are all stored in `app/models/`.

Authorization in AIR2 is mainly computed at the model level.  If you look in most models, you'll see several `user_may_something()` and `query_may_something()` methods.  Passing in a `User` record to these models, they'll tell you whether or not that user can read/write/manage/delete the record.  (Note that these are not CRUD operations, and have very business-rule-specific meanings).  Instead of returing a boolean value, `query_may_something()` methods will apply a where-condition to a Doctrine_Query, in order to only return database results that the user can read/write/manage.


### ExtJS 3.2.1

At the center of the AIR2 UI is good ol' ExtJS.  We have sort of a non-standard usage of Ext, as we don't really use it to control the page layout.  Instead, AIR2 has some customized css/markup to give it a panel-y feel.  Almost everything you see in the interface is driven off Ext DataViews.  Record Stores are used to hold json from the AIR API, and perform restful actions on that data.  The higher-level Ext customizations used by AIR are all in `public_html/js/ui/`.


3. Naming Conventions
---------------------

#### `app/libraries/`

This directory contains CodeIgniter libraries. Those named "AIR2_" are subclasses of CodeIgniter classes (controller, exception, etc), and MUST be named with the prefix to satisfy CodeIgniter.  (See ./app/config/config.php, the "Class Extension Prefix" section).  Other non-CodeIgniter AIR-specific library classes are prefixed with "Air", and must have the same classname as the filename.  Additionally, they should contain a first line to prevent direct script access.

#### `app/controllers/`

This directory contains AIR2 Controllers, extending the AIR2_Controller (which implements security).  These names start with the name of the URL through which they are accessed, followed by "_controller.php".  For example: the url "http://something.org/air2/search" --> "search_controller.php".

#### `app/fixtures/`

This directory (and subdirectories) contain Doctrine fixture files that load static data into the database of AIR2 at install time.  They must be named to match Doctrine model classes, with 1 exception.  The "User" model is in the file "0User.yml" to make sure it is loaded FIRST, so that the AIR2 System User (id = 1) will exist when other fixtures are loaded.

#### `app/models/`

This directory contains Doctrine models.  They are named with the same filename as classname, and are a camel-case version of the tablename with underscores removed.  For instance, the database table "foo_bar" would use the filename
(and classname) "FooBar.php".

#### `lib`

This directory contains application-wide libraries. AIR2-specific libs are prefixed with AIR2_ and shared libs are named according to the class name they represent.

#### `app/api`

These API resources should be structured hierarchically, according to where they show up in the URL structure.  Filenames should simply be the name of the resource.  But classnames must be a complete path (unique), separated by underscores, since PHP 5.2 doesn't provide namespacing.


4. Make targets
---------------

Here are some of the more important make targets:

* `make install` - create the database and assets, load database fixtures, compress javascript, and check perl dependencies
* `make clean` - drop the database and assets
* `make reload` - reload the database and assets from production (takes awhile)
* `make schema` - check/update the database schema
* `make test` - run the unit tests

And a few other useful ones:

* `make js` - compress javascript and create some json-fixtures from database
* `make search` - build search indexes (takes many, many hours)
* `make db` - create the database
* `make assets` - create the assets folder
* `make db-reload` - reload the database from a prod backup
* `make assets-reload` - rsync the assets from prod


5. Cron Jobs
------------

A healthy AIR installation requires some crons.  An example crontab can be found in `cron/crontab-example`.  Basically, the jobs fall into these categories:

* Search updates - keep the search indexes in-sync with the mysql database
* Job queue - run jobs that AIR has scheduled in the job_queue table
* Lyris-IO - run importers/exporters between AIR and Lyris
* Formbuilder-IO - run importers/exporters between AIR and Formbuilder
* Budgethero-IO - run importers/exporters between AIR and Budgethero
* Infrequent tasks - run bash scripts found in `cron/` (daily, monthtly, quarterly)


6. Unit Tests
-------------

Unit tests are intended to cover the server-side functionality of AIR.  This includes testing libraries, controllers, api-calls, importers/exporters, and bin scripts.  Front-end testing (rendering stuff with ExtJS) is currently beyond the scope of these tests.  The closest they get is testing the inline-JSON that gets rendered by `app/views/html.php`.
