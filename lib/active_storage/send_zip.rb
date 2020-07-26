require 'active_storage/send_zip/version'
require 'active_storage/send_zip_helper'

# I `ActiveStorage` namespace to monkey-path my methods into it
module ActiveStorage
  # This is an `ActiveSupport::Concern` to include into your controller.
  # The purpose is just to add a `send_zip` method to your controller
  module SendZip
    extend ActiveSupport::Concern

    protected

    # Zip all given files into a zip and send it with `send_data`
    #
    # @param active_storages [ActiveStorage::Attached::Many] files to save
    # @param filename [ActiveStorage::Attached::Many] files to save
    # @param resize_to_limit [Array] resize to limit filter in ImageProcessing format [width, height]
    def send_zip(active_storages, filename: 'my.zip', resize_to_limit: nil)
      require 'zip'
      files = SendZipHelper.save_files_on_server active_storages, resize_to_limit: resize_to_limit
      zip_data = SendZipHelper.create_temporary_zip_file files

      send_data(zip_data, type: 'application/zip', filename: filename)
    end
  end
end
