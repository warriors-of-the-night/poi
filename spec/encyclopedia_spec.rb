require 'spec_helper'
describe POI::Encyclopedia do
encyclopedia = POI::Encyclopedia.new

content = encyclopedia.content('广州塔')
  it "has content of 广州塔 " do
   expect(content).to eq  %Q(广州塔，是广州新电视塔的名称，建于广州市海珠区赤岗塔附近，是一座以观光旅游为主，具有广播电视发射、文化娱乐和城市窗口功能的大型城市基础设施，广州塔是广州的新地标建筑，塔整体高度达到610米，其中塔身主体454米，天线桅杆156米。)
  end

end
