# Capistrano Extensions [![Build Status](http://travis-ci.org/TechnoGate/capistrano-exts.png)](http://travis-ci.org/TechnoGate/capistrano-exts)

capistrano-exts is a set of helper tasks to help with the initial server
configuration and application provisioning. Things like creating the directory
structure, setting up that database, and other one-off you might find yourself
doing by hand far too often.

# Installation

Install the gem

```ruby
gem install capistrano-exts
```

or add it to your Gemfile

```ruby
gem 'capistrano-exts', '>=1.8.2', :require => false
```

# Setup

First make sure you have capified your project, if not then run the following
command on the root of your project:

```bash
$ capify .
```

Then open up __config/deploy.rb__ and add the following to the top of the file

```ruby
# Stages
# Stages can be really anything you want
set :stages, [:development, :staging, :production]
set :default_stage, :development

# Capistrano extensions
# Valid extensions: :multistage, :git, :deploy, :mysql, :rails, :contao, :contents, :god, :unicorn, :servers
set :capistrano_extensions, [:multistage, :git, :deploy, :mysql, :rails, :servers]
```

Then run the command

```bash
$ cap multistage:setup
```

This command will create default configuration files in the folder
__config/deploy__, one configuration file for each stage you defined above,
before deploying the project to a stage you should carefully edit the
configuration file.

# Usage

## Server preparation

If you have edited the config files, the mysql and web server section, then
you're ready to prepare the server using the command:

```bash
$ cap [stage] deploy:server:setup
```

You'd have to prepare the project's folder with the command:

```bash
$ cap [stage] deploy:setup
```

## Deployment

The project can be deployed with the plain old capistrano command:

```bash
$ cap [stage] deploy
```

## Post deployment

Capistrano exts provide several tasks to help with your everyday development,
like importing/exporting the database, importing/exporting the contents and
sync two stages, sync is of course one way.

### Importing the database

Assuming you're developing locally, for example using a CMS, when the project
is ready for deployment, all you have to do is

1. Dump the database locally, for this example, I'll assume
   **/tmp/project\_db\_dump.sql** is the dump of your project's database
2. Import the database into the target server using the following command

```bash
$ cap [stage] mysql:import_db_dump /tmp/project_db_dump.sql
```

### Importing the contents

You can also import the contents from your local development (or a tarball
from another server), using the command

```bash
$ cap [stage] contents:import /tmp/contents.tar.gz
```

N.B: The tarball will be extracted in **shared/shared\_contents** so you
should make sure you have the
[**contents\_folder**](https://github.com/TechnoGate/capistrano-exts/blob/master/lib/capistrano-exts/templates/multistage.rb#L54)
in the stage's deploy configuration.


### Exporting the database

If you want to export the database you can simply run

```bash
$ cap [stage] mysql:export_db_dump [sql_dump_file]
```

The **sql\_dump\_file** is of course optional, if not given a random file in
/tmp will be created.

### Exporting the contents

If you want to export the contents you can simply run

```bash
$ cap [stage] mysql:export_db_dump [contents_file]
```

The **contents\_file** is of course optional, if not given a random file in
/tmp will be created.


# License
This code is free to use under the terms of the MIT license.
