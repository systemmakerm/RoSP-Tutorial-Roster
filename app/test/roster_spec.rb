describe "Roster" do
  #this test always fails, you really should have tests!

  it "名簿一覧にデータが無いか？" do
    get :index
    assings[:rosters].should == Roster.find_all
    assings[:rosters].should == []
  end
end