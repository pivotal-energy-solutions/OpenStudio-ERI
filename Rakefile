# frozen_string_literal: true

# This file is only used to run all tests and collect results on the CI.
# All rake tasks have been moved to tasks.rb.

require 'rake'
require 'rake/testtask'

desc 'Run all tests'
Rake::TestTask.new('test_all') do |t|
  t.test_files = Dir['rulesets/tests/*.rb'] + Dir['workflow/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run measure unit tests'
Rake::TestTask.new('test_measures') do |t|
  t.test_files = Dir['rulesets/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run ERI tests'
Rake::TestTask.new('test_eri') do |t|
  t.test_files = Dir['workflow/tests/energy_rating_index_test.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run Real Home tests'
Rake::TestTask.new('test_real_homes') do |t|
  t.test_files = Dir['workflow/tests/real_homes_test.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run RESNET/ES/ZERH tests'
Rake::TestTask.new('test_resnet_es_zerh') do |t|
  t.test_files = Dir['workflow/tests/*test.rb'] - Dir['workflow/tests/real_homes_test.rb'] - Dir['workflow/tests/energy_rating_index_test.rb']
  t.warning = false
  t.verbose = true
end
