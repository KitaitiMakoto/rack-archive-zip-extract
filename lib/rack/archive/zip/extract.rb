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
      include Rack::Utils

      SEPS = Rack::File::SEPS
      DOT = '.'.freeze
      DOUBLE_DOT = '..'.freeze
      ALLOWED_METHODS = Rack::File::ALLOWED_VERBS.join(', ').freeze
      ALLOW = 'Allow'.freeze
      CONTENT_TYPE = 'Content-Type'.freeze
      CONTENT_LENGTH = 'Content-Length'.freeze
      IF_MODIFIED_SINCE = 'HTTP_IF_MODIFIED_SINCE'.freeze
      LAST_MODIFIED = 'Last-Modified'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      PATH_INFO = 'PATH_INFO'.freeze

      attr_reader :root

      # @param root [Pathname, #to_path, String] path to document root
      # @param extensions [Array<String>] extensions which is recognized as a zip file
      # @raise [ArgumentError] if +root+ is not a directory
      def initialize(root, extensions: %w[.zip])
        @root = root.kind_of?(Pathname) ? root : Pathname(root)
        @root = @root.expand_path
        @extensions = extensions.each {|extention| extention.freeze}.lazy
        raise ArgumentError, "Not a directory: #{@root}" unless @root.directory?
      end

      def call(env)
        return [status_code(:method_not_allowd), {ALLOW => ALLOWED_METHODS}, []] unless Rack::File::ALLOWED_VERBS.include? env[REQUEST_METHOD]

        path_info = unescape(env[PATH_INFO])
        file = @extensions.map {|ext|
          zip_file, inner_path = find_zip_file_and_inner_path(path_info, ext)
          extract_file(zip_file, inner_path)
        }.select {|file| file}.first
        return [status_code(:not_found), {}, []] if file.nil?

        if_modified_since = env[IF_MODIFIED_SINCE]
        if_modified_since = Time.parse(if_modified_since) if if_modified_since
        if if_modified_since and file.mtime <= if_modified_since
          [status_code(:not_modified), {}, []]
        else
          [
            status_code(:ok),
            {
              CONTENT_TYPE => Rack::Mime.mime_type(::File.extname(path_info)),
              CONTENT_LENGTH => file.size.to_s,
              LAST_MODIFIED => file.mtime.httpdate
            },
            file
          ]
        end
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
      # @return [Zip::File]
      # @return [nil] if +zip_file_path+ is nil or +inner_path+ is empty
      # @return [nil] if +inner_path+ doesn't exist in zip archive
      def extract_file(zip_file_path, inner_path)
        return if zip_file_path.nil? or inner_path.empty?
        archive = ::Zip::Archive.open(zip_file_path.to_path)
        if archive.locate_name(inner_path) < 0
          archive.close
          nil
        else
          ExtractedFile.new(archive, inner_path)
        end
      end

      # @param path_info [String]
      # @return [Array<String>] segments of clean path
      # @see http://rubydoc.info/gems/rack/Rack/File#_call-instance_method Algorithm stolen from Rack::File#_call
      def path_info_to_clean_segments(path_info)
        segments = path_info.split SEPS
        clean = []
        segments.each do |segment|
          next if segment.empty? || segment == DOT
          segment == DOUBLE_DOT ? clean.pop : clean << segment
        end
        clean
      end

      class ExtractedFile
        # @param archive [Zip::Archive]
        # @param path [String]
        def initialize(archive, path)
          @archive = archive
          @file = @archive.fopen(path)
        end

        def each
          @file.read do |chunk|
            yield chunk
          end
        end

        def mtime
          @file.mtime
        end

        def size
          @file.size
        end

        def close
          @file.close
          @archive.close
        end
      end
    end
  end
end
