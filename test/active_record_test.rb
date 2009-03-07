require File.expand_path(File.dirname(__FILE__) + '/abstract_unit')

class Model < ActiveRecord::Base
  attr_accessor :what
  
  def self.columns
    []
  end
  def self.connection
  end
end

class ActiveRecordTest < Test::Unit::TestCase
  def setup
    Background::Config.default_handler = [:test, :forget]
    Background::Config.default_error_reporter = :test
  end
  
  def teardown
    Background::TestHandler.reset
    Background::TestErrorReporter.last_error = nil
  end
  
  def test_should_correctly_marshal_active_record_objects
    model = Model.new
    model.id = 10
    assert_equal model.id, Marshal.load(Marshal.dump(model.clone_for_background)).id
  end
  
  def test_should_correctly_marshal_singleton_active_record_objects
    model = Model.new
    model.id = 10
    def model.some_method
    end
    
    assert_equal model.id, Marshal.load(Marshal.dump(model.clone_for_background)).id
  end
  
  def test_should_correctly_marshal_active_record_instance_variables
    model = Model.new
    model.what = 10
    
    assert_equal model.what, Marshal.load(Marshal.dump(model.clone_for_background)).what
  end
end
