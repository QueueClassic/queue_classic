$:.unshift File.expand_path("../lib", __FILE__)
require 'queue_classic'

worker = QC::Worker.new
worker.start
