# frozen_string_literal: true

namespace :pollen do
  task prune_streams: :environment do
    scope = Pollen::Stream.where('created_at <= :time', time: Time.zone.now - Pollen.controller.configuration.retention)
    scope.count.tap do |count|
      scope.delete_all
      puts "Pruned #{count} old streams"
    end
  end
end
