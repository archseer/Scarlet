require 'mongo_mapper'

module Scarlet
  class Issue
    include MongoMapper::Document
    validates_presence_of :msg
    key :msg, String
    key :by,  String
    timestamps!
  end
end
