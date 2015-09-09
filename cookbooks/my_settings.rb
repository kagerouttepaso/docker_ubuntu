# vim: filetype=ruby.chef
#
# Cookbook Name:: my_settings
# Recipe:: default
#
# Copyright 2014, kitsunai daisuke
#
# MIT
#
#定数定義
username="root"
cookbook_dir="/opt/chef/cookbooks"
home_dir="/root"
dotfiles_dir=home_dir+"/.dotfiles"

###Ubuntuを日本対応させる
#タイムゾーンの設定
link "/etc/localtime" do
  to "/usr/share/zoneinfo/Asia/Tokyo"
end

##aptパッケージを日本からダウンロードするように変更
file "/etc/apt/sources.list" do
  action :create
  content IO.read(cookbook_dir+ "/sources" + node[:platform_version] + ".list")
  owner 'root'
  notifies :run, "execute[apt_update]", :immediately
end

execute "apt_update" do
  action  :run
  command "apt-get update"
end

#日本語設定の作成
package "language-pack-ja" do
  action :upgrade
end
execute "update_locale" do
  action  :run
  command "update-locale LANG=ja_JP.UTF-8"
end

### 自分用カスタム

#パッケージのインストール
%w{bc git tmux vim-nox zsh make gcc autojump}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

#設定ファイルをダウンロード
git dotfiles_dir do
  action            :sync
  repository        "https://github.com/kagerouttepaso/dotfiles.git"
  user              username
  group             username
  enable_submodules true
  notifies :run, "bash[after_sync]", :immediately
end

bash "after_sync" do
  action :nothing
  cwd    dotfiles_dir
  user   username
  group  username
  environment(
    "HOME" => home_dir
  )
  code <<-EOH
  ./install.sh
  EOH
end

file home_dir+"/reconfigure_keybord.sh" do
  action :create
  content <<-EOH
  #!/bin/bash
  sudo dpkg-reconfigure keyboard-configuration
  EOH
  owner username
  group username
  mode  "0755"
end
