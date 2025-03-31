require_relative "helper"

# class JointTest < Test::Unit::TestCase
# describe "JointTest" do
class JointSpec < JointBaseSpec
  include JointTestHelpers

  # def setup
  before do
    # super
    @file   = open_file('unixref.pdf')
    @image  = open_file('mr_t.jpg')
    @image2 = open_file('harmony.png')
    @test1  = open_file('test1.txt')
    @test2  = open_file('test2.txt')
  end

  # def teardown
  after do
    all_files.each { |file| file.close }
  end

  describe "Using Joint plugin" do
    should "add each attachment to attachment_names" do
      assert_equal Set.new([:image, :file]), Asset.attachment_names
      assert_equal Set.new([:image, :file]), EmbeddedAsset.attachment_names
    end

    should "add keys for each attachment" do
      key_names.each do |key|
        assert_includes Asset.keys, "image_#{key}"
        assert_includes Asset.keys, "file_#{key}"
        assert_includes EmbeddedAsset.keys, "image_#{key}"
        assert_includes EmbeddedAsset.keys, "file_#{key}"
      end
    end

    # should "add memoized accessors module" do
    #   assert_instance_of Module, Asset.attachment_accessor_module
    #   assert_instance_of Module, EmbeddedAsset.attachment_accessor_module
    # end

    describe "with inheritance" do
      should "add attachment to attachment_names" do
        assert_equal Set.new([:file]), BaseModel.attachment_names
      end

      should "inherit attachments from superclass, but not share other inherited class attachments" do
        assert_equal Set.new([:file, :image]), Image.attachment_names
        assert_equal Set.new([:file, :video]), Video.attachment_names
      end

      should "add inherit keys from superclass" do
        key_names.each do |key|
          assert_includes BaseModel.keys, "file_#{key}"
          assert_includes Image.keys, "file_#{key}"
          assert_includes Image.keys, "image_#{key}"
          assert_includes Video.keys, "file_#{key}"
          assert_includes Video.keys, "video_#{key}"
        end
      end

      it "saves successfully" do
        assert_grid_difference(2) do
          Image.create(file: @image, image: @image2)
          rewind_files
        end
      end
    end
  end

  describe "Assigning new attachments to document" do
    before do
      @doc = Asset.create(:image => @image, :file => @file)
      rewind_files
    end
    let(:subject) { @doc }

    should "assign GridFS content_type" do
      assert_equal 'image/jpeg', grid.open_download_stream(subject.image_id).file_info.content_type
      assert_equal 'application/pdf', grid.open_download_stream(subject.file_id).file_info.content_type
    end

    should "assign joint keys" do
      assert_equal 13661, subject.image_size
      assert_equal 68926, subject.file_size

      assert_equal "image/jpeg", subject.image_type
      assert_equal "application/pdf", subject.file_type

      refute_nil subject.image_id
      refute_nil subject.file_id

      assert_instance_of BSON::ObjectId, subject.image_id
      assert_instance_of BSON::ObjectId, subject.file_id
    end

    should "allow accessing keys through attachment proxy" do
      assert_equal 13661, subject.image.size
      assert_equal 68926, subject.file.size

      assert_equal "image/jpeg", subject.image.type
      assert_equal "application/pdf", subject.file.type

      refute_nil subject.image.id
      refute_nil subject.file.id

      assert_instance_of BSON::ObjectId, subject.image.id
      assert_instance_of BSON::ObjectId, subject.file.id
    end

    should "proxy unknown methods to GridIO object" do
      assert_equal subject.image_id, subject.image.file_id
      assert_equal 'image/jpeg', subject.image.content_type
      assert_equal 'mr_t.jpg', subject.image.filename
      assert_equal 13661, subject.image.file_length
    end

    should "assign file name from path if original file name not available" do
      assert_equal 'mr_t.jpg', subject.image_name
      assert_equal 'unixref.pdf', subject.file_name
    end

    should "save attachment contents correctly" do
      assert_equal @file.read, subject.file.read
      assert_equal @image.read, subject.image.read
    end

    should "know that attachment exists" do
      assert subject.image?
      assert subject.file?
    end

    should "respond with false when asked if the attachment is blank?" do
      refute subject.image.blank?
      refute subject.file.blank?
    end

    should "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid::FSBucket.any_instance.expects(:upload_from_stream).never
      subject.save
    end
  end

  describe "Assigning new attachments to embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image, :file => @file)
      @asset.save!
      rewind_files
    end
    let(:subject) { @doc }

    should "assign GridFS content_type" do
      assert_equal 'image/jpeg', grid.open_download_stream(subject.image_id).file_info.content_type
      assert_equal 'application/pdf', grid.open_download_stream(subject.file_id).file_info.content_type
    end

    should "assign joint keys" do
      assert_equal 13661, subject.image_size
      assert_equal 68926, subject.file_size

      assert_equal "image/jpeg", subject.image_type
      assert_equal "application/pdf", subject.file_type

      refute_nil subject.image_id
      refute_nil subject.file_id

      assert_instance_of BSON::ObjectId, subject.image_id
      assert_instance_of BSON::ObjectId, subject.file_id
    end

    should "allow accessing keys through attachment proxy" do
      assert_equal 13661, subject.image.size
      assert_equal 68926, subject.file.size

      assert_equal "image/jpeg", subject.image.type
      assert_equal "application/pdf", subject.file.type

      refute_nil subject.image.id
      refute_nil subject.file.id

      assert_instance_of BSON::ObjectId, subject.image.id
      assert_instance_of BSON::ObjectId, subject.file.id
    end

    should "proxy unknown methods to GridIO object" do
      assert_equal subject.image_id, subject.image.file_id
      assert_equal 'image/jpeg', subject.image.content_type
      assert_equal 'mr_t.jpg', subject.image.filename
      assert_equal 13661, subject.image.file_length
    end

    should "assign file name from path if original file name not available" do
      assert_equal 'mr_t.jpg', subject.image_name
      assert_equal 'unixref.pdf', subject.file_name
    end

    should "save attachment contents correctly" do
      assert_equal @file.read, subject.file.read
      assert_equal @image.read, subject.image.read
    end

    should "know that attachment exists" do
      assert subject.image?
      assert subject.file?
    end

    should "respond with false when asked if the attachment is blank?" do
      refute subject.image.blank?
      refute subject.file.blank?
    end


    should "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid::FSBucket.any_instance.expects(:upload_from_stream).never
      subject.save
    end
  end

  describe "Updating existing attachment" do
    before do
      @doc = Asset.create(:file => @test1)

      assert_no_grid_difference do
        @doc.file = @test2
        @doc.save!
      end
      rewind_files
    end
    let(:subject) { @doc }

    should "update keys" do
      assert_equal 'test2.txt', subject.file_name
      assert_equal "text/plain", subject.file_type
      assert_equal 5, subject.file_size
    end

    should "update GridFS" do
      assert_equal 'test2.txt', grid.open_download_stream(subject.file_id).file_info.filename
      assert_equal 'text/plain', grid.open_download_stream(subject.file_id).file_info.content_type
      assert_equal 5, grid.open_download_stream(subject.file_id).file_info.length
      assert_equal @test2.read, grid.open_download_stream(subject.file_id).read
    end
  end

  describe "Updating existing attachment in embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:file => @test1)
      @asset.save!
      assert_no_grid_difference do
        @doc.file = @test2
        @doc.save!
      end
      rewind_files
    end
    let(:subject) { @doc }

    should "update keys" do
      assert_equal 'test2.txt', subject.file_name
      assert_equal "text/plain", subject.file_type
      assert_equal 5, subject.file_size
    end

    should "update GridFS" do
      assert_equal 'test2.txt', grid.open_download_stream(subject.file_id).file_info.filename
      assert_equal 'text/plain', grid.open_download_stream(subject.file_id).file_info.content_type
      assert_equal 5, grid.open_download_stream(subject.file_id).file_info.length
      assert_equal @test2.read, grid.open_download_stream(subject.file_id).read
    end
  end

  describe "Updating document but not attachments" do
    before do
      @doc = Asset.create(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @doc.reload
      rewind_files
    end
    let(:subject) { @doc }

    should "not affect attachment" do
      assert_equal @image.read, subject.image.read
    end

    should "update document attributes" do
      assert_equal 'Updated', subject.title
    end
  end

  describe "Updating embedded document but not attachments" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @asset.reload
      @doc = @asset.embedded_assets.first
      rewind_files
    end
    let(:subject) { @doc }

    should "not affect attachment" do
      assert_equal @image.read, subject.image.read
    end

    should "update document attributes" do
      assert_equal 'Updated', subject.title
    end
  end

  describe "Assigning file where file pointer is not at beginning" do
    before do
      @image.read
      @doc = Asset.create(:image => @image)
      @doc.reload
      rewind_files
    end
    let(:subject) { @doc }

    should "rewind and correctly store contents" do
      assert_equal @image.read, subject.image.read
    end
  end

  describe "Setting attachment to nil" do
    before do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    let(:subject) { @doc }

    it "delete attachment after save" do
      assert_no_grid_difference   { subject.image = nil }
      assert_grid_difference(-1)  { subject.save }
    end

    should "know that the attachment has been nullified" do
      subject.image = nil
      refute subject.image?
    end

    should "respond with true when asked if the attachment is nil?" do
      subject.image = nil
      assert subject.image.nil?
    end

    should "respond with true when asked if the attachment is blank?" do
      subject.image = nil
      assert subject.image.blank?
    end

    should "clear nil attachments after save and not attempt to delete again" do
      Mongo::Grid::FSBucket.any_instance.expects(:delete).once
      subject.image = nil
      subject.save
      Mongo::Grid::FSBucket.any_instance.expects(:delete).never
      subject.save
    end

    should "clear id, name, type, size" do
      subject.image = nil
      subject.save
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
      subject.reload
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
    end
  end

  describe "Setting attachment to nil on embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @asset.save!
      rewind_files
    end
    let(:subject) { @doc }

    should "delete attachment after save" do
      assert_no_grid_difference   { subject.image = nil }
      assert_grid_difference(-1)  { subject.save }
    end

    should "know that the attachment has been nullified" do
      subject.image = nil
      refute subject.image?
    end

    should "respond with true when asked if the attachment is nil?" do
      subject.image = nil
      assert subject.image.nil?
    end

    should "respond with true when asked if the attachment is blank?" do
      subject.image = nil
      assert subject.image.blank?
    end

    should "clear nil attachments after save and not attempt to delete again" do
      Mongo::Grid::FSBucket.any_instance.expects(:delete).once
      subject.image = nil
      subject.save
      Mongo::Grid::FSBucket.any_instance.expects(:delete).never
      subject.save
    end

    should "clear id, name, type, size" do
      subject.image = nil
      subject.save
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
      s = subject._root_document.reload.embedded_assets.first
      assert_nil s.image_id
      assert_nil s.image_name
      assert_nil s.image_type
      assert_nil s.image_size
    end
  end

  describe "Retrieving attachment that does not exist" do
    before do
      @doc = Asset.create
      rewind_files
    end
    let(:subject) { @doc }

    should "know that the attachment is not present" do
      refute subject.image?
    end

    should "respond with true when asked if the attachment is nil?" do
      # assert subject.image.nil?
      assert subject.image.nil?
    end

    should "raise Mongo::GridFileNotFound" do
      # assert_raises(Mongo::GridFileNotFound) { subject.image.read }
      assert_raises(Mongo::Error::FileNotFound) { subject.image.read }
    end
  end

  describe "Destroying a document" do
    before do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    let(:subject) { @doc }

    should "remove files from grid fs as well" do
      assert_grid_difference(-1) { subject.destroy }
    end
  end

  describe "Destroying an embedded document's _root_document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @doc.save!
      rewind_files
    end
    let(:subject) { @doc }

    should "remove files from grid fs as well" do
      assert_grid_difference(-1) { subject._root_document.destroy }
    end
  end

  # What about when an embedded document is removed?

  describe "Assigning file name" do
    should "default to path" do
      assert_equal 'mr_t.jpg', Asset.create(:image => @image).image.name
    end

    it "use original_filename if available" do
      def @image.original_filename
        'testing.txt'
      end
      doc = Asset.create(:image => @image)
      assert_equal 'testing.txt', doc.image_name
    end
  end

  describe "Validating attachment presence" do
    before do
      @model_class = Class.new do
        include MongoMapper::Document
        plugin Joint
        attachment :file, :required => true

        def self.name; "Foo"; end
      end
    end

    should "work" do
      model = @model_class.new
      refute model.valid?

      model.file = @file
      assert model.valid?

      model.file = nil
      refute model.valid?

      model.file = @image
      assert model.valid?
    end
  end

  describe "Assigning joint io instance" do
    before do
      io = Joint::IO.new({
        :name    => 'foo.txt',
        :type    => 'plain/text',
        :content => 'This is my stuff'
      })
      @asset = Asset.create(:file => io)
    end

    should "work" do
      assert_equal 'foo.txt', @asset.file_name
      assert_equal 16, @asset.file_size
      assert_equal 'plain/text', @asset.file_type
      assert_equal 'This is my stuff', @asset.file.read
    end
  end

  describe "A font file" do
    before do
      @file = open_file('font.eot')
      @doc = Asset.create(:file => @file)
    end
    let(:subject) { @doc }

    should "assign joint keys" do
      assert_equal 17610, subject.file_size
      assert_equal "application/vnd.ms-fontobject", subject.file_type
      refute_nil subject.file_id
      assert_instance_of BSON::ObjectId, subject.file_id
    end
  end

  describe "A music file" do
    before do
      @file = open_file('example.m4r')
      @doc = Asset.create(:file => @file)
    end
    let(:subject) { @doc }

    should "assign joint keys" do
      assert_equal 50790, subject.file_size
      # assert_equal "audio/mp4", subject.file_type
      assert_includes ["audio/x-m4a", "audio/mp4"], subject.file_type, "Should be one of [\"audio/x-m4a]\", \"audio/mp4\"]"
      refute_nil subject.file_id
      assert_instance_of BSON::ObjectId, subject.file_id
    end
  end

  describe "Joint collection configuration" do
    it "has default gridfs collection" do
      assert_equal "fs", Asset.joint_collection_name
    end

    it "has custom gridfs collection" do
      assert_equal "custom", CustomCollectionAsset.joint_collection_name
    end

    it "inherits custom gridfs collection" do
      assert_equal "custom", CustomCollectionAssetSubclass.joint_collection_name
    end

    it "saves to the default gridfs collection" do
      assert_grid_difference(2, 'fs') do
        Asset.create(:image => @image, :file => @file)
        rewind_files
      end
    end

    it "saves to the custom gridfs collection" do
      assert_grid_difference(2, 'custom') do
        CustomCollectionAsset.create(:image => @image, :file => @file)
        rewind_files
      end
    end

  end

  describe "Serialization" do
    before do
      @doc = Asset.create(:image => @image, :file => @file)
      rewind_files
    end
    let(:subject) { @doc }

    it "includes joint attachment keys" do
      @doc.class.attachment_names.each do |name|
        key_names.each do |key|
          assert_includes @doc.as_json.keys, "#{name}_#{key}"
        end
      end
    end

    describe "for embedded documents" do
      before do
        @doc.embedded_assets << EmbeddedAsset.new(image: @image, file: @file)
        @doc.save!
        rewind_files
      end

      it "includes attachment keys in embedded documents" do
        EmbeddedAsset.attachment_names.each do |name|
          key_names.each do |key|
            assert_includes @doc.as_json['embedded_assets'].first.keys, "#{name}_#{key}"
          end
        end
      end
    end
  end
end
