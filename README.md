[![Click here to lend your support to: Capistrano Exts and make a donation at www.pledgie.com](http://www.pledgie.com/campaigns/16060.png?skin_name=chrome)](http://www.pledgie.com/campaigns/16060)

# Capistrano Exts [![Build Status](http://travis-ci.org/TechnoGate/capistrano-exts.png)](http://travis-ci.org/TechnoGate/capistrano-exts)

Capistrano exts is a set of helper tasks to help with the initial server
configuration and application provisioning. Things like creating the directory
structure, setting up that database, and other one-off you might find yourself
doing by hand far too often. It provides many helpful post-deployment tasks to
help you import/export database and contents as well as sync one stage with
another.

# Installation

Install the gem

```ruby
gem install capistrano-exts
```

or add it to your Gemfile

```ruby
gem 'capistrano-exts', '>=1.13.2', :require => false
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
# Valid extensions: :multistage, :git, :mysql, :rails, :contao, :contents, :god, :unicorn, :servers
set :capistrano_extensions, [:multistage, :git, :mysql, :rails, :servers]
```

Then run the command

```bash
$ cap multistage:setup
```

This command will create default configuration files in the folder
__config/deploy__, one configuration file for each stage you defined above,
before deploying the project to a stage you should carefully edit the
configuration files.

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
in the configuration file of the stage.


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

### Sync

Capistrano exts has special tasks defined under the **multistage** namespace
for syncing one stage with another, and the tasks are generate on runtime
depending on the stages you have defined, for example, if you have a staging
and a production stage, you can develop your application on the staging area
and then sync one or both of the database and contents of the production stage
with those of staging like so:

Sync the database only

```bash
$ cap multistage:sync:production_database_with_staging
```

Sync the contents only

```bash
$ cap multistage:sync:production_contents_with_staging
```

Sync both

```bash
$ cap multistage:sync:production_with_staging
```

# License

## This code is free to use under the terms of the MIT license.

Copyright (c) 2011 Wael Nasreddine <wael.nasreddine@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.