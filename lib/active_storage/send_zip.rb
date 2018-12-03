require 'active_storage/send_zip/version'
require 'rails'
require 'zip'
require 'tempfile'
require 'pathname'

module ActiveStorage
  module SendZip
    extend ActiveSupport::Concern

    protected

    # Zip all given files into a zip and send it with `send_data`
    #
    # @param active_storages [ActiveStorage::Attached::Many] files to save
    # @param filename [ActiveStorage::Attached::Many] files to save
    def send_zip(active_storages, filename: 'my.zip')
      require 'zip'
      files = save_files_on_server active_storages
      zip_data = create_temporary_zip_file files

      send_data(zip_data, type: 'application/zip', filename: filename)
    end

    private

    # Download active storage files on server in a temporary folder
    #
    # @param files [ActiveStorage::Attached::Many] files to save
    # @return [Array<String>] files paths of saved files
    def save_files_on_server(files)
      require 'zip'
      # get a temporary folder and create it
      temp_folder = Dir.mktmpdir 'active_storage-send_zip'

      # download all ActiveStorage into
      files.map do |file|
        save_file_on_server(file, temp_folder)
      end
    end

    def save_file_on_server(file, folder, subfolder: nil)
      filename = file.filename.to_s
      filepath = File.join folder, filename

      # ensure that filename not exists
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
    def create_temporary_zip_file(filepaths)
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
