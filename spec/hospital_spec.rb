require 'spec_helper'
describe POI::Hospital do
hospitals = POI::Hospital.new
provinces = hospitals.provinces
  it "has 31 provinces totally" do
   expect(provinces.size).to eq 31
  end

  it "the first provinces is 北京" do
   expect(provinces[0].text).to eq '北京市'
  end

cities = hospitals.cities
  it "has 452 cities totally" do
    expect(cities.size).to eq 452
  end

hosps = hospitals.hosps(cities[0]) 
  it "has 203 hospitals in 朝阳区" do
    expect( hosps.size).to eq 203
  end

end