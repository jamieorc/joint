require_relative "../helper"

describe IO do
  context "#initialize" do
    should "set attributes from hash" do
      assert_equal 'foo', Joint::IO.new(:name => 'foo').name
    end
  end

  should "default type to plain text" do
    assert_equal 'plain/text', Joint::IO.new.type
  end

  it "default size to content size" do
    content = 'This is my content'
    assert_equal content.size, Joint::IO.new(:content => content).size
  end

  should "alias path to name" do
    assert_equal 'foo', Joint::IO.new(:name => 'foo').path
  end

  context "#read" do
    should "return content" do
      assert_equal 'Testing', Joint::IO.new(:content => 'Testing').read
    end
  end

  context "#rewind" do
    should "rewinds the io to position 0" do
      io = Joint::IO.new(:content => 'Testing')
      assert_equal 'Testing', io.read
      assert_equal '', io.read
      io.rewind
      assert_equal 'Testing', io.read
    end
  end
end
