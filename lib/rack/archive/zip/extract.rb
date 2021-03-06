require 'pathname'
require 'digest/md5'
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
      extend Rack::Utils

      DOT = '.'.freeze
      DOUBLE_DOT = '..'.freeze
      CONTENT_TYPE = 'Content-Type'.freeze
      CONTENT_LENGTH = 'Content-Length'.freeze
      IF_MODIFIED_SINCE = 'HTTP_IF_MODIFIED_SINCE'.freeze
      LAST_MODIFIED = 'Last-Modified'.freeze
      IF_NONE_MATCH = 'HTTP_IF_NONE_MATCH'.freeze
      ETAG = 'ETag'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      PATH_INFO = 'PATH_INFO'.freeze
      EMPTY_BODY = [].freeze
      EMPTY_HEADERS = {}.freeze
      METHOD_NOT_ALLOWED = [status_code(:method_not_allowd), {'Allow'.freeze => Rack::File::ALLOWED_VERBS.join(', ').freeze}.freeze, EMPTY_BODY]
      NOT_FOUND = [status_code(:not_found), EMPTY_HEADERS, EMPTY_BODY].freeze
      NOT_MODIFIED = [status_code(:not_modified), EMPTY_HEADERS, EMPTY_BODY].freeze
      OCTET_STREAM = 'application/octet-stream'.freeze

      # @param root [Pathname, #to_path, String] path to document root
      # @param extensions [Array<String>] extensions which is recognized as a zip file
      # @param mime_types [Hash{String => String}] pairs of extesion and content type
      # @param buffer_size [Integer] buffer size to read content, in bytes
      # @raise [ArgumentError] if +root+ is not a directory
      def initialize(root, extensions: %w[.zip], mime_types: {}, buffer_size: ExtractedFile::BUFFER_SIZE)
        @root = root.kind_of?(Pathname) ? root : Pathname(root)
        @root = @root.expand_path
        @extensions = extensions.map {|extention| extention.dup.freeze}.lazy
        @mime_types = Rack::Mime::MIME_TYPES.merge(mime_types)
        @buffer_size = buffer_size
        raise ArgumentError, "Not a directory: #{@root}" unless @root.directory?
      end

      def call(env)
        return METHOD_NOT_ALLOWED unless Rack::File::ALLOWED_VERBS.include? env[REQUEST_METHOD]

        path_info = unescape(env[PATH_INFO])
        file = @extensions.map {|ext|
          zip_file, inner_path = find_zip_file_and_inner_path(path_info, ext)
          extract_file(zip_file, inner_path)
        }.select {|file| file}.first
        return NOT_FOUND if file.nil?

        if_modified_since = Time.parse(env[IF_MODIFIED_SINCE]) rescue Time.new(0)
        if_none_match = env[IF_NONE_MATCH]

        if file.mtime <= if_modified_since or env[IF_NONE_MATCH] == file.etag
          file.close
          NOT_MODIFIED
        else
          [
            status_code(:ok),
            {
              CONTENT_TYPE => @mime_types.fetch(::File.extname(path_info), OCTET_STREAM),
              CONTENT_LENGTH => file.size.to_s,
              LAST_MODIFIED => file.mtime.httpdate,
              ETAG => file.etag
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
      # @return [ExtractedFile]
      # @return [nil] if +zip_file_path+ is nil or +inner_path+ is empty
      # @return [nil] if +inner_path+ doesn't exist in zip archive
      def extract_file(zip_file_path, inner_path)
        return if zip_file_path.nil? or inner_path.empty?
        archive = ::Zip::Archive.open(zip_file_path.to_path)
        if archive.locate_name(inner_path) < 0
          archive.close
          nil
        else
          ExtractedFile.new(archive, inner_path, @buffer_size)
        end
      end

      # @param path_info [String]
      # @return [Array<String>] segments of clean path
      # @see http://rubydoc.info/gems/rack/Rack/File#_call-instance_method Algorithm stolen from Rack::File#_call
      def path_info_to_clean_segments(path_info)
        segments = path_info.split PATH_SEPS
        clean = []
        segments.each do |segment|
          next if segment.empty? || segment == DOT
          segment == DOUBLE_DOT ? clean.pop : clean << segment
        end
        clean
      end

      class ExtractedFile
        BUFFER_SIZE = 8192

        attr_reader :etag, :mtime, :size

        # @param archive [Zip::Archive]
        # @param path [String]
        # @param buffer_size [Integer]
        # @raise ArgumentError when +archive+ already closed
        def initialize(archive, path, buffer_size=BUFFER_SIZE)
          raise ArgumentError, 'archive already closed' unless archive.open?
          @archive = archive
          @file = @archive.fopen(path)
          @mtime = @file.mtime
          @size = @file.size
          @etag = Digest::MD5.hexdigest(@file.name) + @mtime.to_i.to_s(16) + @size.to_s(16)
          @buffer_size = buffer_size
        end

        def each
          while chunk = @file.read(@buffer_size)
            yield chunk
          end
        end

        def close
          @file.close
          @archive.close
        end
      end
    end
  end
end
