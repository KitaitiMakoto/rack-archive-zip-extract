require 'pathname'
require 'rack/utils'
require 'rack/file'
require 'rack/mime'
require 'zipruby'

module Rack::Archive
  module Zip
    # {Rack::Archive::Zip::Extract Rack::Archive::Zip::Extract} is a Rack application which serves files in zip archives.
    # @example
    #   run Rack::Archive::Zip::Extract.new('path/to/docroot')
    # @example
    #   run Rack::Archive::Zip::Extract.new('path/to/docroot', extensions: %w[.epub .zip .jar .odt .docx])
    # @note
    #   {Rack::Archive::Zip::Extract Rack::Archive::Zip::Extract} does not serve a zip file itself. Use Rack::File or so to do so.
    class Extract
      SEPS = Rack::File::SEPS
      ALLOWED_VERBS = Rack::File::ALLOWED_VERBS

      attr_reader :root

      # @param root [Pathname, #to_path, String] path to document root
      # @param extensions [Array<String>] extensions which is recognized as a zip file
      # @raise [ArgumentError] if +root+ is not a directory
      def initialize(root, extensions: %w[.zip])
        @root = root.kind_of?(Pathname) ? root : Pathname(root)
        @root = @root.expand_path
        @extensions = extensions
        raise ArgumentError, "Not a directory: #{@root}" unless @root.directory?
      end

      def call(env)
        return [405, {'Allow' => ALLOWED_VERBS.join(', ')}, []] unless ALLOWED_VERBS.include? env['REQUEST_METHOD']

        path_info = Rack::Utils.unescape(env['PATH_INFO'])
        zip_file = nil
        body = nil
        @extensions.each do |ext|
          zip_file, inner_path = find_zip_file_and_inner_path(path_info, ext)
          body = extract_content(zip_file, inner_path)
          break if body
        end
        return [404, {}, []] if body.nil?

        [
          200,
          {
            'Content-Type' => Rack::Mime.mime_type(::File.extname(path_info)),
            'Content-Length' => body.bytesize.to_s,
            'Last-Modified' => zip_file.mtime.httpdate
          },
          [body]
        ]
      end

      # @param path_info [String]
      # @param extension [String]
      # @return [Array] a pair of Pathname(zip file) and String(file path in zip archive)
      def find_zip_file_and_inner_path(path_info, extension)
        segments = path_info_to_clean_segments(path_info)
        current = @root
        zip_file = nil
        while segment = segments.shift
          zip_file = current + "#{segment}#{extension}"
          return zip_file, ::File.join(segments) if zip_file.file?
          current += segment
        end
      end

      # @param zip_file_path [Pathname] path to zip file
      # @param inner_path [String] path to file in zip archive
      # @return [String] content
      # @return [nil] if +zip_file_path+ is nil or +inner_path+ is empty
      # @return [nil] if +inner_path+ doesn't exist in zip archive
      def extract_content(zip_file_path, inner_path)
        return if zip_file_path.nil? or inner_path.empty?
        ::Zip::Archive.open zip_file_path.to_path do |archive|
          return if archive.locate_name(inner_path) < 0
          archive.fopen inner_path do |file|
            return file.read
          end
        end
      end

      # @param path_info [String]
      # @return [Array<String>] segments of clean path
      def path_info_to_clean_segments(path_info)
        segments = path_info.split SEPS
        clean = []
        segments.each do |segment|
          next if segment.empty? || segment == '.'
          segment == '..' ? clean.pop : clean << segment
        end
        clean
      end
    end
  end
end
