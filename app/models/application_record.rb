class ApplicationRecord < ActiveRecord::Base
  include Turbo::Broadcastable
  primary_abstract_class
end
