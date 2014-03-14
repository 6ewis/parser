=============================================================
SLOW PARSER - data file full of energy utility meter readings
=============================================================

How to run it.
install ruby
type irb in the terminal
then load 'parse_energy.rb'

you can then play around with the following commands 

r = Reporting.new "./pulse_data.txt", 15
 
r.show_all_data
r.show_unique_customers
r.show_customers_with_gas    
r.show_customers_with_electricity
r.show_all_data :with_table
r.show_unique_customers :with_table
r.show_customers_with_gas  :with_table
r.show_customers_with_electricity :with_table
r.show_avg_consumption_per_bill_month 
r.show_avg_consumption_per_bill_month :electricity
r.show_avg_consumption_per_bill_month :gas
r.show_nbr_of_meters_readings_per_number_of_customers
r.show_nbr_of_meters_readings_per_number_of_customers :electricity
r.show_nbr_of_meters_readings_per_number_of_customers :gas
puts "\nMethods available: #{Reporting.instance_methods(false)}"

=============================================================
FAST PARSER - data file full of energy utility meter readings
=============================================================

You can now run it from the cmd line
  
ruby fast_parser.rb (a prompt will ask for the filename)

or ruby fast_parser.rb filename 

You can also chmod +x fast_parser and execute it directly

fast-parser as at least 20 x improvement on speed. It handles the 100K line file I have in 10 seconds

