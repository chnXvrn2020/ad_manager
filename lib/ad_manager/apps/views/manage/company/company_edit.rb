# frozen_string_literal: true
require_relative '../../../controllers/company_controller'

require 'gtk3'

class CompanyEdit < Gtk::Dialog

  attr_reader :keyword

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

  def add_ui
    @add_button = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_button.set_size_request(270, 50)
    @btn_box.pack_start(@add_button, expand: true)
  end

  def search_ui
    @search_button = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_button.set_size_request(270, 50)
    @btn_box.pack_start(@search_button, expand: true)
  end

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

  def close_btn_ui
    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(270, 50)
    @btn_box.pack_start(@close_button, expand: true)
  end

  def set_signal_connect
    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def set_add_widgets_connect
    @add_button.signal_connect('clicked') do
      next if @type.nil?

      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      company = { 'type' => @type, 'name' => @entry.text.to_s.strip, 'parent_id' => @id }

      begin
        success = @controller.add_child_company(Company.new(company))
      rescue StandardError => e
        dialog_message(self, :error, :write_error, e.message)
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

  def set_search_widgets_connect
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

  def set_modify_widgets_connect

    ##
    # ボタンのコネクト
    @modify_button.signal_connect('clicked') do
      next if @type.nil?

      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        next
      end

      company = { 'id' => @id, 'type' => @type, 'name' => @entry.text.to_s.strip }

      begin
        success = @controller.modify_one_company(Company.new(company))
      rescue StandardError => e
        dialog_message(self, :error, :modify_error, e.message)
        next
      end

      if success
        dialog_message(self, :info, :modify_success)
      else
        dialog_message(self, :warning, :duplicate_data)
        @entry.grab_focus
      end
    end

    @change_button.signal_connect('clicked') do
      begin
        @controller.change_current_yn(@id)
      rescue StandardError => e
        dialog_message(self, :error, :modify_error, e.message)
        next
      end

      @change_button.sensitive = false
      @remove_button.sensitive = false

      dialog_message(self, :info, :modify_success)
    end

    @remove_button.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, self)
      res = con.run

      if res == Gtk::ResponseType::YES
        begin
          @controller.remove_one_company(@id)

          dialog_message(self, :info, :remove_success)

          response(Gtk::ResponseType::OK)
          destroy
        rescue StandardError => e
          dialog_message(self, :error, :remove_error, e.message)
          next
        end
      end

      con.destroy
    end

  end

  def load_data
    return if @id.nil?

    begin
      company = @controller.get_one_company(@id)
      count = @controller.get_company_group_count(@id)
    rescue StandardError => e
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    @entry.text = company.name
    @change_button.sensitive = false if company.current_yn == 'Y'
    @remove_button.sensitive = false if count <= 1 || company.current_yn == 'Y'

  end
end
