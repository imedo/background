require 'base64'

module Background #:nodoc:
  # This background handler runs the given code block via script/runner.
  class RunnerHandler
    # Marshals the block and the local variables and sends it through ActiveMQ to the background processor.
    def self.handle(locals, options = {}, &block)
      fork do
        system(%{script/runner "Background::RunnerHandler.execute '#{encode(locals, &block)}'"})
      end
    end
    
    def self.encode(locals, &block)
      Base64.encode64(Marshal.dump([block, locals]))
    end
    
    def self.decode(string)
      message = Base64.decode64(string)
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
