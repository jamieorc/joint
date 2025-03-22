module Joint
  class AttachmentProxy
    def initialize(instance, name)
      @instance, @name = instance, name
    end

    def id
      @instance.send("#{@name}_id")
    end

    def name
      @instance.send("#{@name}_name")
    end

    def size
      @instance.send("#{@name}_size")
    end

    def type
      @instance.send("#{@name}_type")
    end

    def nil?
      !@instance.send("#{@name}?")
    end
    alias_method :blank?, :nil?

    def grid_io
      # grid is instance of Mongo::Grid::FSBucket
      # open_download_stream returns Grid::FSBucket::Stream::Read
      @grid_io ||= @instance.grid.open_download_stream(id)
    end

    def read
      grid_io.read
    end

    # Grid::FSBucket::Stream::Read#file_info returns Grid::File::Info
    def content_type
      grid_io.file_info.content_type
    end

    def file_id
      grid_io.file_info.id
    end

    def filename
      grid_io.file_info.filename
    end

    def file_length
      grid_io.file_info.length
    end
    alias file_size file_length

    def upload_date
      grid_io.file_info.upload_date
    end
  end
end
