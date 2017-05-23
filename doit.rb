# models

class Base
  def initialize(options={})
    options.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end
end

class Brand < Base
  attr_accessor :name
  attr_accessor :locations, :menu_items, :price_levels, :order_types
  
  def initialize(options={})
    super
    @locations ||= []
    @menu_items ||= []
    @price_levels ||= []
    @order_types ||= []
  end
end

class Location < Base
  attr_accessor :name
  attr_accessor :day_parts
  
  def initialize(options={})
    super
    @day_parts ||= []
  end
end

class MenuItem < Base
  attr_accessor :name
  attr_accessor :price_assignments
  
  def initialize(options={})
    super
    @price_assignments ||= []
  end
end

class OrderType < Base
  attr_accessor :name
end

class PriceLevel < Base
  attr_accessor :name
  attr_accessor :order_type, :day_part, :location
end

class DayPart < Base
  attr_accessor :name, :start_time, :end_time
end

class PriceAssignment < Base
  attr_accessor :price_level, :price
end

# data

$brand = Brand.new(name: 'Cafe Bangarang')
$brand.locations = [
  $fidi = Location.new(name: 'FiDi'),
  $soho = Location.new(name: 'SoHo'),
]
$brand.menu_items = [
  $spicy_reuben = MenuItem.new(name: 'Spicy Reuben'),
]
$brand.order_types = [
  $dine_in_ot = OrderType.new(name: 'Dine In'),
  $take_out_ot = OrderType.new(name: 'Take Out'),
  $delivery_ot = OrderType.new(name: 'Delivery'),
]
$brand.locations.first.day_parts = $brand.locations.last.day_parts = [
  $breakfast = DayPart.new(name: 'Breakfast', start_time: 2*3600, end_time: 11*3600),
  $lunch = DayPart.new(name: 'Lunch', start_time: 11*3600, end_time: 17*3600),
  $dinner = DayPart.new(name: 'Dinner', start_time: 17*3600, end_time: 11*3600),
]
$brand.price_levels = [
  $regular = PriceLevel.new(name: 'Regular', order_type: $dine_in_ot, location: $fidi),
  $happy_hour = PriceLevel.new(name: 'Happy Hour', order_type: $dine_in_ot, day_part: $dinner, location: $fidi),
  $delivery = PriceLevel.new(name: 'Delivery', order_type: $delivery_ot, location: $fidi),
]
$spicy_reuben.price_assignments = [
  PriceAssignment.new(price_level: $regular, price: 4),
  PriceAssignment.new(price_level: $happy_hour, price: 2),
]

# logic

def seconds_now
  Time.now-Time.new(Time.now.year, Time.now.month, Time.now.day)
end

class PriceService
  def current_day_part(location)
    sn = seconds_now
    location.day_parts.detect do |dp|
      if dp.start_time < dp.end_time
        dp.start_time <= sn && dp.end_time > sn
      else
        dp.start_time < sn || dp.end_time >= sn
      end
    end
  end
  
  def current_price_level(menu_item, location, order_type)
    pa = menu_item.price_assignments.detect do |pa|
      pa.price_level.location == location &&
      pa.price_level.order_type == order_type &&
      pa.price_level.day_part == current_day_part(location)
    end
    pa ||= menu_item.price_assignments.detect do |pa|
      pa.price_level.location == location &&
      pa.price_level.order_type == order_type
    end
    pa && pa.price_level
  end
end

# tests

require 'rspec'
require 'timecop'
require 'pry'

describe PriceService do
  let(:price_service) { PriceService.new }
  
  it 'does happy hour' do
    Timecop.freeze(Time.new(2010, 10, 10, 1)) do
      price_service.current_price_level($spicy_reuben, $fidi, $dine_in_ot).
        should == $happy_hour
    end
  end
  
  it 'does dine in' do
    Timecop.freeze(Time.new(2010, 10, 10, 10)) do
      price_service.current_price_level($spicy_reuben, $fidi, $dine_in_ot).
        should == $regular
    end
  end
  
  it 'is nil for delivery' do
    Timecop.freeze(Time.new(2010, 10, 10, 1)) do
      price_service.current_price_level($spicy_reuben, $fidi, $delivery_ot).
        should be_nil
    end
  end
  
  it 'is nil for soho' do
    Timecop.freeze(Time.new(2010, 10, 10, 1)) do
      price_service.current_price_level($spicy_reuben, $soho, $dine_in_ot).
        should be_nil
    end
  end
end
