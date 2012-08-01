require 'rho/rhocontroller'
require 'helpers/browser_helper'

class RosterController < Rho::RhoController
  include BrowserHelper

  # GET /Roster
  def index
    @rosters = Roster.find(:all)
    render :back => '/app'
  end

  # GET /Roster/{1}
  def show
    @roster = Roster.find(@params['id'])
    if @roster
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Roster/new
  def new
    @roster = Roster.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Roster/{1}/edit
  def edit
    @roster = Roster.find(@params['id'])
    if @roster
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Roster/create
  def create
    @roster = Roster.create(@params['roster'])
    redirect :action => :index
  end

  # POST /Roster/{1}/update
  def update
    @roster = Roster.find(@params['id'])
    @roster.update_attributes(@params['roster']) if @roster
    redirect :action => :index
  end

  # POST /Roster/{1}/delete
  def delete
    @roster = Roster.find(@params['id'])
    @roster.destroy if @roster
    redirect :action => :index  
  end
  
  def capture
    id = strip_braces(@params["id"])
    # カメラ機能の呼び出し
    Camera::take_picture(url_for(:action => :capture_callback, :id => id))
    render :back => url_for(:action => :show, :id => id)
  end
  
  def capture_callback
    # @params["status"]には、カメラの撮影結果が入る
    if @params["status"] == "ok"
      @roster = Roster.find(@params["id"])
      # 該当の名簿に既に写真が保存されている場合、その写真を削除する
      if @roster.image_uri && File.exists?(@roster.image_uri)
        File.unlink(@roster.image_uri)
      end
      @roster.update_attributes("image_uri" => @params["image_uri"])
      Alert.show_popup("写真を登録しました。")
      WebView.navigate(url_for(:action => :show, :id => @roster.object))
    else
      # カメラの撮影に失敗した場合
      Alert.show_popup("写真の撮影に失敗しました。")
      WebView.navigate(url_for(:action => :show, :id => strip_braces(@params["id"])))
    end
  end
  
  def set_address_ajax
    if GeoLocation.known_position?
      @latitude = GeoLocation.latitude
      @longitude = GeoLocation.longitude
    else
      # テスト用で現在地が取得できない環境では、
      # システム工房エムの現在地を入れる
      @latitude = 35.459667
      @longitude = 133.078492
    end
    geo = Rho::AsyncHttp.get(
      :url => "http://maps.google.com/maps/geo?oe=utf-8&ll=#{@latitude},#{@longitude}&output=json"
    )
    if geo["status"] == "ok"
      geo_body = Rho::JSON.parse(geo["body"])
      place = geo_body["Placemark"].detect do |pl|
        pl["AddressDetails"]["Country"]["AdministrativeArea"].has_key?("Locality")
      end
      if place
        # 返ってきたJSONファイルから住所を取得
        pref = place["AddressDetails"]["Country"]["AdministrativeArea"]["AdministrativeAreaName"]
        local = place["AddressDetails"]["Country"]["AdministrativeArea"]["Locality"]
        city = local["LocalityName"]
        address = local["DependentLocality"]["DependentLocalityName"]
        address += local["DependentLocality"]["Thoroughfare"]["ThoroughfareName"]
        address = pref + city + address
        # Javascriptを実行
        WebView.execute_js("setFieldValue('roster[address]', '#{address}')")
        render :string => ""
      end
    else
      Alert.show_popup("現在地が取得できませんでした。")
    end
  end
end
