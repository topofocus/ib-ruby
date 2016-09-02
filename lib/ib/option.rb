module OptionHandling
=begin

=end

  def initialize_option_handling
    tws.subscribe( :TickPrice,:TickSize,:TickString,:TickGeneric, :TickEFP) do |msg|
      logger.progname = 'Gateway#option_handling'
      contract = advisor.contracts.detect{|y| y.con_id == msg.ticker_id }
      if contract.is_a? IB::Contract

	case msg
	when IB::Messages::Incoming::TickGenric

	when IB::Messages::Incoming::TickPrice
	  ## implied Vola; historic vola
	when IB::Messages::Incoming::TickPrice
	  if prices[msg.ticker_id].nil?
	    prices[msg.ticker_id] = {msg.type => msg.price }
	  else
	    prices[msg.ticker_id][msg.type]=msg.price
	  end
	end
      end
       send_message IB::Messages::Outgoing::CancelImpliedVolatility msg.ticker_id
       send_message IB::Messages::Outgoing::CancelOptionPrice msg.ticker_id

    end
=begin
Gateway#RequestOpenOrders  aliased as UpdateOrders

Resets the order-array for each account first.
Requests all open (eg. pending)  orders from the tws 

=end
    def  calculate_option_price contract, underlying_price: 0, volatility:  
      ## add contract to advisor.contracts array
      contract.verify do |c|
             advisor.contracts.update_or_create c, :con_id
	     send_message IB::Messages::Outgoing::CalculateOptionPrice.new(
	        :request_id => c.con_id,
		:contract => c,
		:volatility => volatility,
		:under_price => underlying_price.zero? c.contract_detail.underprice : underlying_price 
	     )
      end
    end

    def  calculate_option_volatility contract, underlying_price: 0, :option_price: 0
      ## add contract to advisor.contracts array
      contract.verify do |c|
             advisor.contracts.update_or_create c, :con_id
	     send_message IB::Messages::Outgoing::CalculateImpliedVolatility.new(
	        :request_id => c.con_id,
		:contract => c,
		:option_price => option_price.zero? ? c.price : option_price,
		:under_price => underlying_price.zero? ? c.contract_detail.underprice : underlying_price
	     )
      end
    end

    alias update_orders request_open_orders 
  end # module
end
