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
    # @return [String] folder path of saved files
    def self.save_files_on_server(files)
      require 'zip'
      # get a temporary folder and create it
      temp_folder = Dir.mktmpdir 'active_storage-send_zip'

      if files.is_a? Hash
        filepaths = []

        files.each do |subfolder, filesHash|
          filesHash = [filesHash] unless filesHash.is_a? Array
          filesHash.each do |f|
            filepaths << save_file_on_server(f, temp_folder, subfolder: subfolder.to_s)
          end
        end
      elsif files.respond_to? :each
        files.each { |file| save_file_on_server(file, temp_folder) }
      else
        raise ArgumentError, '`files` must be an hash or an iterable object'
      end

      temp_folder
    end

    # Save the given file on the server
    #
    # @param file [ActiveStorage::Attached] files to save
    # @param folder [String] where to store the file
    # @return [String] the filepath of file created
    def self.save_file_on_server(file, folder, subfolder: nil)
      filename = file.filename.to_s

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

      File.open(filepath, 'wb') { |f| f.write(file.download) }
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

        return File.read(temp_file.path)
      ensure
        # close all ressources & remove temporary files
        # temp_file.close
        # temp_file.unlink
        # FileUtils.rm_rf(folderpath)
      end
    end
  end
end
