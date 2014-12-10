shared_examples "school" do |type|
  Test_school = []
  it "can get max page num" do
    max_page_num = eval("::POI::School::#{type}").max_page_num
  end

  it "can get schools in page" do
    schools = eval("::POI::School::#{type}").schools_in_page(1)
    Test_school.push schools[0]
  end

  it "can get schools extra info" do
    school = Test_school.pop
    school = eval("::POI::School::#{type}").get_info(school)
  end
end

describe ::POI::School do
  it_should_behave_like( 'school', 'Elementary' )
end

describe ::POI::School do
  it_should_behave_like( 'school', 'Middle' )
end

describe ::POI::School do
  it_should_behave_like( 'school', 'High' )
end
