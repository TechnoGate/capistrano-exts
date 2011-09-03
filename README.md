Capistrano Extensions [![Build Status](http://travis-ci.org/TechnoGate/capistrano-exts.png)](http://travis-ci.org/TechnoGate/capistrano-exts)
=====
This gem provides some useful capistrano tasks, for preparing the server,
the database and the application without ever SSH'ing to the destination server,
it also provides multistage functionality just like [capistano-ext](https://github.com/capistrano/capistrano-ext)
gem, in fact the included multistage file is a modified version of capistrano-ext

Installation
------------

Install the gem

```ruby
gem install capistrano-exts
```

or add it to your Gemfile

```ruby
gem 'capistrano-exts', '>=1.0.0'
```

Setup
-----
First make sure you have capified your project, if not then run the following command on the root of your project:

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
# Valid extensions: :multistage, :git, :deploy, :mysql, :rails, :contao, :god, :unicorn, :servers
set :capistrano_extensions, [:multistage, :git, :deploy, :mysql, :rails, :servers]
```

Then run the command

```bash
$ cap multistage:prepare
```

Then edit the files found at __config/deploy/*.rb__, that's it you're ready..

Usage
-----

The server can be prepared by running:

```bash
$ cap deploy:server:prepare deploy:setup
```

Deploy with

```bash
$ cap deploy
```

That's pretty much it


License
-------
This code is free to use under the terms of the MIT license.