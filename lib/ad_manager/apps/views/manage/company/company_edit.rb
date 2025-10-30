# frozen_string_literal: true
require_relative '../../../controllers/company_controller'

require 'gtk3'

class CompanyEdit < Gtk::Dialog

  attr_reader :keyword

  # 初期化
  def initialize(parent, menu, type, id)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 200)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @menu = menu
    @type = type
    @id = id
    @controller = CompanyController.new

    set_ui
    close_btn_ui
    set_signal_connect

    show_all
  end

  private

  # UIの設定
  def set_ui

    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(600, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    @btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(@btn_box, padding: 30)

    @type = radio_to_type(@type)

    # 機能によって分岐する
    case @menu
    when I18n.t('menu.add')
      add_ui
      set_add_widgets_connect
    when I18n.t('menu.search')
      search_ui
      set_search_widgets_connect
    when I18n.t('menu.modify')
      modify_ui
      load_data
      set_modify_widgets_connect
    else
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

  # 追加のUIの設定
  def add_ui
    @add_button = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_button.set_size_request(270, 50)
    @btn_box.pack_start(@add_button, expand: true)
  end

  # 検索のUIの設定
  def search_ui
    @search_button = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_button.set_size_request(270, 50)
    @btn_box.pack_start(@search_button, expand: true)
  end

  # 更新のUIの設定
  def modify_ui
    @modify_button = Gtk::Button.new(label: I18n.t('menu.modify'))
    @modify_button.set_size_request(150, 50)
    @btn_box.pack_start(@modify_button, expand: true)

    @change_button = Gtk::Button.new(label: I18n.t('menu.change_use'))
    @change_button.set_size_request(150, 50)
    @btn_box.pack_start(@change_button, expand: true)

    @remove_button = Gtk::Button.new(label: I18n.t('menu.remove'))
    @remove_button.set_size_request(150, 50)
    @btn_box.pack_start(@remove_button, expand: true)
  end

  # 閉じるボタンのUIの設定
  def close_btn_ui
    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(270, 50)
    @btn_box.pack_start(@close_button, expand: true)
  end

  # 各種ウィゼットの設定
  # 閉じるボタンのイベントの設定
  def set_signal_connect
    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  # 追加UIのウィゼットのイベント設定
  def set_add_widgets_connect
    # 追加ボタンのイクリックイベント
    @add_button.signal_connect('clicked') do
      next if @type.nil?

      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      # 引数を一つの束ねる
      company = { 'type' => @type, 'name' => @entry.text.to_s.strip, 'parent_id' => @id }

      success = @controller.add_child_company(Company.new(company))

      if success.is_a?(String)
        dialog_message(self, :error, :write_error, success)
        next
      end

      if success
        dialog_message(self, :info, :write_success)

        response(Gtk::ResponseType::OK)
        destroy
      else
        dialog_message(self, :warning, :duplicate_data)
        @entry.grab_focus
      end
    end
  end

  # 検索UIのウィゼットのイベント設定
  def set_search_widgets_connect
    # 検索ボタンのイクリックイベント
    @search_button.signal_connect('clicked') do
      next if @type.nil?

      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      @keyword = @entry.text.to_s.strip

      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  # 更新UIのウィゼットのイベント設定
  def set_modify_widgets_connect
    # 更新ボタンのイクリックイベント
    @modify_button.signal_connect('clicked') do
      next if @type.nil?

      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      # 引数を一つの束ねる
      company = { 'id' => @id, 'type' => @type, 'name' => @entry.text.to_s.strip }

      result = @controller.modify_one_company(Company.new(company))

      if result.is_a?(String)
        dialog_message(self, :error, :modify_error, result)
        next
      end

      if result
        dialog_message(self, :info, :modify_success)
      else
        dialog_message(self, :warning, :duplicate_data)
        @entry.grab_focus
      end
    end

    # メインの会社に変更するボタンのイクリックイベント
    @change_button.signal_connect('clicked') do
      result = @controller.change_current_yn(@id)

      if result.is_a?(String)
        dialog_message(self, :error, :modify_error, result)
        next
      end

      @change_button.sensitive = false
      @remove_button.sensitive = false

      dialog_message(self, :info, :modify_success)
    end

    # 削除ボタンのイクリックイベント
    @remove_button.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, self)
      res = con.run

      if res == Gtk::ResponseType::YES
        result = @controller.remove_one_company(@id)

        if result.is_a?(String)
          dialog_message(self, :error, :remove_error, result)
          next
        end

        dialog_message(self, :info, :remove_success)

        response(Gtk::ResponseType::OK)
        destroy
      end
      con.destroy
    end

  end

  # 制作会社、出版社の情報の読み込み
  def load_data
    return if @id.nil?

    result = @controller.get_company_info(@id)

    if result.is_a?(String)
      dialog_message(self, :error, :db_error, result)
      return
    end

    company = result['company']
    count = result['count']

    @entry.text = company.name
    @change_button.sensitive = false if company.current_yn == 'Y'
    @remove_button.sensitive = false if count <= 1 || company.current_yn == 'Y'

  end
end
