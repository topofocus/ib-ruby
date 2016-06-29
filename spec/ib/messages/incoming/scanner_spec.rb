require 'message_helper'

describe IB::Messages::Incoming do

  context 'Message received from IB', :connected => true do

    before(:all) do
      gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, connect:true, serial_array: false, host: 'localhost'))
      @ib = gw.tws
      @ib.subscribe(IB::Messages::Incoming::ScannerParameters) do |msg|
	puts msg.inspect
      end
    end

    after(:all) { IB::Gateway.current.disconnect }

    it "test scanner" do
      ib.send_message IB::Messages::Outgoing::RequestScannerSubscription.new(:qa
    end
  end #
end # describe IB::Messages:Incoming
