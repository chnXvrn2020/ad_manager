# frozen_string_literal: true

require 'gtk3'

require_relative '../../../controllers/company_controller'
require_relative 'company_edit'

class CompanyIndex < Gtk::Dialog

  def initialize(parent, type, company_id)
    super(title: type.label.to_s + I18n.t('menu.config'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 500)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @type = type
    @company_id = company_id
    @controller = CompanyController.new
    @keyword = nil

    set_ui
    load_company_data
    set_signal_connect

    show_all
  end

  private
  def set_ui

    label_box = Gtk::Box.new(:horizontal)
    child.pack_start(label_box, padding: 10)

    @label = Gtk::Label.new
    label_box.pack_start(@label, expand: true)

    list_box = Gtk::Box.new(:horizontal)
    child.pack_start(list_box, padding: 5)

    @list_scroll = Gtk::ScrolledWindow.new
    @list_scroll.set_size_request(600, 300)
    list_box.pack_start(@list_scroll, expand: true)

    @list_widget = Gtk::ListBox.new
    @list_scroll.add(@list_widget)

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 10)

    @add_btn = Gtk::Button.new(label: I18n.t('menu.add'))
    @add_btn.set_size_request(100, 50)
    btn_box.pack_start(@add_btn, expand: true)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(100, 50)
    btn_box.pack_start(@search_btn, expand: true)

    @delete_btn = Gtk::Button.new(label: I18n.t('menu.remove_away'))
    @delete_btn.set_size_request(100, 50)
    btn_box.pack_start(@delete_btn, expand: true)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(100, 50)
    btn_box.pack_start(@close_btn, expand: true)

  end

  def set_signal_connect

    ##
    # ボタンのコネクト
    @add_btn.signal_connect('clicked') do
      company_edit = CompanyEdit.new(self, @add_btn.label, @type.label, @company_id)

      company_edit.signal_connect('response') do |widget, response|
        load_company_data if response == Gtk::ResponseType::OK
      end
    end

    @search_btn.signal_connect('clicked') do
      company_edit = CompanyEdit.new(self, @search_btn.label, @type.label, @company_id)

      company_edit.signal_connect('response') do |widget, response|
        @keyword = company_edit.keyword
        load_company_data if response == Gtk::ResponseType::OK
      end
    end

    @delete_btn.signal_connect('clicked') do
      con = confirm_dialog(:remove_confirm, self)
      res = con.run

      if res == Gtk::ResponseType::YES
        begin
          @controller.remove_company_group(@company_id)

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

    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end

    ##
    # リストのコネクト
    @list_widget.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i

          company_edit = CompanyEdit.new(self, I18n.t('menu.modify'), @type.label, item)

          company_edit.signal_connect('response') do |widget, response|
            load_company_data if response == Gtk::ResponseType::OK
          end

        end
      end
    end

  end

  def load_company_data
    clear_list_box(@list_widget)

    company = begin
      @controller.get_company_group(@company_id, @keyword)
    rescue StandardError => e
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    company.each do |item|
      @label.set_markup("<span font='25'>#{item.name}</span>") if item.id == @company_id
      row = Gtk::ListBoxRow.new
      postfix = ''

      postfix = I18n.t('company.current_use') if item.current_yn == 'Y'

      row.add(Gtk::Label.new(item.name + postfix))
      row.name = item.id.to_s

      @list_widget.add(row)
    end

    # リストのリフレッシュ
    @list_widget.show_all
  end

end
