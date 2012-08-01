require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'json'

class RosterServerController < Rho::RhoController
  include BrowserHelper
  
  SERVER_ADDRESS = "http://192.168.1.196:3000"

  # GET /RosterServer
  def index
#    @rosterservers = RosterServer.find(:all)
    http = Rho::AsyncHttp.get(:url => "#{SERVER_ADDRESS}/rosters.json")
    @rosterservers = http["body"].map{|r|RosterServer.new(r)}
    render :back => '/app'
  end

  # GET /RosterServer/{1}
  def show
#    @rosterserver = RosterServer.find(@params['id'])
    id = strip_braces(@params["id"])
    http = Rho::AsyncHttp.get(:url => "#{SERVER_ADDRESS}/rosters/#{id}.json")
    @rosterserver = RosterServer.new(http["body"]) if http["body"]
    if @rosterserver
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /RosterServer/new
  def new
    @rosterserver = RosterServer.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /RosterServer/{1}/edit
  def edit
#    @rosterserver = RosterServer.find(@params['id'])
    id = strip_braces(@params["id"])
    http = Rho::AsyncHttp.get(:url => "#{SERVER_ADDRESS}/rosters/#{id}.json")
    @rosterserver = RosterServer.new(http["body"]) if http["body"]
    if @rosterserver
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /RosterServer/create
  def create
#    @rosterserver = RosterServer.create(@params['rosterserver'])
    json = ::JSON.generate(:roster => @params["rosterserver"])
    Rho::AsyncHttp.post(
      :url => "#{SERVER_ADDRESS}/rosters.json",
      :body => "json=#{json}",
      :callback => url_for(:action => :create_callback)
    )
    redirect :action => :index
  end
  
  def create_callback
    if @params["status"] == "ok" && @params["body"] == "OK"
      msg = "作成しました。"
    else
      msg = "作成に失敗しました。"
    end
    Alert.show_popup(msg)
    WebView.navigate(url_for(:action => :index))
  end

  # POST /RosterServer/{1}/update
  def update
#    @rosterserver = RosterServer.find(@params['id'])
#    @rosterserver.update_attributes(@params['rosterserver']) if @rosterserver
    id = strip_braces(@params["id"])
    json = ::JSON.generate(:roster => @params["rosterserver"])
    Rho::AsyncHttp.post(
      :url => "#{SERVER_ADDRESS}/rosters/#{id}.json",
      :http_command => "PUT",
      :body => "json=#{json}",
      :callback => url_for(:action => :update_callback)
    )
    redirect :action => :index
  end
  
  def update_callback
    if @params["status"] == "ok" && @params["body"] == "OK"
      msg = "更新しました。"
    else
      msg = "更新に失敗しました。"
    end
    Alert.show_popup(msg)
    WebView.navigate(url_for(:action => :index))
  end

  # POST /RosterServer/{1}/delete
  def delete
#    @rosterserver = RosterServer.find(@params['id'])
#    @rosterserver.destroy if @rosterserver
    id = strip_braces(@params["id"])
    Rho::AsyncHttp.post(
      :url => "#{SERVER_ADDRESS}/rosters/#{id}.json",
      :http_command => "DELETE",
      :callback => url_for(:action => :delete_callback)        
    )
    redirect :action => :index  
  end
  
  def delete_callback
    if @params["status"] == "ok" && @params["body"] == "OK"
      msg ="削除しました。"
    else
      msg = "削除に失敗しました。"
    end
    Alert.show_popup(msg)
    WebView.navigate(url_for(:action => :index))
  end
end
