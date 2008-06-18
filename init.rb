# Include hook code here

require File.dirname(__FILE__) + '/lib/core_ext/proc_source'
require File.dirname(__FILE__) + '/lib/background'
require File.dirname(__FILE__) + '/lib/core_ext/background'
Dir.glob(File.dirname(__FILE__) + '/lib/core_ext/handlers/*.rb').each do |handler|
  require handler
end
Dir.glob(File.dirname(__FILE__) + '/lib/core_ext/error_reporters/*.rb').each do |reporter|
  require reporter
end
