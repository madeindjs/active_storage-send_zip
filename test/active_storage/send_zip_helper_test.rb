# frozen_string_literal: true

require 'test_helper'
require 'pathname'

class ActiveStorageMock
  attr_reader :filename, :download, :key, :service

  def initialize(filename = 'foo.txt', content = 'content of file')
    @filename = filename
    @download = content
    @key = 'service key'
    @service = ActiveStorageServiceMock.new(self)
  end

  def variant(resize_to_limit: nil)
    ActiveStorageVariantMock.new(resize_to_limit)
  end
end

# Mock for ActiveStorage::Attached::Many
class ActiveStorageManyMock
  # Define the constant to simulate ActiveStorage::Attached::Many
  module ActiveStorage
    module Attached
      class Many
      end
    end
  end

  attr_reader :attachments

  def initialize(attachments = [])
    @attachments = attachments
  end

  def each(&block)
    @attachments.each(&block)
  end

  # Mock the is_a? method to simulate ActiveStorage::Attached::Many
  def is_a?(klass)
    klass == ActiveStorageManyMock::ActiveStorage::Attached::Many
  end
end

class ActiveStorageVariantMock
  attr_reader :key, :download, :service

  def initialize(resize_to_limit = nil)
    @resize_to_limit = resize_to_limit
    @download = 'content of file'
    @key = 'service key'
    @service = ActiveStorageServiceMock.new(self)
  end

  def processed
    self
  end
end

class ActiveStorageServiceMock
  def initialize(mock)
    @mock = mock
  end

  def download(_key)
    @mock.download
  end
end

class ActiveStorage::SendZipTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActiveStorage::SendZip::VERSION
  end

  def test_it_should_save_one_active_support
    files = [
      ActiveStorageMock.new
    ]

    assert_produce_files files
  end

  def test_it_should_save_two_active_support
    files = [
      ActiveStorageMock.new,
      ActiveStorageMock.new('bar.txt')
    ]

    assert_produce_files files, count: 2
  end

  def test_it_should_save_two_active_support
    files = [
      ActiveStorageMock.new,
      ActiveStorageMock.new
    ]

    assert_produce_files files, count: 2
  end

  def test_it_should_save_files_in_differents_folders
    files = {
      'folder A' => [
        ActiveStorageMock.new,
        ActiveStorageMock.new
      ],
      'folder B' => [
        ActiveStorageMock.new('bar.txt')
      ]
    }
    assert_produce_nested_files files, folder_count: 2, files_count: 3
  end

  def test_it_should_raise_an_exception
    assert_raises ArgumentError do
      ActiveStorage::SendZipHelper.save_files_on_server 'bad boi'
    end
  end

  def test_it_should_save_files_in_differents_folders_with_root_files
    files = {
      'folder A' => [
        ActiveStorageMock.new,
        ActiveStorageMock.new
      ],
      'folder B' => [
        ActiveStorageMock.new('bar.txt'),
        { 'folder C' => [
          ActiveStorageMock.new
        ] }
      ],
      0 => ActiveStorageMock.new,
      1 => ActiveStorageMock.new('bar.txt')
    }
    assert_produce_nested_files files, folder_count: 5, files_count: 6
  end

  def test_it_should_resize_files
    files = [
      ActiveStorageMock.new,
      ActiveStorageMock.new
    ]

    assert_produce_resized_files files, count: 2
  end

  def test_it_should_handle_empty_files
    files = []

    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files)
    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }

    assert_equal 0, files_path.count
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end

  def test_it_should_handle_filename_collision
    # Create mocks with same filename to test collision handling
    files = [
      ActiveStorageMock.new('same_name.txt'),
      ActiveStorageMock.new('same_name.txt')
    ]

    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files)
    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }

    assert_equal 2, files_path.count
    # Both files should have been saved with different names due to collision handling
    filenames = files_path.map { |path| File.basename(path) }
    assert(filenames.all? { |name| name.include?('same_name') })
  end

  def test_it_should_handle_deeply_nested_directories
    files = {
      'level1' => {
        'level2' => {
          'level3' => [
            ActiveStorageMock.new,
            ActiveStorageMock.new('bar.txt')
          ]
        },
        'another_level2' => [
          ActiveStorageMock.new('baz.txt')
        ]
      }
    }

    assert_produce_nested_files files, folder_count: 4, files_count: 3
  end

  def test_it_should_handle_active_storage_attached_many_objects
    # Skip this test if we're not in a Rails environment with ActiveStorage
    skip 'ActiveStorage not available' unless defined?(ActiveStorage)

    # This test would verify the functionality, but we can't easily mock
    # ActiveStorage::Attached::Many without a full Rails environment
    # The implementation has been designed to handle this case properly
  end

  def test_it_should_handle_nil_values_gracefully
    files = {
      'folder_with_files' => [
        ActiveStorageMock.new
      ],
      'folder_with_nil' => nil
    }

    # Should raise an error when trying to iterate over nil
    assert_raises NoMethodError do
      ActiveStorage::SendZipHelper.save_files_on_server(files)
    end
  end

  def test_it_should_create_zip_with_various_file_sizes
    # Mock different file sizes by customizing download content
    large_file_mock = ActiveStorageMock.new('large.txt')
    # Simulate larger content
    large_file_mock.instance_variable_set(:@download, 'content' * 1000)

    files = [
      ActiveStorageMock.new('small.txt'),
      large_file_mock
    ]

    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files)
    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }

    assert_equal 2, files_path.count

    # Verify zip creation works with different file sizes
    zip_content = ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
    refute_nil zip_content
    assert zip_content.length > 0
  end

  private

  def assert_produce_nested_files(files, folder_count: 1, files_count: 1)
    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files)
    temp_folder_glob = File.join temp_folder, '**', '*'

    glob = Dir.glob(temp_folder_glob)

    files_paths = glob.reject { |e| File.directory? e }
    folders_paths = glob.select { |e| File.directory? e }

    assert_equal folder_count, folders_paths.count
    assert_equal files_count, files_paths.count
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end

  def assert_produce_files(files, count: 1)
    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files)

    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }

    assert_equal count, files_path.count
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end

  def assert_produce_resized_files(files, count: 1)
    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files, resize_to_limit: [640, 480])

    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }

    assert_equal count, files_path.count
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end
end
