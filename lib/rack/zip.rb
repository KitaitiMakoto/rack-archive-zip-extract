require 'pathname'
require 'rack/utils'
require 'rack/file'
require 'rack/mime'
require 'zipruby'

# Rack::Zip is a Rack application which serves files in zip archives.
# @example
#   run Rack::Zip
# @example
#   run Rack::Zip, :extensions => %w[.epub .zip .jar .odt .docx]
# @note
#   {Rack::Zip Rack::Zip} does not serve a zip file itself. Use Rack::File or so to do so.
class Rack::Zip
  SEPS = Rack::File::SEPS
  ALLOWED_VERBS = Rack::File::ALLOWED_VERBS

  attr_reader :root

  # @param root [Pathname|#to_path|String]
  # @param extensions [Array<String>] extensions which is recognized as a zip file
  def initialize(root, extensions: %w[.zip])
    @root = root.kind_of?(Pathname) ? root : Pathname(root)
    @root = @root.expand_path
    @extensions = extensions
    raise ArgumentError, "Not a directory: #{@root}" unless @root.directory?
  end

  def call(env)
    return [405, {'Allow' => ALLOWED_VERBS.join(', ')}, ['']] unless ALLOWED_VERBS.include? env['REQUEST_METHOD']

    zip_file_path, file_in_zip = find_zip_file_and_inner_path(Rack::Utils.unescape(env['PATH_INFO']))
    return [404, {}, []] if zip_file_path.nil? or file_in_zip.empty?

    body = ''
    length = 0
    Zip::Archive.open zip_file_path.to_path do |archive|
      return [404, {}, []] if archive.locate_name(file_in_zip) < 0
      archive.fopen file_in_zip do |file|
        length = file.size
        body = file.read
      end
    end
    [
     200,
     {
       'Content-Type' => Rack::Mime.mime_type(File.extname(file_in_zip)),
       'Content-Length' => length.to_s
     },
     [body]
    ]
  end

  # @param path_info [String]
  # @return [Array] a pair of Pathname(zip file) and String(file path in zip archive)
  def find_zip_file_and_inner_path(path_info)
    path_parts = path_info_to_clean_parts(path_info)
    current = @root
    zip_file = nil
    while part = path_parts.shift
      zip_file = find_existing_file_with_extension(current, part, @extensions)
      current += part
      break if zip_file
    end
    return zip_file, File.join(path_parts)
  end

  # @param path_info [String]
  # @return [Array<String>] parts of clean path
  def path_info_to_clean_parts(path_info)
    parts = path_info.split SEPS
    clean = []
    parts.each do |part|
      next if part.empty? || part == '.'
      part == '..' ? clean.pop : clean << part
    end
    clean
  end

  # @param directory_path [Pathname] directory path to find file
  # @param basename [String] file name without extension
  # @param extensions [Array<String>] list of extension candidates, to be joined with +basename+
  # @return [Pathname] file path when file with extension exists
  # @return [nil] when file with extension doesn't exist
  def find_existing_file_with_extension(directory_path, basename, extensions)
    extensions.lazy.map {|ext| directory_path + "#{basename}#{ext}"}.find(&:file?)
  end
end
