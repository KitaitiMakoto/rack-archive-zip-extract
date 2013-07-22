require 'test/unit'
require 'test/unit/notify'
require 'rack/lint'
require 'rack/mock'
require 'rack/zip'

class TestZip < Test::Unit::TestCase
  def setup
    @zip = Rack::Zip.new(__dir__)
  end

  def request(path, app=@zip)
    Rack::MockRequest.new(app).get(path)
  end

  def test_request_to_file_in_zip_returns_content
    response = request('/sample/sample.txt')

    assert_equal "This is a plain text file.\n", response.body
  end

  class TestStatusCode < self
    data(
      'file in zip'              => [200, '/sample/sample.txt'],
      'zip file itself'          => [404, '/sample.zip'],
      'non-existent file in zip' => [404, '/sample/non-existent']
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
    ext = Rack::Zip.new(__dir__, extensions: %w[.ext])
    response = request('/sample/sample.txt', ext)

    assert_equal 200, response.status
    assert_equal "This is a plain text file in sample.ext.\n", response.body
  end

  class TestMultipleExtensions < self
    def setup
      super
      @multi = Rack::Zip.new(__dir__, extensions: %w[.ext .zip])
    end

    def test_multiple_extensions_for_zip_file_can_be_specified
      response = request('/sample/sample.txt', @multi)

      assert_equal 200, response.status
      assert_equal "This is a plain text file in sample.ext.\n", response.body
    end

    def test_use_former_extension_when_same_basename_specified
      file_path, _ = @multi.find_zip_file_and_inner_path('/sample/sample.txt')

      assert_equal @multi.root + 'sample.ext', file_path
    end
  end

  class TestFindZipFileAndInnerPath < self
    data(
      'path to zip file'                             => ['/sample.zip',            nil,          ''],
      'path to non-existent file'                    => ['/non-existent',          nil,          ''],
      'path ending with slash'                       => ['/sample/',               'sample.zip', ''],
      'path including file name in zip archive'      => ['/sample/inner.txt',      'sample.zip', 'inner.txt'],
      'path including directory name in zip archive' => ['/sample/inner/file.txt', 'sample.zip', 'inner/file.txt']
    )

    def test_find_zip_file_and_inner_path(data)
      path_info, path, file_in_zip = data
      path &&= @zip.root + path

      assert_equal [path, file_in_zip], @zip.find_zip_file_and_inner_path(path_info)
    end
  end
end
