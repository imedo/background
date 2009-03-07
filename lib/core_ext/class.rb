class Class
  def clone_for_background
    self
  end

  def background_method(*args)
    method = args.shift
    options = args.first || {}
    # handler = [options.delete(:handler)].flatten
    
    alias_method_chain method, :background do |aliased_target, punctuation|
      self.class_eval do
        define_method "#{method}_with_background#{punctuation}" do |*args|
          background(options.update(:locals => { :args => args })) do
            send("#{method}_without_background#{punctuation}", *args)
          end
        end
      end
    end
  end
end
