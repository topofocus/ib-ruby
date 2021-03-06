##  ib-ruby –  Introduction to the Gateway

Ib-ruby is a pure ruby implementation to access the IB-TWS-API.
It mirrors most of the information provided by the TWS as ActiveModel-Objects.

### Connect to the TWS

Assuming, the TWS ( FA-Account, aka »Friends and Family«,  is needed ) is running 
and API-Connections are enabled,  just instantiate IB::Gateway to connect i.e.

```
gw = IB::Gateway.new connect: true, host: 'localhost:7496' , client_id: 1001
# for possible argumets look into lib/ib/gateway.rb
# use host: 'localhost.4001' to connect to a running TWS-Gateway
```

The Connection-Object, which provides the status and recieves subscriptions of TWS-Messages, is
always present as 

```
  tws = IB::Gateway.tws 
or
  tws = gw.tws
and also
  tws = IB::Gateway.current.tws

```
The Gateway acts as a Proxy to the Connection-Object and provides a simple Security-Layer.
The method »connect« without an argument waits approx. 1 hour for the TWS to connect to.
Every 60 seconds it tries to establish a connection. The argument determines the count of repetitions.
IB::Gateway reconnects automatically if the transmission was interrupted. 
It is even possible to switch from one TWS to another

```
  gw.change_host host:  'new_host:new_port'  
  gw.prepare_connection
  gw.connect
```


### Read Account-Data

If you open the TWS-GUI you get a nice overview of all account-positions, the distribution of 
currencies, margin-using, leverage and other account-measures.

These informations are available through the API, too. 
One can send a message to the tws and simply wait for the response.

The Gateway handles anything in the background and provides essential account-data
in a structured manner:


```
  gw.get_account_data
  gw.request_open_orders
```
leads to this ActiveModel object-tree

 * Gateway 
  * Account 
   * -> PortfolioValues
   * -> AccountValues
   * -> Orders
   * -> Contracts

IB::Gateway provides an array of active Accounts. One is a Advisor-Account. 
Several tasks are delegated to the accounts. 
An Advisor cannot submit an order for himself. 
A User can only place orders for himself. 

The TWS sends data arbitrarily. Ib-ruby has to process them concurrently. Someone has to take care
of possible data-collistions. Therefor its not advisable to access the TWS-Data directly.
IB::Gateway provides thread safe wrapper-nethods 
```
 gw.for_active_accounts do |account |   ... end
 gw.for_selected_account( ib_account_id ) do |account|  ... end
```
However, if you know what you are doing and no interference with TWS-Messages is expected,
Advisor and Users are directly available through
```
 gw.advisor	       --> Account-Object
 gw.active_accounts[n] --> Account-Object 
 gw.active_accounts    --> Array of user-accounts 	
```



PortfolioValues represent the portfolio-positions of the specified Account. 
Each PortfolioValue is an ActiveModel
and has the following structure, 

```
IB::PortfolioValue:  
    position: (integer), market_price: (float), market_value: (float), average_cost: (float)
    unrealized_pnl: (float), realized_pnl: (float), created_at: (date_time), updated_at: (date_time),
    contract: (IB::Contract),
    created_at: (date_time), updated_at: (date_time)
```
As usual, attributes are accessible through  PortfolioValue[:attribute], PortfolioValue['attribute']
or PortfolioValue.attribute and even PortfolioValue.call(attribute)
 
AccountValues prepresent any property of the Account, as displayed in the Account-Window of the TWS.
Each record has this structure:
```
IB::AccountValue:
    key: (string),
    value: (string)
    currency: (string)
    created_at: (date_time), updated_at: (date_time)
```

There is a simple method: *IB::Account#SimpleAccountDateScan* to select one or a group of 
AccountValues: *IB::Account#simple_account_data_scan* search_key, search_currency 
The parameter »search_key« is treated as a regular-expression, the parameter »currency« is optional.
Most AccountValue-Keys are split into the currencies present in the account.
To retrieve an ordered list  this snipplet helps

```
     account = gw.active_accounts[1]
     account_value = ->(item) do
       array = account.simple_account_data_scan(item).map{ |y| 
	      [y.value,y.currency] unless y.value.to_i.zero?  }.compact
       array.sort{ |a,b| b.last == 'BASE' ? 1 :  a.last  <=> b.last } # put base element in front
     end

     account_value['TotalCashBalance']
     => [["682343", "BASE"], ["1829", "AUD"], ["629503", "EUR"], ["-23081", "JPY"], ["56692", "USD"]]
```

Open (pending) Orders are retrieved by *gw.request_open_orders*. IB::Gateway, in this case the module
OrderHandling (in ib/order_handling.rb) updates the »orders«-Array of each Account. 
The Account#orders-Array consists of IB::Order-Entries:


```
IB::Order: local_id: (integer), side: "B/S", quantity: (integer), 
	   order_type: (validOrderType), 
	   limit_price:(float), aux_price:(float),
	   tif:("DAY/GTC/GTD"), order_ref: (string), 
	   perm_id: (integer), 
	   transmit: (boolean),
	   order_states: (array of IB::OrderState),
	   contract: (IB::Contract),
	   created_at: (date_time), updated_at: (date_time)
	   (only essential attributes are included)   

```
If an order gets filled while IB::Gateway is active, the IB::Account#Orders-Entries are updated.


## Place, modify and delete Order

To place an Order, one has to specify the IB::Contract and has to define the IB::Order itself.
Contracts are best identified by their *con_id*.
To place an order in as secure manner, first the contract has to be verified. 
Therfor we have *IB::Contract#Verify* 

``` Ruby
  contract = IB::Stock.new symbol: 'RRD'
  --> #<IB::Stock:0x00000002bb1eb0 @attributes={"symbol"=>"RRD",  "right"=>"", "include_expired"=>false, 
		"sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}> 
  contract.verify
  --> 1
  contract --> #<IB::Stock:0x00000002bb1eb0 @attributes={"symbol"=>"RRD",
		 "right"=>"", "include_expired"=>false, "sec_type"=>"STK",
		 "currency"=>"USD", "exchange"=>"SMART", "expiry"=>"", "strike"=>0.0,
		 "local_symbol"=>"RRD", "con_id"=>6507, "multiplier"=>0,
		 "primary_exchange"=>"NASDAQ"},
	        @contract_detail=#<IB::ContractDetail:0x00000002c128c8 (...)

```
  *IB::Contract#Verify* returns the number of detected contracts and updates the object itself.
  
  *IB::Account#PlaceOrder* verifies the Contract-Record befor trying to place the order.
  After the order is transmitted to the TWS several status messages are send. They are 
  captured by Gateway#OrderHandling, where the IB::Model-Objects are updated.
  Therefor a thread-safe solution of the complete order-process is immanent. 
  
  
 Although *IB::Connection#PlaceOrder* still works, its advisable to use the save *place_order* method
  of IB::Account
``` ruby

    gw= IB::Gateway.new  connect:true
    contract = IB::Stock.new symbol: 'RRD'
    buy_order = IB::Order.new total_quantity: 100, limit_price: 21.00,
    	                               action: :buy, :order_type: :limit, 
				       tif: 'GTC'
    IB::Gateway.tws.subscribe( :OpenOrder     ) { |msg| puts "Placed: #{msg.order}!"     }
    IB::Gateway.tws.subscribe( :ExecutionData ) { |msg| puts "Filled: #{msg.execution}!" }
    
    local_id= gw.for_selected_account( 'U123456' ) do |account|
	account.place_order order: buy_order, contract: contract
    end

```
  The order is fired only, if  the contract was successfully validated by the TWS

[Continue](integration.md)






