# frozen_string_literal: true

require 'rails'
require 'zip'
require 'tempfile'
require 'pathname'

module ActiveStorage
  # This module contains some methods usefull for `ActiveStorage::SendZip.send_zip`
  # method.
  module SendZipHelper
    # Download active storage files on server in a temporary folder
    #
    # @param files [ActiveStorage::Attached::One|ActiveStorage::Attached::Many|Array|Hash] file(s) to save
    # @param resize_to_limit [Array] resize to limit filter in ImageProcessing format [width, height]
    # @return [String] folder path of saved files
    def self.save_files_on_server(files, resize_to_limit: nil)
      require 'zip'
      # get a temporary folder and create it
      temp_folder = Dir.mktmpdir 'active_storage-send_zip'

      if files.is_a? Hash
        filepaths = construct_with_hash(files, temp_folder)
      elsif files.respond_to? :each
        files.each { |file| save_file_on_server(file, temp_folder, resize_to_limit: resize_to_limit) }
      else
        raise ArgumentError, '`files` must be an hash or an iterable object'
      end

      temp_folder
    end

    # Parses hash to build out directories where folders are key names
    #
    # @param files [ActiveStorage::Attached::One|ActiveStorage::Attached::Many|Array|Hash] file(s) to save
    # @return [String] folder path of saved files
    def self.construct_with_hash(files, temp_folder)
      filepaths = []

      files.each do |subfolder, filesHash|
        filesHash = [filesHash] unless filesHash.is_a? Array

        filesHash.each do |f|
          # Build directory strucutre recursively for hashes
          if f.is_a? Hash
            # Build folder for hash entry
            folder = File.join(temp_folder, subfolder.to_s)
            Dir.mkdir(folder) unless Dir.exist?(folder)

            filepaths += construct_with_hash(f, folder)
          # Save attachement
          else
            filepaths << save_file_on_server(f, temp_folder, subfolder: subfolder.to_s)
          end
        end
      end

      filepaths
    end

    # Save the given file on the server
    #
    # @param file [ActiveStorage::Attached] files to save
    # @param folder [String] where to store the file
    # @param resize_to_limit [Array] resize to limit filter in ImageProcessing format [width, height]
    # @return [String] the filepath of file created
    def self.save_file_on_server(file, folder, subfolder: nil, resize_to_limit: nil)
      filename = file.filename.to_s.encode("Shift_JIS")

      folder = File.join(folder, subfolder) unless subfolder.nil?
      Dir.mkdir(folder) unless Dir.exist?(folder)

      # build filepath & create path if not exists
      filepath = File.join(folder, filename)

      # Ensure that filename not already exists
      if File.exist? filepath
        # create a new random filenames
        basename = File.basename filename
        extension = File.extname filename

        filename = "#{basename}_#{SecureRandom.uuid}#{extension}"
        filepath = File.join folder, filename
      end

      # resize images if needed
      unless resize_to_limit.nil?
        file = file.variant(resize_to_limit: resize_to_limit).processed
      end

      # write the file on disk
      File.open(filepath, 'wb') { |f| f.write(file.service.download(file.key)) }

      filepath
    end

    # Create a temporary zip file & return the content as bytes
    #
    # @param folderpath [String] folder path
    # @return [String] as content of zip
    def self.create_temporary_zip_file(folderpath)
      temp_file = Tempfile.new('user.zip')
      folderpath_glob = File.join folderpath, '**', '*'

      files = Dir.glob(folderpath_glob).reject { |e| File.directory? e }

      begin
        # Initialize the temp file as a zip file
        Zip::OutputStream.open(temp_file) { |zos| }

        # open the zip
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          files.each do |filepath|
            filepath_zip = filepath.sub(folderpath, '').sub(File::SEPARATOR, '')
            zip.add filepath_zip, filepath
          end
        end

        File.read(temp_file.path)
      ensure
        # close all ressources & remove temporary files
        # temp_file.close
        # temp_file.unlink
        # FileUtils.rm_rf(folderpath)
      end
    end
  end
end
