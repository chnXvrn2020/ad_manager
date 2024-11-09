# frozen_string_literal: true

require_relative '../../controllers/common_controller'
require_relative '../../controllers/company_controller'
require_relative '../../controllers/content_controller'

require 'gtk3'

class CommonEdit < Gtk::Dialog

  attr_reader :keyword, :last_id

  def initialize(parent, menu, type, data = nil)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 200)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @parent = parent
    @menu = menu
    @type = type
    @data = data
    @common_controller = CommonController.new
    @content_controller = ContentController.new
    @company_controller = CompanyController.new

    set_ui
    close_btn_ui
    set_signal_connect

    show_all
  end

  def set_ui

    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(600, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    @btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(@btn_box, padding: 30)

    @type = radio_to_type(@type.label)

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
    signal_connect('key_press_event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Return ||
        event.keyval == Gdk::Keyval::KEY_KP_Enter

        case @menu
        when I18n.t('menu.add')
          @add_button.clicked
        when I18n.t('menu.search')
          @search_button.clicked
        when I18n.t('menu.modify')
          @modify_button.clicked
        else
          response(Gtk::ResponseType::CANCEL)
          destroy
        end

      end
      false
    end

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

      success = begin
        case @type
        when 'content'
          @last_id = @content_controller.add_content(@entry.text.to_s.strip)

          if @last_id.nil?
            false
          else
            true
          end
        when 'studio', 'publisher'
          company = { 'type' => @type, 'name' => @entry.text.to_s.strip }

          @company_controller.add_one_company(Company.new(company))
        else
          common = { 'type' => @type, 'name' => @entry.text.to_s.strip }

          @common_controller.add_one_common(Common.new(common))
        end
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

      common = { 'id' => @data, 'type' => @type, 'name' => @entry.text.to_s.strip }

      success = begin
        @common_controller.modify_one_common(Common.new(common))
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

    @remove_button.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, self)
      res = con.run

      if res == Gtk::ResponseType::YES
        begin
          @common_controller.remove_one_common(@data)

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
    return if @data.nil?

    common = begin
     @common_controller.get_one_common(@data)
   rescue StandardError => e
     dialog_message(self, :error, :db_error, e.message)
   end

    @entry.text = common.name
  end
end
