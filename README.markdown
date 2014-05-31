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

*Note that Rack::Archive::Zip::Extract doesn't serve ZIP file itself.*

### File extensions

By default, files with extension ".zip" is recognized as ZIP files.
You can tell the app extensions by option argument:

    run Rack::Archive::Zip::Extract.new('path/to/docroot', extensions: ['.epub', '.zip'])

### Mime types

By default, Rack::Archive::Zip::Extract uses [`Rack::Mime::MIME_TYPES`][mime_types] as a mime type table. You can add and/or update mime type settings by passing hash table to initializer:

    run Rack::Archive::Zip::Extract.new('path/to/docroot', mime_types: {'.html' => 'application/xhtml+xml', '.apk => 'application/vnd.android.package-archive'})

In example above, Rack::Archive::Zip::Example sends "`Content-Type: application/xhtml+xml`" header for access to path with extension "`.html`" instead of "`text/html`" and "`application/vnd.android.package-archive`" for "`*.apk`" instead of default "`application/octet-stream`".

[mime_types]: http://rack.rubyforge.org/doc/Rack/Mime.html#MIME_TYPES

### Buffer size

Buffer size for reading file in zip archive is set to {Rack::Archive::Zip::Extract::ExtractedFile::BUFFER_SIZE 8192} bytes by default.

You can change it by passing `buffer_size` named argument when initailizig the app:

    run Rack::Archive::Zip::Extract.new('path/to/docroot', buffer_size: 1024 * 1024)

License
-------

This program is distribuetd under the term of the MIT License. See MIT-LICENSE file for more info.
