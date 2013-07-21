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

  def test_request_to_file_in_zip_returns_200
    response = request('/sample/sample.txt')

    assert_equal 200, response.status
  end

  def test_request_to_file_in_zip_returns_content
    response = request('/sample/sample.txt')

    assert_equal "This is a plain text file.\n", response.body
  end

  [
   %w[.txt  text/plain      text_plain],
   %w[.html text/html       text_html],
   %w[.xml  application/xml application_xml]
  ].each do |(ext, content_type, underscored)|
    define_method "test_request_to_file_with_extension_#{ext}_returns_content_type_#{underscored}" do
      response = request("/sample/sample#{ext}")

      assert_equal content_type, response['Content-Type']
    end
  end

  def test_request_to_zip_file_itself_returns_404
    response = request('/fixtures.zip')

    assert_equal 404, response.status
  end

  def test_request_to_file_in_zip_which_not_exist_returns_404
    response = request('/sample/non-existing')

    assert_equal 404, response.status
  end

  def test_extension_of_file_can_be_changed
    ext = Rack::Zip.new(__dir__, extensions: %w[.ext])
    response = request('/sample/sample.txt', ext)

    assert_equal 200, response.status
    assert_equal "This is a plain text file in sample.ext.\n", response.body
  end

  def test_multiple_extensions_for_zip_file_can_be_specified
    multi = Rack::Zip.new(__dir__, extensions: %w[.ext .zip])
    response = request('/sample/sample.txt', multi)

    assert_equal 200, response.status
    assert_equal "This is a plain text file in sample.ext.\n", response.body
  end

  data(
    'path to zip file'                             => ['/sample.zip',            [nil,          '']],
    'path to non-existing file'                    => ['/non-existing',          [nil,          '']],
    'path ending with slash'                       => ['/sample/',               ['sample.zip', '']],
    'path including file name in zip archive'      => ['/sample/inner.txt',      ['sample.zip', 'inner.txt']],
    'path including directory name in zip archive' => ['/sample/inner/file.txt', ['sample.zip', 'inner/file.txt']]
  )
  def test_find_zip_file(data)
    path_info, (path, file_in_zip) = data
    path &&= (@zip.root + path)

    assert_equal [path, file_in_zip], @zip.find_zip_file(path_info)
  end

  def test_use_former_extension_when_same_basename_specified
    multi = Rack::Zip.new(__dir__, extensions: %w[.ext .zip])
    file_path, _ = multi.find_zip_file('/sample/sample.txt')

    assert_equal multi.root + 'sample.ext', file_path
  end
end
