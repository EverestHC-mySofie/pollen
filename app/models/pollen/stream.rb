# frozen_string_literal: true

module Pollen
  class Stream < ApplicationRecord
    belongs_to :owner, class_name: Pollen.common.configuration.owner_class

    enum :status, pending: 0, completed: 10, failed: 20

    validates :timeout, numericality: { only_integer: true, greater_than: 0 }

    before_validation(on: :create) do
      self.id = SecureRandom.uuid unless id.present?
    end
  end
end
