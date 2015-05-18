require 'integration_helper'





describe "Build Contract-Database", :connected => true, :integration => true do

  before(:all) do
    verify_account
    #IB::Contract.all{|x| x.destroy }
  end

 # after(:all) { IB::Contract.all{|x| x.destroy }}#close_connection }
## An Order requires a valid contact-record to act on.
## The idea is to maintain a database of contract-records to refer on.
## Here we test the integrity of the database
  #first the database is build
  #some contents are changed
  #then it is updated
  let!( :list_of_symbols ) {	[ "AGU", "DE", "LNN", "TAP", "GPS", "T", "A", "GE" ] }

  it{ expect( list_of_symbols ).to have_exactly(8).items }
  context "BuildDB" do
    let!( :number_of_datasets ){ list_of_symbols.size }


    let( :db ){ list_of_symbols.map{|s| is= IB::Stock.new(symbol:s); is.verify; is } }
    let( :agu) { IB::Stock.new( symbol:list_of_symbols.first )}
    let( :agu_canada) { IB::Stock.new symbol:'AGU', currency:'CAD' }
    it{ expect( db ).to have_exactly(number_of_datasets).items }
    it{ expect( IB::Contract.count).to eq number_of_datasets }
    it "update contract_data ", focus:true do
      db.each do |y| 
	expect{ y.verify }.not_to change{ y }
      end
    end
    #  it "try to save duplicate Dataset" do
#	  expect{ agu.read_contract_from_tws }.to raise_error ActiveRecord::RecordNotUnique
#	  # important: ensure that invalid datasets are destroyed immediately 
#	  agu.destroy
#  end

  it "try to save the same stock in a different currency" do
	  ## the first using of the var (agu_canada) creates it, which should be reflected in the db
	  expect{ agu_canada }.to change{ IB::Contract.count }.by(1)
	  # the second using does not lead to a creation of a db-object
	  expect{ agu_canada.update_contract }.not_to raise_error 
  end



  end #context
end # describe

