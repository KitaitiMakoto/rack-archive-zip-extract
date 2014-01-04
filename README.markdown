Rack::Archive::Zip::Extract
===========================

Rack::Archive::Zip::Extract is a Rack application which serves files in ZIP archives.

Installation
------------

    $ gem install rack-archive-zip-extract

Or add this line to your application's Gemfile:

    $ gem 'rack-archive-zip-extract', :require => 'rack/archive/zip/extract'

And then execute:

    $ bundle install

Usage
-----

Write below in your config.ru:

    require 'rack/archive/zip/extract'
    
    run Rack::Archive::Zip::Extract.new('path/to/docroot')

`'path/to/docroot'` above should have some ZIP files like this:

    $ tree path/to/docroot
    some.zip
    another.zip
    andmore.zip

Then, run server:

    $ rackup

Now you can see files in zip archives. For example, visit http://localhost:9292/some/inner-file.txt and then you can see the text in "inner-file.txt" file in "some.zip" archive file.

By default, files with extension ".zip" is recognized as ZIP files.
You can tell the app extensions by option argument:

    run Rack::Archive::Zip::Extract.new('path/to/docroot', extensions: ['.epub', '.zip'])

Note that Rack::Archive::Zip::Extract doesn't serve ZIP file itself.

License
-------

This program is distribuetd under the term of the MIT License. See MIT-LICENSE file for more info.
