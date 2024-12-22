# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen do
  it 'exposes its version' do
    expect(Pollen::VERSION).not_to be_nil
  end

  it 'creates a singleton server' do
    server = Pollen.server
    expect(server).to be_instance_of(Pollen::Server)
    expect(Pollen.server).to eq server
  end

  it 'creates a singleton controller' do
    controller = Pollen.controller
    expect(controller).to be_instance_of(Pollen::Controller)
    expect(Pollen.controller).to eq controller
  end

  it 'creates a singleton object to handle common configuration parameters' do
    common = Pollen.common
    expect(common).to be_instance_of(Pollen::Common)
    expect(Pollen.common).to eq common
  end
end
