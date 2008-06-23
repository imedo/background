module Background #:nodoc:
  # Stores the serialized block on disk. This handler is probably most useful as a fallback handler.
  class DiskHandler
    # The directory in which the serialized blocks should be stored.
    @@dirname = nil
    cattr_accessor :dirname
    
    # Marshals the block and the locals into a file in the folder specified by dirname.
    def self.handle(locals, options = {}, &block)
      filename = "background_#{Time.now.to_f.to_s}"
      File.open("#{dirname}/#{filename}", 'w') do |file|
        file.print(Marshal.dump([block, locals]))
      end
    end
    
    # Replays all marshalled background tasks in the order in which they were stored into the folder
    # specified by dirname.
    def self.recover(handler)
      handler_class = "Background::#{handler.to_s.camelize}Handler".constantize
      Dir.entries(dirname).grep(/^background/).sort.each do |filename|
        path = "#{dirname}/#{filename}"
        File.open(path, 'r') do |file|
          code, variables = Marshal.load(file)
          handler_class.handle(variables, &code)
        end
        FileUtils.rm(path)
      end
    end
  end
end
