require 'test/unit'
require 'test/unit/notify'
require 'rack/lint'
require 'rack/mock'
require 'rack/zip'

class TestZip < Test::Unit::TestCase
  def setup
    @zip = Rack::Zip.new(__dir__)
  end

  def test_request_to_file_in_zip_returns_200
    response = Rack::MockRequest.new(@zip).get('/sample/sample.txt')

    assert_equal 200, response.status
  end

  def test_request_to_file_in_zip_returns_content
    response = Rack::MockRequest.new(@zip).get('/sample/sample.txt')

    assert_equal "This is a plain text file.\n", response.body
  end

  [
   %w[.txt  text/plain      text_plain],
   %w[.html text/html       text_html],
   %w[.xml  application/xml application_xml]
  ].each do |(ext, content_type, underscored)|
    define_method "test_request_to_file_with_extension_#{ext}_returns_content_type_#{underscored}" do
      response = Rack::MockRequest.new(@zip).get("/sample/sample#{ext}")

      assert_equal content_type, response['Content-Type']
    end
  end

  def test_request_to_zip_file_itself_returns_404
    response = Rack::MockRequest.new(@zip).get('/fixtures.zip')

    assert_equal 404, response.status
  end

  def test_request_to_file_in_zip_which_not_exist_returns_404
    response = Rack::MockRequest.new(@zip).get('/sample/non-existing')

    assert_equal 404, response.status
  end

  def test_extension_of_file_can_be_changed
    zip = Rack::Zip.new(__dir__, extensions: %w[.ext])

    pend
  end

  def test_multiple_extensions_for_zip_file_can_be_specified
    zip = Rack::Zip.new(__dir__, extensions: %w[.ext .zip])

    pend
  end
end
