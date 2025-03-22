require "bundler/setup"
Bundler.setup(:default, "test", "development")

# require 'byebug'
require "tempfile"
require "pp"
require "minitest/autorun"
require "minitest/rg"
require "mocha/minitest"
require "shoulda"
require "mongo_mapper"
require_relative "../lib/joint"

MongoMapper.database = "joint_test"

class JointBaseSpec < Minitest::Spec
  before do
    # NOTE this from skinandbones (Blake Carlson): coll.remove unless coll.name =~ /^system/
    MongoMapper.database.collections.each(&:delete_many)
  end

  def assert_difference(expression, difference = 1, message = nil, &block)
    b      = block.send(:binding)
    exps   = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }
    yield
    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      after = eval(e, b)
      assert_equal(before[i] + difference, after, error)
    end
  end

  def assert_no_difference(expression, message = nil, &block)
    assert_difference(expression, 0, message, &block)
  end

  def assert_grid_difference(difference=1, collection_name='fs', &block)
    assert_difference("MongoMapper.database['#{collection_name}.files'].count()", difference, &block)
  end

  def assert_no_grid_difference(collection_name = 'fs', &block)
    # assert_grid_difference(0, collection_name, &block)
    assert_no_difference(%Q{MongoMapper.database["#{collection_name}.files"].count()}, ">>>>> #{collection_name}.files.count() changed <<<<<", &block)
  end
end

class Basic
  include MongoMapper::Document
  has_many :embedded_assets
end

class Asset
  include MongoMapper::Document
  plugin Joint

  key :title, String
  attachment :image
  attachment :file
  has_many :embedded_assets
end

class CustomCollectionAsset < Asset
  set_joint_collection :custom
end

class CustomCollectionAssetSubclass < CustomCollectionAsset
  attachment :video
end

class EmbeddedAsset
  include MongoMapper::EmbeddedDocument
  plugin Joint

  key :title, String
  attachment :image
  attachment :file
end

class BaseModel
  include MongoMapper::Document
  plugin Joint
  attachment :file
end

class Image < BaseModel; attachment :image end
class Video < BaseModel; attachment :video end

module JointTestHelpers
  def all_files
    [@file, @image, @image2, @test1, @test2]
  end

  def rewind_files
    all_files.each { |file| file.rewind }
  end

  def open_file(name)
    f = File.open(File.join(File.dirname(__FILE__), "fixtures", name), "r")
    f.binmode
    f
  end

  def grid(collection_name = 'fs')
    @grids ||= {}
    @grids[collection_name] ||= Mongo::Grid::FSBucket.new(MongoMapper.database, fs_name: collection_name)
  end

  def key_names
    [:id, :name, :type, :size]
  end
end
