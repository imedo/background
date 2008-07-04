require 'rubygems'
require 'activesupport'
require 'test/unit'
require File.dirname(__FILE__) + '/../init'

class SomeBackgroundClass
  def add_three(a, b, c)
    a + b + c
  end
  
  def puts_something
    puts "something"
  end
end

class BackgroundTest < Test::Unit::TestCase
  def setup
    Background::Config.default_handler = [:test, :forget]
    Background::Config.default_error_reporter = :test
  end
  
  def teardown
    Background::TestHandler.reset
    Background::TestErrorReporter.last_error = nil
  end
  
  def test_should_run_code_block_in_background
    background do
      puts "lala"
    end
    assert Background::TestHandler.code =~ /"lala"/
    assert Background::TestHandler.executed
  end
  
  def test_should_store_locals
    a = Regexp.new('x')
    b = String.new('hello')
    background :locals => { :a => a, :b => b } do
      puts "lala"
    end
    assert_equal Regexp, Background::TestHandler.locals[:a].class
    assert_equal String, Background::TestHandler.locals[:b].class
  end
  
  def test_should_work_with_unduppable_locals
    a = 10
    b = :symbol
    c = nil
    background :locals => { :a => a, :b => b, :c => c } do
      puts "lala"
    end
    assert_equal 10, Background::TestHandler.locals[:a]
    assert_equal :symbol, Background::TestHandler.locals[:b]
    assert_equal nil, Background::TestHandler.locals[:c]
  end
  
  def test_should_use_correct_self_object
    "hallo".background {}
    assert_equal "hallo", Background::TestHandler.self_object
  end
  
  def test_should_decorate_method_if_called_in_class_without_block
    SomeBackgroundClass.background :add_three, :params => ['a', 'b', 'c']
    obj = SomeBackgroundClass.new
    assert obj.respond_to?(:add_three_with_background)
    assert obj.respond_to?(:add_three_without_background)
    assert_equal 6, obj.add_three_without_background(1, 2, 3)
    assert_not_equal 6, obj.add_three_with_background(1, 2, 3)
  end
  
  def test_should_decorate_method_without_parameters
    SomeBackgroundClass.background :puts_something
    obj = SomeBackgroundClass.new
    assert obj.respond_to?(:puts_something_with_background)
    assert obj.respond_to?(:puts_something_without_background)
  end
  
  def test_should_execute_block_with_in_process_handler
    $global_variable = 10
    background :handler => :in_process do
      $global_variable *= 2
    end
    assert_equal 20, $global_variable
  end
  
  def test_should_use_specified_handler_and_fallback
    a = 10
    actual_handler = background :handler => [:in_process, :test], :locals => { :a => a } do
      raise "lala"
    end
    assert_equal "lala", Background::TestErrorReporter.last_error.message
    assert_equal :test, actual_handler
    # check if test handler was executed
    assert Background::TestHandler.executed
  end
  
  def test_should_use_fallback_on_failure
    Background::TestHandler.fail_next_time = true
    actual_handler = background :handler => [:test, :forget] do
      puts "lala"
    end
    assert_not_nil Background::TestErrorReporter.last_error
    assert_equal :forget, actual_handler
  end
  
  def test_should_use_options_hash_for_handler
    background :handler => [{:test => { :some_option => 2 }}] do
      puts "lala"
    end
    assert_not_nil Background::TestHandler.options
    assert_equal 2, Background::TestHandler.options[:some_option]
  end
end
