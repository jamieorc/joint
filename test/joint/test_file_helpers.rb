require_relative "../helper"

describe "FileHelpers" do
  include JointTestHelpers

  before do
    @image = open_file('mr_t.jpg')
  end

  after do
    @image.close
  end

  describe ".name" do
    it "return original_filename" do
      def @image.original_filename
        'frank.jpg'
      end
      assert_equal 'frank.jpg', Joint::FileHelpers.name(@image)
    end

    should "fall back to File.basename" do
      assert_equal 'mr_t.jpg', Joint::FileHelpers.name(@image)
    end
  end

  describe ".size" do
    it "return size" do
      def @image.size
        25
      end
      assert_equal 25, Joint::FileHelpers.size(@image)
    end

    should "fall back to File.size" do
      assert_equal 13661, Joint::FileHelpers.size(@image)
    end
  end

  describe ".type" do
    it "return type if Joint::IO instance" do
      assert_equal 'image/jpeg', Joint::FileHelpers.type(@image)
    end

    should "fall back to Wand" do
      assert_equal 'image/jpeg', Joint::FileHelpers.type(@image)
    end
  end

end
