# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pollen::Stream do
  it 'assigns an UUID on create' do
    expect(create(:stream).id).to match(Pollen::ServerConfiguration::UUID_REGEXP)
  end

  it 'ensures timeout is greater than zero' do
    stream = build(:stream, timeout: 0)
    expect(stream.valid?).to eq false
    expect(stream.errors.messages[:timeout]).to eq ['must be greater than 0']
  end
end
