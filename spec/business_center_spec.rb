require'./spec_helper'
describe ::POI::BusinessCenter do
  it "can get city number 403" do
   expect(::POI::BusinessCenter.cities.size).to eq 403
  end

  it "can get business in guangzhou" do
    expect(::POI::BusinessCenter.centers('4')[0].keys).to eq [:center_id, :city_id, :name]
  end

end