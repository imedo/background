module Background #:nodoc:
  # This background handler runs the given code block in a forked child process.
  class ForkHandler
    # Runs the code block in a forked child process
    def self.handle(locals, options = {}, &block)
      fork do
        block.call
      end
    end
  end
end
