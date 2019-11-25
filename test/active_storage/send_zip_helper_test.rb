require 'test_helper'
require 'pathname'

class ActiveStorageMock
  attr_reader :filename, :download

  def initialize(filename)
    @filename = filename
    @download = 'content of file'
  end
end

class ActiveStorage::SendZipTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActiveStorage::SendZip::VERSION
  end

  def test_it_should_save_one_active_support
    files = [
      ActiveStorageMock.new('foo.txt')
    ]

    assert_produce_files files
  end

  def test_it_should_save_two_active_support
    files = [
      ActiveStorageMock.new('foo.txt'),
      ActiveStorageMock.new('bar.txt')
    ]

    assert_produce_files files, count: 2
  end

  def test_it_should_save_two_active_support
    files = [
      ActiveStorageMock.new('foo.txt'),
      ActiveStorageMock.new('foo.txt')
    ]

    assert_produce_files files, count: 2
  end

  def test_it_should_save_files_in_differents_folders
    files = {
      'folder A' => [
        ActiveStorageMock.new('foo.txt'),
        ActiveStorageMock.new('foo.txt')
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
        ActiveStorageMock.new('foo.txt'),
        ActiveStorageMock.new('foo.txt')
      ],
      'folder B' => [
        ActiveStorageMock.new('bar.txt')
      ],
      0 => ActiveStorageMock.new('foo.txt'),
      1 => ActiveStorageMock.new('bar.txt')
    }
    assert_produce_nested_files files, folder_count: 4, files_count: 5
  end

  def test_it_should_rename_files_with_filenames_map_hash_values
    filenames_map = {
      'folder A' => ['hello'],
      'folder B' => ['world']
     }
    files = {
      'folder A' => [
        ActiveStorageMock.new('foo.txt')
      ],
      'folder B' => [
        ActiveStorageMock.new('bar.txt')
      ]
    }

    assert_rename_nested_files(files, filenames_map)
  end

  def test_it_should_rename_files_with_filenames_map_array_values
    filenames_map = ['hello', 'world']
    files = [
      ActiveStorageMock.new('foo.txt'),
      ActiveStorageMock.new('bar.txt')
    ]

    assert_rename_files(files, filenames_map)
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

  def assert_rename_nested_files(files, filenames_map)
    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files, filenames_map)
    temp_folder_glob = File.join temp_folder, '**', '*'

    glob = Dir.glob(temp_folder_glob)

    files_paths = glob.reject { |e| File.directory? e }
    files_names = files_paths.map { |f| f.split('/').last.split('.').first }
    assert_equal files_names.sort, filenames_map.values.flatten
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end

  def assert_rename_files(files, filenames_map)
    temp_folder = ActiveStorage::SendZipHelper.save_files_on_server(files, filenames_map)

    temp_folder_glob = File.join temp_folder, '**', '*'
    files_path = Dir.glob(temp_folder_glob).reject { |e| File.directory? e }
    files_names = files_path.map { |f| f.split('/').last.split('.').first }
    assert_equal files_names.sort, filenames_map.sort
    refute_nil ActiveStorage::SendZipHelper.create_temporary_zip_file(temp_folder)
  end

end
