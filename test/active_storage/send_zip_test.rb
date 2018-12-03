require 'test_helper'

class FakeController
  include ActiveStorage::SendZip

  def test_save_files_on_server(files)
    save_files_on_server files
  end

  def test_create_temporary_zip_file(files)
    create_temporary_zip_file files
  end
end

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

    controller = FakeController.new
    files_saved = controller.test_save_files_on_server(files)
    assert_equal 1, files_saved.count
    refute_nil controller.test_create_temporary_zip_file(files_saved)
  end

  def test_it_should_save_two_active_support
    files = [
      ActiveStorageMock.new('foo.txt'),
      ActiveStorageMock.new('bar.txt')
    ]

    controller = FakeController.new
    files_saved = controller.test_save_files_on_server(files)
    assert_equal 2, files_saved.count
    refute_nil controller.test_create_temporary_zip_file(files_saved)
  end
end
