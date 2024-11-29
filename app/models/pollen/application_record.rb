# frozen_string_literal: true

module Pollen
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
