# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    allow(DhanHQ::Models::Instrument).to receive(:find) do |_exchange_segment, _symbol|
      FakeInstrument.build
    end
  end
end
