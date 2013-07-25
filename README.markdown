Rack::Zip
=========

Rack::Zip is a Rack application which serves files in ZIP archives.

Installation
------------

This library is currently not on rubygems.org because I think the name "Rack::Zip" is not good.
See "Request for comments" section of this file for details.

    $ git clone https://github.com/KitaitiMakoto/rack-zip.git
    $ cd rack-zip
    $ gem build rack-zip.gemspec
    $ gem install ./rack-zip-0.0.1.gem

Usage
-----

Write below in you config.ru:

    require 'rack/zip'
    
    run Rack::Zip.new('path/to/docroot')

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

    run Rack::Zip.new('path/to/docroot', extensions: ['.epub', '.zip'])

Note that Rack::Zip doesn't serve ZIP file itself.

Request for comments
--------------------

This application is not released as a RubyGem because I need to decide appropriate gem name.

"Rack::Zip" is not a good name. It sounds like that it archives some files on machine as a ZIP file and serves it via HTTP. But it is misunderstanding.

Also, "Rack::Unzip", like Nginx's [nginx-unzip-module][], is not good. This application doesn't actually *unzip* files.

Is "Rack::FilesInZip" good? It is correct but not cool.

If you have some idea about the name of this application, please tell me as an [issue][].

[nginx-unzip-module]: https://github.com/youzee/nginx-unzip-module
[issue]: https://github.com/KitaitiMakoto/rack-zip/issues
