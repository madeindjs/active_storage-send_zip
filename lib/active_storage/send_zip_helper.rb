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
    # @param files [ActiveStorage::Attached::Many] files to save
    # @return [Array<String>] files paths of saved files
    def self.save_files_on_server(files)
      require 'zip'
      # get a temporary folder and create it
      temp_folder = Dir.mktmpdir 'active_storage-send_zip'

      if files.is_a? Array
        return files.map { |file| save_file_on_server(file, temp_folder) }
      elsif files.is_a? Hash
        filepaths = []

        files.each do |subfolder, filesHash|
          filesHash.each { |f| filepaths << save_file_on_server(f, temp_folder, subfolder: subfolder) }
        end

        return filepaths
      end
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
    # @param filepaths [Array<String>] files paths
    # @return [String] as content of zip
    def self.create_temporary_zip_file(filepaths)
      temp_file = Tempfile.new('user.zip')

      begin
        # Initialize the temp file as a zip file
        Zip::OutputStream.open(temp_file) { |zos| }

        # open the zip
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          filepaths.each do |filepath|
            filename = File.basename filepath
            # add file into the zip
            zip.add filename, filepath
          end
        end

        return File.read(temp_file.path)
      ensure
        # close all ressources & remove temporary files
        temp_file.close
        temp_file.unlink
        filepaths.each { |filepath| FileUtils.rm(filepath) }
      end
    end
  end
end
