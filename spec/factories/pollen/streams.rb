# frozen_string_literal: true

FactoryBot.define do
  factory :stream, class: 'Pollen::Stream' do
    owner { build(:user) }
    timeout { 120 }
  end
end
