module Background #:nodoc:
  # This handler is used in a testing environment. It allows for introspection of last call to the handle method.
  class TestHandler
    # contains all locals given to the last call to TestHandler#handle.
    cattr_accessor :locals
    # contains the block given to the last call to TestHandler#handle.
    cattr_accessor :block
    # If true, the execution of TestHandler#handle will fail the next time it's called.
    cattr_accessor :fail_next_time
    # True, if TestHandler#handle was executed.
    cattr_accessor :executed
    # Stores the last options hash given to handle
    cattr_accessor :options
    
    # Does not call the block, but sets some variables for introspection.
    def self.handle(locals, options = {}, &block)
      self.executed = true
      if self.fail_next_time
        self.fail_next_time = false
        raise "TestHandler.handle: Failed on purpose"
      end
      
      self.locals, self.options, self.block = locals, options, block
    end
    
    # Returns the object from which the block was sent to the handler.
    def self.self_object
      self.locals[:self]
    end
    
    # Returns the block's source code.
    def self.code
      self.block.source
    end
    
    # Resets the class' accessors.
    def self.reset
      locals = options = block = fail_next_time = executed = nil
    end
  end
end
