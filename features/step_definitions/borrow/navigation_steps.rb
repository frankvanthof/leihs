# -*- encoding : utf-8 -*-

Dann(/^seh ich die Navigation$/) do
  find("nav")
end

Dann(/^die Navigation beinhaltet "(.*?)"$/) do |section|
  case section
    when "Abzuholen"
      find("nav a[href='#{borrow_to_pick_up_path}']") if @current_user.contract_lines.to_hand_over.sum(&:quantity) > 0
    when "Rückgaben"
      find("nav a[href='#{borrow_returns_path}']") if @current_user.contract_lines.to_take_back.sum(&:quantity) > 0
    when "Bestellungen"
      find("nav a[href='#{borrow_orders_path}']") if @current_user.orders.submitted.count > 0
    when "Geräteparks"
      find("nav a[href='#{borrow_inventory_pools_path}']", :text => _("Inventory Pools"))
    when "Benutzer"
      find("nav a[href='#{borrow_current_user_path}']", :text => @current_user.name)
    when "Logout"
      find("nav a[href='#{logout_path}']")
    when "Verwalten"
      find("nav a[href='#{backend_path}']", :text => _("Manage"))
    else
      pending
  end
end

Dann(/^seh ich in der Navigation den Home\-Button$/) do
  find("nav a[href='#{borrow_root_path}']")
end

Wenn(/^ich den Home\-Button bediene$/) do
  find("nav a[href='#{borrow_root_path}']").click
end

Dann(/^lande ich auf der Seite der Hauptkategorien$/) do
  current_path.should == borrow_root_path
end