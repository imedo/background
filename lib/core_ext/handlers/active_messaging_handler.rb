module Background #:nodoc:
  # This background handler sends the block as well as the local variables through ActiveMessaging
  # to the background poller. If you don't use the ActiveMessaging plugin, then this handler won't
  # work. In the background poller, you'd need a processor which could look like this:
  #
  #    class BackgroundProcessor < ApplicationProcessor
  #      subscribes_to :background
  #    
  #      def on_message(message)
  #        code, variables = Marshal.load(message)
  #        obj = variables.delete(:self)
  #    
  #        obj.send :instance_eval, variables.collect { |key, value| "#{key} = variables[:#{key}]" }.join(';')
  #        obj.send :instance_eval, "x = lambda {#{code.source}}; x.call"
  #      end
  #    end
  #    
  class ActiveMessagingHandler
    # The ActiveMQ queue name through which the block should be serialized.
    @@queue_name = :background
    cattr_accessor :queue_name
    
    # Marshals the block and the local variables and sends it through ActiveMQ to the background processor.
    def self.handle(locals, &block)
      ActiveMessaging::MessageSender.publish self.queue_name, Marshal.dump([block, locals])
    end
  end
end
