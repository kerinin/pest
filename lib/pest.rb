$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'uuidtools'
require 'csv'

require "pest/version"

require "pest/function"
require "pest/function/probability"
require "pest/function/entropy"

require "pest/data_set"
require "pest/data_set/hash"
require "pest/data_set/narray"
require "pest/data_set/r"

require "pest/estimator"
require "pest/estimator/frequency"

module Pest
  CACHE_TO_FILE = false
end
