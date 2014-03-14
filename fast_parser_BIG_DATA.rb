#!/usr/bin/env ruby
#Usage parse <argument>
require 'csv'
require 'active_support/inflector' 
require 'set'


module Printer

  def print_statistics
    show_basic_stats

    show_average_consumptions

    show_nbr_of_meters_readings_per_number_of_customers 
    show_nbr_of_meters_readings_per_number_of_customers :elect 
    show_nbr_of_meters_readings_per_number_of_customers :gas

  end

  private

  def show_basic_stats
    puts "%- 35s %10d" % ["Nbr of readings:", statistics[:nbr_of_readings]]

    [:nbr_of_unique_customers, :nbr_customers_with_electricity, :nbr_customers_with_gas].each do |meth|
      puts "%- 35s %10d" % ["#{meth.to_s.humanize}:", statistics[meth] ]
    end
  end

  def show_average_consumptions
    puts "--\nAVERAGE CONSUMPTIONS\n--"
    Date::MONTHNAMES.compact.each do |month|
      puts "%- 25s %10d" %  ["#{month} (all years)", statistics[:"consumption_#{month}"] ]
    end

    puts "%- 25s %10d" %  ["Total average consumption (all years)", statistics[:total_consumptions]]
  end


  def show_nbr_of_meters_readings_per_number_of_customers resource = nil
      print "\n\nNUMBER OF METERS READINGS PER NUMBER OF CUSTOMERS WITH THAT MANY READINGS #{'(' + resource.to_s.upcase + ' ONLY)' if resource}\n\n"
      print "#{'Number of meter readings'}".center(35) + "|" + "#{'Number of customers'}".center(35) + "\n\n"
      list_of_nbr_of_meter_readings_and_associated_number_of_customers(resource).each \
      { |a,b| puts "#{a}".center(35) + "|" + "#{b}".center(35)} 
  end

end


class Parser
  include Printer
  attr_accessor :statistics

  def initialize filename
    self.statistics = Hash.new(0)
    statistics[:list_of_unique_customers] = Set.new
    statistics[:list_customers_and_associated_nbr_of_readings] = Hash.new(0)
    statistics[:list_customers_elect_and_associated_nbr_of_readings] = Hash.new(0)
    statistics[:list_customers_gas_and_associated_nbr_of_readings] = Hash.new(0)

    deserialize_users filename
    print_statistics
  end

  def deserialize_users filename
    CSV.foreach(filename, col_sep: "|", headers: true) do |row|
      sanitize_values row
      calculate_statistics row
    end 
  end

  private

  def sanitize_values(row)  
    row["Bill Month"] = row["Bill Month"].to_i
    row["ElecOrGas"] = row["ElecOrGas"].to_i
    row["Consumption"] = row["Consumption"].to_f
  end

  def calculate_statistics row
    increment :nbr_of_readings

    unless statistics[:list_of_unique_customers].include? row["CustID"] 
      increment :nbr_of_unique_customers 
    end

    statistics[:list_of_unique_customers] << row["CustID"]
    statistics[:list_customers_and_associated_nbr_of_readings][ row['CustID'] ]         += 1 

    if row["ElecOrGas"] == 1
      increment :nbr_customers_with_electricity 
      statistics[:list_customers_elect_and_associated_nbr_of_readings][ row['CustID'] ] += 1
    elsif row["ElecOrGas"] == 2
      increment :nbr_customers_with_gas 
      statistics[:list_customers_gas_and_associated_nbr_of_readings][ row['CustID'] ]   += 1
    end

    avg_consumptions_month Date::MONTHNAMES[row["Bill Month"]] , row["Consumption"]
  end

  
  def list_of_nbr_of_meter_readings_and_associated_number_of_customers resource = nil
    stat = statistics[:"list_customers_#{(resource.to_s + '_') if resource}and_associated_nbr_of_readings"] 
    stat.delete(nil)  # {"108000601"=>4, "108000602"=>1, "108000603"=>1, nil=>1} - nil from line 104
    stat_values = stat.values
    # p stat      
    # p stat_values
    array = []
    unless stat_values.empty?
      1.upto(stat_values.max).each do |counter|
        array << [counter, stat_values.count(counter)]
      end 
    else
      array << [0,0]
    end
    array
  end

  def increment key 
    statistics[key] +=  1
  end

  def sum key, value
    statistics[key] += value
  end

  def avg_consumptions_month month , consumption
    sum :"consumption_#{month}", consumption 
    increment :"nbr_of_#{month}_bill"
    statistics[:"avg_consumption_#{month}"] = 
      statistics[:"consumption_#{month}"].fdiv statistics[:"nbr_of_#{month}_bill"]

    sum :total_consumptions, consumption
    increment :nbr_of_all_bill_month
    statistics[:avg_total_consumptions] = 
     statistics[:total_consumptions].fdiv statistics[:nbr_of_all_bill_month]
  end

end


if ARGV[0] 
  Parser.new ARGV[0] 
else
  puts "type in the filename: "
  filename = gets.chomp
  Parser.new filename
end





