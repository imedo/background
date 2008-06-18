module Kernel
  # Executes the given block in a background task, or decorates a method to be executed in the background.
  #
  # There are two ways to use this method:
  #
  # === Decorate a method.
  #
  # To decorate a class' method, the background method must be called from inside a class
  # and the first argument must be a symbol, containing the name of the method to decorate.
  #
  #    class FactorialClass
  #      def factorial(number)
  #        result = (1..number).inject(1) { |num, res| res * num }
  #        Logger.log("The result is #{result}")
  #      end
  #
  #      # execute all calls to FactorialClass#factorial in the background
  #      background :factorial, :params => ['number']
  #    end
  #
  # === Execute a block in the background.
  #
  # To execute a block in the background, simply call Kernel#background with the block to execute.
  # All local variables used in the block must be explicitely supplied to the :locals option.
  #
  #    class User
  #      def delete_all_messages(move_to_trash)
  #        background :locals => { :trash => move_to_trash } do
  #          if trash
  #            self.messages.update_all "folder = 'Trash'"
  #          else
  #            self.messages.delete_all
  #          end
  #        end
  #      end
  #    end
  #
  # There are many possible strategies to run a block in a background process, sometimes several
  # inside a single application. This is why there is an option to specify the background handler
  # for the particular block to execute. For the case that the execution fails with the selected
  # handler (e.g. the background process doesn't respond), there is an option to specify one or
  # more fallback handlers. The handler and the fallback handlers are tried in order. On every
  # failure, an error is reported to the user through a configurable error reporter. If no handler
  # succeeds, the method returns nil, otherwise the method returns a symbolized name of the first
  # handler, that succeeded in executing the block.
  #
  # === Options
  #
  # handler:: The background handler to use. This option is ignored when using the decoration method.
  #           If none is specified, the Background::Config.default_handler is used. Available handlers
  #           are :active_messaging, :in_process, :forget, :disk, and :test.
  #
  # fallback:: An array containing fallback handlers, that are executed in order on failure. Execution
  #            is stopped as soon as one handler succeeds. If no fallback option is specified, the
  #            handlers in Background::Config.default_fallback are used.
  #
  # params:: Parameter names of the method to decorate. These parameter names must match the parameter
  #          names of the original method, that is decorated. This option is ignored, when a block is
  #          given.
  #
  # locals:: A Hash containing name-value-pairs of local variables that need to be accessible to the
  #          block when it is run in the background. This option is ignored when a method is decorated.
  #
  # reporter:: A reporter class that reports errors to the user. Available reporters are :stdout, :silent,
  #            :exception_notification, and :test.
  #
  # === Writing own handlers
  #
  # Writing handlers is easy. A background handler class must implement a self.handle method that accepts
  # a hash containing local variables for the block to execute. An error reporter must implement
  # a self.report method that accepts an exception object. Note that for most non-fallback handlers
  # you need to write a background task that accepts and executes the block. See Background::ActiveMessagingHandler
  # for an example on how to do that.
  #
  # === Things to note
  #
  # * Since it is not possible to serialize singleton objects, all objects are dup'ed before
  #   serialization. This means that all singleton methods get stripped away on serialization.
  # * Every class used in a background block or method must be available in the background process as
  #   well.
  # * Subject to the singleton restriction mentioned above, the self object is correctly and automatically
  #   serialized and can be referenced in the block using the self keyword.
  def background(*args, &block)
    if args.first.is_a?(Symbol) && self.is_a?(Class)
      method = args.shift
      options = args.first || {}
      params = options.delete(:params) || {}
      fallback = [options.delete(:fallback)].flatten

      alias_method_chain method, :background do |aliased_target, punctuation|
        self.class_eval %{
          def #{method}_with_background#{punctuation}(#{params.join(', ')})
            background(:fallback => #{fallback.inspect}, :locals => { #{params.collect {|p| ":#{p} => #{p}" }.join(', ')} }) do
              #{method}_without_background#{punctuation}(#{params.join(', ')})
            end
          end
        }
      end
    else
      options = args.first || {}
      locals = options.delete(:locals) || {}
      locals.each do |key, value|
        locals[key] = value.dup rescue value
      end
      locals[:self] = self.dup
      handler = options.delete(:handler) || Background::Config.default_handler
      fallback = [options.delete(:fallback) || Background::Config.default_fallback].flatten
      reporter = options.delete(:reporter) || Background::Config.default_error_reporter
      
      ([handler] + fallback).each do |hand|
        begin
          "Background::#{hand.to_s.camelize}Handler".constantize.handle(locals, &block)
          return hand
        rescue Exception => e
          "Background::#{reporter.to_s.camelize}ErrorReporter".constantize.report(e)
        end
      end
    end
    nil
  end
end
