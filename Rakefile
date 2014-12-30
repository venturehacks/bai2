require 'bundler/gem_tasks'

require 'rake/testtask'
require 'minitest/reporters'
Minitest::Reporters.use!([Minitest::Reporters::ProgressReporter.new])

Rake::TestTask.new do |t|
  t.pattern ='test/tests/*.rb'
end
