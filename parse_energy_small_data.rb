require 'csv'
require 'active_support/inflector' 
require "benchmark"
 
Customer = Struct.new(:cust_id,
                      :elect_or_gas, 
                      :disconnect_doc, 
                      :move_in_date, 
                      :move_out_date, 
                      :bill_year,
                      :bill_month,
                      :span_days,
                      :meter_read_date,
                      :meter_read_type,
                      :consumption,
                      :exception_code,
                      :data 
                      ) 
 
class Parser
  attr_accessor :customers 
 
  def initialize filename
    self.customers = [] 
    deserialize_users filename
    serialize_users
  end
 
  def deserialize_users filename
    CSV.foreach(filename, col_sep: "|")  do |row|
      next if row.join == /^[:space:]/ # make sure that all cases are taken care of e,g ["","",""," "]
      sanitize_values(row)
      customers << Customer.new(*row, row)
    end
    customers
  end
 
  def serialize_users
    CSV.open("./serialized_users.csv", "w+") do |csv| 
      customers.each do |c|
        csv << c.data  
      end
    end
  end
 
  def sanitize_values(row)
    row.map!(&:to_s)
  end
end
 
module Statistics 
 
  attr_accessor :parser, :output_size
 
  def initialize data , output_size
    self.parser = Parser.new data
    self.output_size = output_size
  end
 
  def customers
    parser.customers
  end
 
  def unique_customers
    customers.uniq(&:cust_id )
  end
 
  def customers_with_electricity#_ONLY
    customer = customers.select { |customer| ['1', 'ElecOrGas'].include?(customer.elect_or_gas) }
  end
 
  def customers_with_gas#_ONLY
    customers.select { |customer| ['2', 'ElecOrGas'].include?(customer.elect_or_gas) }
  end
 
 
  def customers_bill_month month , resource = nil
    [:customers_with_electricity, :customers_with_gas, :customers].each do |receiver|
      break send(receiver).select {|customer| customer.bill_month == "#{month}"} if receiver.to_s.end_with?(resource.to_s)
    end
  end
 
  def list_of_nbr_of_meter_readings_and_customer_ID resource = nil
    customers_id = 
    [:customers_with_electricity, :customers_with_gas, :customers].each do |receiver|
      break send(receiver).collect { |customer| next if customer.cust_id == "CustID"; customer.cust_id}.compact \
      if receiver.to_s.end_with?(resource.to_s)
    end
    customers_id.map do |customer_id| 
      [customers_id.count(customer_id), customer_id]
    end.uniq
  end 
 
  def list_nbr_of_meters_readings resource = nil
    list_of_nbr_of_meter_readings_and_customer_ID(resource).transpose.first
  end
 
  def nbr_of_customers_with_that_many_readings arg, resource = nil
    list_nbr_of_meters_readings(resource).count(arg)
  end
 
  def list_of_unique_nbr_of_meter_readings_and_number_of_customers resource = nil
    list_of_nbr_of_meter_readings_and_customer_ID(resource).map { |a,_| [a, nbr_of_customers_with_that_many_readings(a,resource) ]}.
    uniq.sort
  end
 
  def avg_consumption_month month , resource = nil
    unless customers_bill_month(month, resource).empty? 
     ( (customers_bill_month(month, resource).inject(0) { |sum, n| sum + n.consumption.to_i } ) /  customers_bill_month(month, resource).
      length ) 
    else
      0
    end
  end
 
end
 
class Reporting
  include Statistics
 
  def show_all_data arg=nil
    format_show customers if arg == :with_table
    puts "\nNumber of customers: #{customers.count - 1}"
  end
  
  [:unique_customers, :customers_with_electricity, :customers_with_gas].each do |meth|
    define_method "show_#{meth}" do |arg = nil|
      format_show send(meth) if arg == :with_table
      puts "\nNumber of #{meth.to_s.humanize}: #{send(meth).count - 1}"
    end
  end
 
  def show_avg_consumption_per_bill_month resource = nil
    print "\n\nAVERAGE CONSUMPTION PER BILL MONTH #{'PER ' + resource.to_s.upcase if resource} ACROSS ALL CUSTOMERS\n\n"
    print "MONTHS".center(output_size*2) + "|" + "AVERAGE CONSUMPTION(S)".center(output_size*2) + "\n\n"
    total_avg_consumption = []
    (1..12).each do |i| 
      puts "\n\n" + "#{ Date::MONTHNAMES[i]}".center(output_size*2) + "|" + "#{avg_consumption_month i, resource}".center(output_size*2)
      total_avg_consumption << avg_consumption_month(i, resource)
      end
      puts "\n\n" + "TOTAL AVERAGE CONSUMPTION".center(output_size*2) + "|" + "#{total_avg_consumption.inject(:+) / total_avg_consumption.length}".center(output_size*2)
  end
 
  def show_nbr_of_meters_readings_per_number_of_customers resource = nil
    print "\n\nNUMBER OF METERS READINGS PER NUMBER OF CUSTOMERS WITH THAT MANY READINGS #{'(' + resource.to_s.upcase + ' ONLY)' if resource}\n\n"
    print "#{'Number of meter readings'}".center(output_size*2) + "|" + "#{'Number of customers'}".center(output_size*2) + "\n\n"
    list_of_unique_nbr_of_meter_readings_and_number_of_customers(resource).each \
    { |a,b| puts "#{a}".center(output_size*2) + "|" + "#{b}".center(output_size*2)} 
  end
 
  private
 
  def format_show customers
    customers.map do |customer|  
      puts customer.data.map { |item| item.center output_size}.join'|'
    end 
  end
 
end
 
r = Reporting.new "./pulse_data.txt", 15
 
# r.show_all_data
# r.show_unique_customers
# r.show_customers_with_gas    
# r.show_customers_with_electricity
# r.show_all_data :with_table
# r.show_unique_customers :with_table
# r.show_customers_with_gas  :with_table
# r.show_customers_with_electricity :with_table
# r.show_avg_consumption_per_bill_month 
# r.show_avg_consumption_per_bill_month :electricity
# r.show_avg_consumption_per_bill_month :gas
time = Benchmark.realtime do
r.show_nbr_of_meters_readings_per_number_of_customers
end

puts "Time elapsed #{time*1000} milliseconds"
# r.show_nbr_of_meters_readings_per_number_of_customers :electricity
# r.show_nbr_of_meters_readings_per_number_of_customers :gas
puts "\nMethods available: #{Reporting.instance_methods(false)}"
 