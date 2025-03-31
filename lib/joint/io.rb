require 'stringio'

module Joint
  class IO
    attr_accessor :name, :type, :size
    attr_reader :content

    alias path name

    def initialize(attrs={})
      attrs.each { |key, value| send("#{key}=", value) }
      @type ||= 'plain/text'
    end

    def content=(value)
      @io = StringIO.new(value || nil)
      @size = value ? value.size : 0
    end

    def read(*args)
      @io.read(*args)
    end

    def rewind
      @io.rewind if @io.respond_to?(:rewind)
    end

    def eof?
      @io.nil? ? true : @io.eof?
    end
  end
end
