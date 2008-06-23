module Background #:nodoc:
  # Executes the task in-process. This handler is probably most useful as a fallback handler.
  class InProcessHandler
    # Executes the task in-process by calling the block.
    def self.handle(locals, options = {}, &block)
      b = binding
      locals.each do |key, value|
        next if key == :self
        eval("#{key} = locals[:#{key}]", binding)
      end
      block.bind(locals[:self]).call
    end
  end
end
