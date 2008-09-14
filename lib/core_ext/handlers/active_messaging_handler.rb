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
    #
    # === Options
    #
    # queue:: The name of the queue to use to send the code to the background process.
    def self.handle(locals, options = {}, &block)
      ActiveMessaging::Gateway.publish((options[:queue] || self.queue_name).to_sym, Marshal.dump([block, locals]))
    end
    
    # Decodes a marshalled message which was previously sent over ActiveMQ. Returns an array containing
    # the code block as a string, the self-object and other local variables.
    def self.decode(message)
      begin
        code, variables = Marshal.load(message)
      rescue ArgumentError => e
        # Marshal.load does not trigger const_missing, so we have to do this ourselves.
        e.message.split(' ').last.constantize
        retry
      end
      obj = variables.delete(:self)
      [code, obj, variables]
    end
    
    # Executes a marshalled message which was previously sent over ActiveMQ, in the context of the self
    # object, with all the other local variables defined.
    def self.execute(message)
      code, obj, variables = self.decode(message)
      puts "--- executing code: #{code.source}\n--- with variables: #{variables.inspect}\n--- in object: #{obj.inspect}"

      obj.send :instance_eval, variables.collect { |key, value| "#{key} = variables[:#{key}]" }.join(';')
      obj.send :instance_eval, code.source
      puts "--- it happened!"
    end
  end
end
