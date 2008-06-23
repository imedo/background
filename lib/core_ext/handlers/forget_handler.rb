module Background #:nodoc:
  # Forgets the background task. This handler is probably most useful as a fallback handler.
  class ForgetHandler
    # Does nothing
    def self.handle(locals, options = {}, &block)
      # do nothing
    end
  end
end
