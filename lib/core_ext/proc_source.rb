require 'stringio'
require 'irb/ruby-lex'

# Tell the ruby interpreter to load code lines of required files
# into this filename -> lines Hash. This behaviour seems to be
# very undocumented and therefore shouldn't really be relied on.
SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

module ProcSource #:nodoc:
  def get_lines(filename, start_line = 0)
    case filename
      # special "(irb)" descriptor?
      when "(irb)"
        IRB.conf[:MAIN_CONTEXT].io.line(start_line .. -1)
      # special "(eval...)" descriptor?
      when /^\(eval.+\)$/
        EVAL_LINES__[filename][start_line .. -1]
      # regular file
      else
        # Ruby already parsed this file? (see disclaimer above)
        if lines = SCRIPT_LINES__[filename]
          lines[(start_line - 1) .. -1]
        # If the file exists we're going to try reading it in
        elsif File.exist?(filename)
          begin
            File.readlines(filename)[(start_line - 1) .. -1]
          rescue
            nil
          end
        end
    end
  end

  def handle(proc)
    filename, line = proc.source_descriptor
    lines = get_lines(filename, line) || []

    lexer = RubyLex.new
    lexer.set_input(StringIO.new(lines.join))

    state = :before_constructor
    nesting_level = 1
    start_token, end_token = nil, nil
    found = false
    while token = lexer.token
      # we've not yet found any proc-constructor -- we'll try to find one.
      if [:before_constructor, :check_more].include?(state)
        # checking more and newline? -> done
        if token.is_a?(RubyToken::TkNL) and state == :check_more
          state = :done
          break
        end
        # token is Proc?
        if token.is_a?(RubyToken::TkCONSTANT) and
           token.instance_variable_get(:@name) == "Proc"
          # method call?
          if lexer.token.is_a?(RubyToken::TkDOT)
            method = lexer.token
            # constructor?
            if method.is_a?(RubyToken::TkIDENTIFIER) and
               method.instance_variable_get(:@name) == "new"
              unless state == :check_more
                # okay, code will follow soon.
                state = :before_code
              else
                # multiple procs on one line
                return
              end
            end
          end
        # token is lambda or proc call?
        elsif token.is_a?(RubyToken::TkIDENTIFIER) and
              %w{proc lambda}.include?(token.instance_variable_get(:@name))
          unless state == :check_more
            # okay, code will follow soon.
            state = :before_code
          else
            # multiple procs on one line
            return
          end
        elsif token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO)
          # found the code start, update state and remember current token
          state = :in_code
          start_token = token
        end

      # we're waiting for the code start to appear.
      elsif state == :before_code
        if token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO)
          # found the code start, update state and remember current token
          state = :in_code
          start_token = token
        end

      # okay, we're inside code
      elsif state == :in_code
        if token.is_a?(RubyToken::TkRBRACE) or token.is_a?(RubyToken::TkEND)
          nesting_level -= 1
          if nesting_level == 0
            # we're done!
            end_token = token
            # parse another time to check if there are multiple procs on one line
            # we can't handle that case correctly so we return no source code at all
            state = :check_more
          end
        elsif token.is_a?(RubyToken::TkfLBRACE) or token.is_a?(RubyToken::TkDO) or
              token.is_a?(RubyToken::TkBEGIN) or token.is_a?(RubyToken::TkCASE) or
              token.is_a?(RubyToken::TkCLASS) or token.is_a?(RubyToken::TkDEF) or
              token.is_a?(RubyToken::TkFOR) or token.is_a?(RubyToken::TkIF) or
              token.is_a?(RubyToken::TkMODULE) or token.is_a?(RubyToken::TkUNLESS) or
              token.is_a?(RubyToken::TkUNTIL) or token.is_a?(RubyToken::TkWHILE) or
              token.is_a?(RubyToken::TklBEGIN)
          nesting_level += 1
        end
      end
    end

    if start_token and end_token
      start_line, end_line = start_token.line_no - 1, end_token.line_no - 1 
      source = lines[start_line .. end_line]
      start_offset = start_token.char_no
      start_offset += 1 if start_token.is_a?(RubyToken::TkDO)
      end_offset = -(source.last.length - end_token.char_no)
      source.first.slice!(0 .. start_offset)
      source.last.slice!(end_offset .. -1)

      # Can't use .strip because newline at end of code might be important
      # (Stuff would break when somebody does proc { ... #foo\n})
      proc.source = source.join.gsub(/^ | $/, "")
    end
  end

  module_function :handle, :get_lines
end

class Proc #:nodoc:
  def source_descriptor
    if md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)>$/.match(old_inspect)
      filename, line = md.captures
      return filename, line.to_i
    end
  end
  
  def self.source_cache
    @source_cache ||= {}
  end

  def source=(code)
    @source = Proc.source_cache[source_descriptor.join('/')] = code
  end

  def source
    @source = Proc.source_cache[source_descriptor.join('/')]
    ProcSource.handle(self) unless @source
    @source
  end

  alias :old_inspect :inspect
  def inspect
    if source
      "proc {#{source}}"
    else
      old_inspect
    end
  end

  def ==(other)
    if self.source && other.respond_to?(:source) && other.source
      self.source == other.source
    else
      self.object_id == other.object_id
    end
  end

  def _dump(depth = 0)
    if source
      source
    else
      raise(TypeError, "Can't serialize Proc with unknown source code.")
    end
  end

  def to_yaml(*args)
    self.source # force @source to be set
    super.sub("object:Proc", "proc")
  end

  def self.allocate; from_string ""; end

  def self.from_string(string)
    result = eval("proc {#{string}}")
    result.source = string
    return result
  end

  def self._load(code)
    self.from_string(code)
  end

  def self.marshal_load; end
  def marshal_load; end
end

require 'yaml'
YAML.add_ruby_type(/^proc/) do |type, val|
  Proc.from_string(val["source"])
end

# EVAL_LINES__ = Hash.new
# 
# alias :old_eval :eval
# def eval(code, *args)
#   context, descriptor, start_line, *more = *args
#   descriptor ||= "(eval#{code.hash})"
#   start_line ||= 0
#   lines ||= code.grep(/.*/)
#   EVAL_LINES__[descriptor] ||= Array.new
#   EVAL_LINES__[descriptor][start_line, lines.length] = lines
#   old_eval(code, context, descriptor, start_line, *more)
# end


if __FILE__ == $0 then
  require "pstore"

  code = lambda { puts "Hello World!" }

  File.open("proc.marshalled", "w") { |file| Marshal.dump(code, file) }
  code = File.open("proc.marshalled") { |file| Marshal.load(file) }

  code.call

  store = PStore.new("proc.pstore")
  store.transaction do
    store["proc"] = code
  end
  store.transaction do
    code = store["proc"]
  end

  code.call

  File.open("proc.yaml", "w") { |file| YAML.dump(code, file) }
  code = File.open("proc.yaml") { |file| YAML.load(file) }

  code.call
end