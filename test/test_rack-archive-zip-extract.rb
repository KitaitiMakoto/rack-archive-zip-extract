require 'test/unit'
require 'test/unit/notify'
require 'rack/lint'
require 'rack/mock'
require 'rack/archive/zip/extract'

class TestRackArchiveZipExtract < Test::Unit::TestCase
  def setup
    @zip = Rack::Archive::Zip::Extract.new(__dir__)
  end

  def request(path, app=@zip, opts={})
    Rack::MockRequest.new(app).get(path, opts)
  end

  def test_request_to_file_in_zip_returns_content
    response = request('/sample/sample.txt')

    assert_equal "This is a plain text file.\n", response.body
  end

  def test_request_to_file_in_zip_returns_last_modified
    response = request('/sample/sample.txt')
    expected = File.mtime(File.join(__dir__, 'fixtures', 'sample-zip', 'sample.txt'))
    actual = Time.parse(response['Last-Modified'])

    assert_in_delta expected, actual, 2
  end

  def test_request_to_old_file_returns_not_modified
    mtime = File.mtime(File.join(__dir__, 'fixtures', 'sample-zip', 'sample.txt'))
    if_modified_since = mtime + 12
    response = request('/sample/sample.txt', @zip, {'HTTP_IF_MODIFIED_SINCE' => if_modified_since.httpdate})

    assert_equal 304, response.status
  end

  def test_request_to_old_file_returns_no_content
    mtime = File.mtime(File.join(__dir__, 'fixtures', 'sample-zip', 'sample.txt'))
    if_modified_since = mtime + 12
    response = request('/sample/sample.txt', @zip, {'HTTP_IF_MODIFIED_SINCE' => if_modified_since.httpdate})

    assert_empty response.body
  end

  class TestStatusCode < self
    data(
      'file in zip'              => [200, '/sample/sample.txt'],
      'zip file itself'          => [404, '/sample.zip'],
      'non-existent file in zip' => [404, '/sample/non-existent'],
      'file in subdirectory'     => [200, '/sample/subdir/sample.txt']
    )

    def test_status_code(data)
      status_code, path_info = data

      assert_equal status_code, request(path_info).status
    end
  end

  class TestContentType < self
    data(
      'text/plain'      => %w[.txt  text/plain],
      'text/html'       => %w[.html text/html],
      'application/xml' => %w[.xml  application/xml]
    )
    def test_content_type(data)
      extension, content_type = data
      response = request("/sample/sample#{extension}")

      assert_equal content_type, response['Content-Type']
    end
  end

  def test_extension_of_file_can_be_changed
    ext = Rack::Archive::Zip::Extract.new(__dir__, extensions: %w[.ext])
    response = request('/sample/sample.txt', ext)

    assert_equal 200, response.status
    assert_equal "This is a plain text file in sample.ext.\n", response.body
  end

  class TestMultipleExtensions < self
    def setup
      super
      @multi = Rack::Archive::Zip::Extract.new(__dir__, extensions: %w[.ext .zip])
    end

    def test_multiple_extensions_for_zip_file_can_be_specified
      response = request('/sample/sample.txt', @multi)

      assert_equal 200, response.status
      assert_equal "This is a plain text file in sample.ext.\n", response.body
    end

    def test_fallback_to_next_extension_when_file_not_exit_in_zip_archive
      response = request('/sample/sample.html', @multi)

      assert_equal 200, response.status
    end
  end

  class TestExtractedFile < self
    def setup
      @zip_path = 'test/sample.zip'
      @inner_path = 'sample.txt'
      @file = Rack::Archive::Zip::Extract::ExtractedFile.new(Zip::Archive.open(@zip_path), @inner_path)
    end

    def test_not_respond_to_to_path
      assert_false @file.respond_to? :to_path
    end

    def test_cannot_initialize_with_closed_archive
      archive = Zip::Archive.open(@zip_path)
      archive.close
      assert_raise ArgumentError do Rack::Archive::Zip::Extract::ExtractedFile.new archive, @inner_path
      end
    end
  end
end
