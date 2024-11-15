# frozen_string_literal: true
#
require_relative '../../../controllers/company_controller'
require_relative 'company_search'

require 'gtk3'

class CompanySelector < Gtk::Dialog

  attr_reader :param

  def initialize(parent, type, ides)
    title = case type
            when 'studio'
              I18n.t('company.studio_title')
            when 'publisher'
              I18n.t('company.publisher_title')
            end

    super(title: title, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 500)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @parent = parent
    @type = type
    @ides = ides
    @title = title
    @param = []
    @controller = CompanyController.new
    @keyword = nil

    set_ui
    load_company_data
    load_selected_company
    set_signal_connect

    show_all
  end

  def set_ui
    v_box = Gtk::Box.new(:vertical)
    child.pack_start(v_box, padding: 10)

    label = Gtk::Label.new
    label.set_markup("<span font='25'>#{@title}</span>")
    v_box.pack_start(label, expand: true)

    list_h_box = Gtk::Box.new(:horizontal)
    v_box.pack_start(list_h_box, padding: 20)

    selected_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(selected_list_v_box, expand: true)

    selected_label = Gtk::Label.new
    selected_label.text = I18n.t('company.selected')
    selected_list_v_box.pack_start(selected_label)

    @selected_list_scroll = Gtk::ScrolledWindow.new
    @selected_list_scroll.set_size_request(400, 300)
    selected_list_v_box.pack_start(@selected_list_scroll, expand: true)

    @selected_list = Gtk::ListBox.new
    @selected_list_scroll.add(@selected_list)

    company_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(company_list_v_box, expand: true)

    company_label = Gtk::Label.new
    company_label.text = I18n.t('company.not_selected')
    company_list_v_box.pack_start(company_label)

    @company_list_scroll = Gtk::ScrolledWindow.new
    @company_list_scroll.set_size_request(400, 300)
    company_list_v_box.pack_start(@company_list_scroll, expand: true)

    @company_list = Gtk::ListBox.new
    @company_list_scroll.add(@company_list)

    btn_h_box = Gtk::Box.new(:horizontal)
    v_box.pack_start(btn_h_box, padding: 20)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(220, 50)
    btn_h_box.pack_start(@search_btn, expand: true)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(220, 50)
    btn_h_box.pack_start(@close_btn, expand: true)

  end

  def set_signal_connect
    @selected_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          company_id = selected_row.name.to_i
          @ides.delete(company_id)

          load_selected_company
          load_company_data
        end
      end
    end

    @company_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          company_id = selected_row.name.to_i
          @ides << company_id

          load_selected_company
          load_company_data
        end
      end
    end

    @search_btn.signal_connect('clicked') do
      company_search = CompanySearch.new(self, I18n.t('menu.search'))

      company_search.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          @keyword = company_search.keyword
          load_company_data
        end
      end
    end

    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def load_company_data
    clear_list_box(@company_list)

    company = begin
      @controller.get_all_company_list(@type, @ides, @keyword)
    rescue StandardError => e
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    company.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @company_list.add(row)
    end

    @company_list_scroll.vadjustment.value = 0.0
    @company_list.show_all
  end

  def load_selected_company
    clear_list_box(@selected_list)
    @param = []

    return if @ides.empty?

    selected_company = []

    begin
      @ides.each do |company_id|
        selected_company << @controller.get_one_company(company_id)
      end
    rescue StandardError => e
      dialog_message(self, :error, :db_error, e.message)
      return
    end

    selected_company.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s

      @selected_list.add(row)

      @param << { 'name' => item.name, 'id' => item.id }
    end

    @selected_list_scroll.vadjustment.value = 0.0
    @selected_list.show_all
  end

end
