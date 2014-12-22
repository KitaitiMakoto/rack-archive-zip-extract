CHANGELOG
=========

0.0.7
-----

* Require Rack >= 1.6

0.0.6
-----

* Make Content-Type header customizable

0.0.5
-----

* [BUG FIX]Duplicate extensions before freezing
* Send ETag header

0.0.4
-----

* Change method name `extract_content` -> `extract_file`
* [BUG FIX]Close body when content not modified
* Make buffer size for reading file in zip archive configuable

0.0.3
-----

* Chunk content body and use buffer rather than read body at a time

0.0.2
-----

* Use mtime of file in archive for Last-Modified header
* Don't read file body from zip archive when file is older than If-Modified-Since header

0.0.1
-----

* Initial release
