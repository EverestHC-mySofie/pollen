# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pollen::Engine do
  it 'appends the middleware after actions dispatch executor' do
    middleware = Rails.application.middleware
    expect(middleware.find_index(Pollen::Middleware)).to eq(middleware.find_index(ActionDispatch::Executor) + 1)
  end
end
