[![Build Status](https://travis-ci.org/HandsetDetection/ruby-apikit.svg?branch=master)](https://travis-ci.org/HandsetDetection/ruby-apikit)
[![Gem Version](https://badge.fury.io/rb/handset_detection.svg)](https://badge.fury.io/rb/handset_detection)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Ruby API Kit v4.0, implementing v4.0 of the HandsetDetection API. #

API Kits can use our web service or resolve detections locally 
depending on your configuration.


## Installation ##

	gem install 'handset_detection'

For Ruby on Rails apps, or any other application that uses Bundler, add this line to your `Gemfile`:

	gem 'handset_detection'

## Configuration ##

API Kit configuration files can be downloaded directly from Handset Detection.

1. Login to your dashboard
2. Click 'Add a Site'
3. Configure your new site
4. Grab the config file variables for your API Kit (from the site settings)
5. Place the variables into the `hdconfig.yml` file
6. If you use Ruby on Rails, place `hdconfig.yml` in your `config` folder.


## Examples ##

### Instantiate the HD4 object ###

    # Using the default config file
    require 'handset_detection'
    hd = HD4.new

OR

    # Using a custom config file
    require 'handset_detection'
    hd = HD4.new '/tmp/my_custom_config_file.yml'

### List all vendors ###

    if hd.device_vendors
      data = hd.get_reply
      p data
    else
      p hd.get_error
    end

### List all device models for a vendor (Nokia) ###

    if hd.device_models 'Nokia'
      data = hd.get_reply
      p data
    else
      p hd.get_error
    end

### View information for a specific device (Nokia N95) ###

    if hd.device_view 'Nokia', 'N95'
      data = hd.get_reply
      p data
    else
      p hd.get_error
    end

### What devices have this attribute ? ###

    if hd.device_what_has 'network','CDMA'
      data = hd.get_reply
      p data
    else
      p hd.get_error
    end

### Device detection ###

    hd.set_detect_var 'user-agent', 'Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 NokiaN95-3/20.2.011 Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413'
    hd.set_detect_var 'x-wap-profile', 'http://nds1.nds.nokia.com/uaprof/NN95-1r100.xml'
    if hd.device_detect
      data = hd.get_reply
      p data
    else
      p hd.get_error
    end

### Detect your website visitor's device ###

Invoke `hd.set_server_headers` with your web server's `HTTP_*` environment variables.

Using Ruby on Rails:

	hd.set_server_headers request.env

This is a Ruby on Rails controller that will detect the visitor's device, and simply display the detection results:

	require 'handset_detection'

	class DemoController < ApplicationController
	  def index
	    hd = HD4.new
	    hd.set_server_headers request.env
	    if hd.device_detect
	      render :plain => hd.get_reply
	    else
	      render :plain => hd.get_error
	    end
	  end
	end

### Download the Full Ultimate Edition ###

Note : Increase the default timeout before downloading the archive.

    hd.set_timeout 500
    if hd.device_fetch_archive
      data = hd.get_raw_reply
      puts "Downloaded #{data.length} bytes"
    else
      p hd.get_error
      p hd.get_raw_reply
    end

### Download the Community Ultimate Edition ###

    hd.set_timeout 500
    if hd.community_fetch_archive
      data = hd.get_raw_reply
      puts "Downloaded #{data.length} bytes"
    else
      p hd.get_error
      p hd.get_raw_reply
    end

## Flexible Caching Options

Version 4.1.\* includes file-based, Memcached and Rails (ActiveSupport) caching options.

### Using Memcached

This is an example cache configuration that you can insert in your config file:

	cache: { memcached: { 
	  servers: [ 'localhost:11211' ], 
	  options: { value_max_bytes: 4000000 }
	}}

See https://github.com/petergoldstein/dalli#configuration for other options that you can set.

### Using Ruby on Rails

If you don't specify any cache options, Handset Detection will detect that you use Rails and it will utilize the Rails cache.

To explicitly ask for the Rails cache, you can set:

	cache: { rails: true }

### Using the filesystem

To use your filesystem as the cache backend, you can use this configuration:

	cache: { file: { directory: /tmp }}

### Using in-memory cache

The in-memory cache is useful when running batch jobs.

	cache: { memory: {}}

If running on multiple threads, you can use the `thread_safe` option:

	cache: { memory: { thread_safe: true }}

## Extra Examples ##

Additional examples can be found in the examples.rb file.


## Getting Started with the Free usage tier and Community Edition ##

After signing up with our service you'll be on a free usage tier which entitles you to 20,000 Cloud detections (web service)
per month, and access to our Community Edition for Ultimate (stand alone) detection. The archive for stand alone detection
can be downloaded manually however its easiest to configure the API kit with your credentials and let the API kit do the
heavy lifting for you. See examples above for how to do this.

Instructions for manually installing the archive are available at [v4 API Ultimate Community Edition, Getting Started](https://handsetdetection.readme.io/docs/getting-started-with-ultimate-community-full-editions)


## Unit testing ##

Unit tests use minitest and can be found in the test directory.

	rake test


## API Documentation ##

See the [v4 API Documentation](https://handsetdetection.readme.io).


## API Kits ##

See the [Handset Detection GitHub Repo](https://github.com/HandsetDetection).


## Support ##

Let us know if you have any hassles (hello@handsetdetection.com).
