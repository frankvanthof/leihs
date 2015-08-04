# -*- encoding : utf-8 -*-

#Wenn(/^Julie in einer Delegation ist$/) do
When(/^Julie is in a delegation$/) do
  @user = User.where(login: 'julie').first
  expect(@user.delegations.empty?).to be false
end

#Dann(/^werden mir im alle Suchresultate von Julie oder Delegation mit Namen Julie angezeigt$/) do
Then(/^I see all results for Julie or the delegation named Julie$/) do
  q = '%Julie%'
  delegations = @current_inventory_pool.users.as_delegations.where(User.arel_table[:firstname].matches(q))
  ([@user] + delegations).each do |u|
    find('#users .list-of-lines .line', match: :prefer_exact, text: u.to_s)
  end
  # TODO also check contracts matches, etc...
end

#Dann(/^mir werden alle Delegationen angezeigt, den Julie zugeteilt ist$/) do
Then(/^I see all delegations Julie is a member of$/) do
  (@user.delegations & @current_inventory_pool.users).each do |u|
    find('#users .list-of-lines .line', match: :prefer_exact, text: u.to_s)
  end
  # TODO also check contracts matches, etc...
end

Then(/^I can restrict the user list to show only (users|delegations)$/) do |arg1|
  t, b = case arg1
           when 'users'
             [_('Users'), false]
           when 'delegations'
             [_('Delegations'), true]
         end

  find('#user-index-view form#list-filters select#type').select t
  within '#user-list.list-of-lines' do
    find('.line', match: :first)
    ids = all(".line [data-type='user-cell']").map { |user_data| user_data['data-id'] }
    expect(User.find(ids).any?(&:is_delegation)).to be b
  end
end

#Angenommen(/^ich befinde mich im Reiter '(.*)'$/) do |arg1|
Given(/^I open the tab '(.*)'$/) do |arg1|
  find('nav ul li a.navigation-tab-item', text: arg1).click
  find('nav ul li a.navigation-tab-item.active', text: arg1)
  find('#user-index-view ')
end

#Wenn(/^ich eine neue Delegation erstelle$/) do
When(/^I create a new delegation$/) do
  within('.multibutton', text: _('New User')) do
    find('.dropdown-toggle').click
    find('.dropdown-item', text: _('New Delegation')).click
  end
end

#Wenn(/^ich der Delegation Zugriff für diesen Pool gebe$/) do
When(/^I give the delegation access to the current inventory pool$/) do
  find("select[name='access_right[role]']").select(_('Customer'))
end

#Wenn(/^ich dieser Delegation einen Namen gebe$/) do
When(/^I give the delegation a name$/) do
  @name = Faker::Lorem.sentence
  find("input[name='user[firstname]']").set @name
end

#Wenn(/^ich dieser Delegation keinen, einen oder mehrere Personen zuteile$/) do
When(/^I assign none, one or more people to the delegation$/) do
  @delegated_users = []
  rand(0..2).times do
    find('[data-search-users]').set ' '
    find('ul.ui-autocomplete')
    el = all('ul.ui-autocomplete > li').to_a.sample
    @delegated_users << el.text
    el.click
  end
end

#Wenn(/^ich kann dieser Delegation keine Delegation zuteile$/) do
When(/^I cannot assign a delegation to the delegation$/) do
  find('[data-search-users]').set @current_inventory_pool.users.as_delegations.order('RAND()').first.name
  expect(has_no_selector?('ul.ui-autocomplete > li')).to be true
end

#Wenn(/^ich genau einen Verantwortlichen eintrage$/) do
When(/^I enter exactly one responsible person$/) do
  @responsible ||= @current_inventory_pool.users.not_as_delegations.order('RAND()').first
  find('.row.emboss', text: _('Responsible')).find("input[data-type='autocomplete']").set @responsible.name
  find('ul.ui-autocomplete > li').click
end

#Dann(/^ist die neue Delegation mit den aktuellen Informationen gespeichert$/) do
Then(/^the new delegation is saved with the current information$/) do
  delegation = User.find_by_firstname(@name)
  expect(delegation.delegator_user).to eq @responsible
  delegation.delegated_users.each {|du| @delegated_users.include? du.name}
  delegation.delegated_users.count == (@delegated_users + [@resonsible]).uniq.count
end

#Wenn(/^ich nach einer Delegation suche$/) do
When(/^I search for a delegation$/) do
  @delegation = @current_inventory_pool.users.as_delegations.order('RAND()').first
  #step "ich suche '%s'" % @delegation.firstname
  step "I search for '%s'" % @delegation.firstname
end

#Wenn(/^ich über den Delegationname fahre$/) do
When(/^I hover over the delegation name$/) do
  find('#users .list-of-lines .line', match: :prefer_exact, text: @delegation.to_s).find("[data-type='user-cell']").hover
end

#Dann(/^werden mir im Tooltipp der Name und der Verantwortliche der Delegation angezeigt$/) do
Then(/^the tooltip shows name and responsible person for the delegation$/) do
  find('body > .tooltipster-base', text: @delegation.delegator_user.to_s)
end

#Dann(/^werden mir die Delegationen angezeigt, denen ich zugeteilt bin$/) do
Then(/^I see the delegations I am assigned to$/) do
  @current_user.delegations.customers.each do |delegation|
    find('.line strong', match: :prefer_exact, text: delegation.to_s)
  end
end

#Wenn(/^ich eine Delegation wähle$/) do
When(/^I pick a delegation to represent$/) do
  within(all('.line').to_a.sample) do
    id = find('.line-actions a.button')[:href].gsub(/.*\//, '')
    @delegation = @current_user.delegations.customers.find(id)
    find('strong', match: :prefer_exact, text: @delegation.to_s)
    find('.line-actions a.button').click
  end
end

#Dann(/^wechsle ich die Anmeldung zur Delegation$/) do
Then(/^I am logged in as that delegation$/) do
  find("nav.topbar ul.topbar-navigation a[href='/borrow/user']", text: @delegation.short_name)
  @delegated_user = @current_user
  @current_user = @delegation
end

#Dann(/^die Delegation ist als Besteller gespeichert$/) do
Then(/^the delegation is saved as borrower$/) do
  @contracts.each do |contract|
    expect(contract.user).to eq @delegation
  end
end

#Dann(/^ich werde als Kontaktperson hinterlegt$/) do
Then(/^I am saved as contact person$/) do
  @contracts.each do |contract|
    expect(contract.delegated_user).to eq @delegated_user
  end
end

#Angenommen(/^es wurde für eine Delegation eine Bestellung erstellt$/) do
Given(/^there is an order for a delegation$/) do
  @contract = @current_inventory_pool.reservations_bundles.submitted.find {|c| c.user.is_delegation }
  expect(@contract).not_to be_nil
end

#Angenommen(/^ich befinde mich in dieser Bestellung$/) do
#  step "I edit the order"
#end

#Angenommen(/^ich befinde mich in einer Bestellung von einer Delegation$/) do
Given(/^I am editing a delegation's order$/) do
  @contract = @current_inventory_pool.reservations_bundles.find {|c| [:submitted, :approved].include? c.status and c.delegated_user and c.user.delegated_users.count >= 2}
  @delegation = @contract.user
  step 'I edit the order'
end

#Dann(/^sehe ich den Namen der Delegation$/) do
Then(/^I see the delegation's name$/) do
  expect(has_content?(@contract.user.name)).to be true
end

#Dann(/^ich sehe die Kontaktperson$/) do
Then(/^I see the contact person$/) do
  expect(has_content?(@contract.delegated_user.name)).to be true
end

#Angenommen(/^es existiert eine persönliche Bestellung$/) do
Given(/^there is an order placed by me personally$/) do
  @contract = @current_inventory_pool.reservations_bundles.submitted.find {|c| not c.user.is_delegation }
  expect(@contract).not_to be_nil
end

#Dann(/^ist in der Bestellung der Name des Benutzers aufgeführt$/) do
Then(/^the order shows the name of the user$/) do
  expect(has_content?(@contract.user.name)).to be true
end

#Dann(/^ich sehe keine Kontatkperson$/) do
Then(/^I don't see any contact person$/) do
  find('h2', text: @contract.user.name)
end

#Angenommen(/^es existiert eine Aushändigung( für eine Delegation)?( mit zugewiesenen Gegenständen)?$/) do |arg1, arg2|
Given(/^there is a hand over( for a delegation)?( with assigned items)?$/) do |arg1, arg2|
  @hand_over = if arg1 and arg2
                 @current_inventory_pool.visits.hand_over.find {|v| v.user.is_delegation and v.reservations.all?(&:item) and Date.today >= v.date }
               elsif arg1
                 @current_inventory_pool.visits.hand_over.find {|v| v.user.is_delegation and v.reservations.any? &:item and not v.date > Date.today } # NOTE v.date.future? doesn't work properly because timezone
               else
                 @current_inventory_pool.visits.hand_over.order('RAND()').first
               end
  expect(@hand_over).not_to be_nil
end

#Angenommen(/^ich öffne diese Aushändigung$/) do
Given(/^I open this hand over$/) do
  visit manage_hand_over_path @current_inventory_pool, @hand_over.user
end

When /^I select all reservations selecting all linegroups$/ do
  all('input[data-select-lines]').each {|el| el.click unless el.checked?}
end

#Wenn(/^ich die Delegation wechsle$/) do
When(/^I change the delegation$/) do
  expect(has_selector?('input[data-select-lines]', match: :first)).to be true
  step 'I select all reservations selecting all linegroups'
  multibutton = first('.multibutton', text: _('Hand Over Selection')) || first('.multibutton', text: _('Edit Selection'))
  multibutton.find('.dropdown-toggle').click
  find('#swap-user', match: :first).click
  find('.modal', match: :first)
  @contract ||= @hand_over.reservations.map(&:contract).uniq.first
  @old_delegation = @contract.user
  @new_delegation = @current_inventory_pool.users.find {|u| u.is_delegation and u.firstname != @old_delegation.firstname}
  find('input#user-id', match: :first).set @new_delegation.name
  find('.ui-menu-item a', match: :first).click
  @contract.reservations.reload.all? {|c| c.user == @new_delegation }
end

#Wenn(/^ich versuche die Delegation zu wechseln$/) do
When(/^I try to change the delegation$/) do
  expect(has_selector?('input[data-select-lines]', match: :first)).to be true
  all('input[data-select-lines]').each_with_index do |line, i|
    el = all('input[data-select-lines]')[i]
    el.click unless el.checked?
  end
  multibutton = first('.multibutton', text: _('Hand Over Selection')) || first('.multibutton', text: _('Edit Selection'))
  multibutton.find('.dropdown-toggle').click
  find('#swap-user', match: :first).click
  find('.modal', match: :first)
  find('input#user-id', match: :first)
  @wrong_delegation = User.as_delegations.find {|d| not d.access_right_for @current_inventory_pool}
  @valid_delegation = @current_inventory_pool.users.as_delegations.order('RAND()').first
end

#Dann(/^lautet die Aushändigung auf diese neu gewählte Delegation$/) do
Then(/^the hand over goes to the new delegation$/) do
  expect(has_content?(@new_delegation.name)).to be true
  expect(has_no_content?(@old_delegation.name)).to be true
end

#Wenn(/^ich versuche die Kontaktperson zu wechseln$/) do
When(/^I try to change the contact person$/) do
  expect(has_selector?('input[data-select-lines]', match: :first)).to be true
  step 'I select all reservations selecting all linegroups'
  find('button', text: _('Hand Over Selection')).click
  @delegation = @hand_over.user
  @contact = @delegation.delegated_users.order('RAND()').first
  @not_contact = @current_inventory_pool.users.find {|u| not @delegation.delegated_users.include? u}
end

#Wenn(/^ich versuche bei der Bestellung die Kontaktperson zu wechseln$/) do
When(/^I try to change the order's contact person$/) do
  click_button 'swap-user'
  @contact = @delegation.delegated_users.order('RAND()').first
  @not_contact = @current_inventory_pool.users.find {|u| not @delegation.delegated_users.include? u}
end

#Dann(/^kann ich nur diejenigen Personen wählen, die zur Delegationsgruppe gehören$/) do
Then(/^I can choose only those people that belong to the delegation group$/) do
  find('input#user-id', match: :first).set @not_contact.name
  expect(has_no_selector?('.ui-menu-item a')).to be true
  find('input#user-id', match: :first).set @contact.name
  find('.ui-menu-item a', match: :first, text: @contact.name).click
  find('#selected-user', text: @contact.name)
end

#Dann(/^kann ich bei der Bestellung als Kontaktperson nur diejenigen Personen wählen, die zur Delegationsgruppe gehören$/) do
Then(/^I can choose only those people as contact person for the order that belong to the delegation group$/) do
  within '#contact-person' do
    find('input#user-id', match: :first).set @not_contact.name
    expect(has_no_selector?('.ui-menu-item a')).to be true
    find('input#user-id', match: :first).set @contact.name
    find('.ui-menu-item a', match: :first, text: @contact.name).click
    find('#selected-user', text: @contact.name)
  end
end

#Wenn(/^ich die Kontaktperson wechsle$/) do
When(/^I change the contact person$/) do
  @contact ||= (@delegation or @new_delegation).delegated_users.order('RAND()').first
  within '#contact-person' do
    find('input#user-id', match: :first).set @contact.name
    find('.ui-menu-item a', match: :first, text: @contact.name).click
    find('#selected-user', text: @contact.name)
  end
end

#Dann(/^kann ich nur diejenigen Delegationen wählen, die Zugriff auf meinen Gerätepark haben$/) do
Then(/^I can choose only those delegations that have access to this inventory pool$/) do
  find('input#user-id', match: :first).set @wrong_delegation.name
  expect(has_no_selector?('.ui-menu-item a')).to be true
  find('input#user-id', match: :first).set @valid_delegation.name
  find('.ui-menu-item a', match: :first, text: @valid_delegation.name).click
  find('#selected-user', text: @valid_delegation.name)
end

#Wenn(/^ich statt einer Delegation einen Benutzer wähle$/) do
When(/^I pick a user instead of a delegation$/) do
  @contract ||= @hand_over.reservations.map(&:contract).uniq.first
  @delegation = @contract.user
  @delegated_user = @contract.delegated_user
  @new_user = @current_inventory_pool.users.not_as_delegations.order('RAND()').first
  has_selector?('input[data-select-lines]', match: :first)
  all('input[data-select-lines]').each_with_index do |line, i|
    el = all('input[data-select-lines]')[i]
    el.click unless el.checked?
  end
  multibutton = first('.multibutton', text: _('Hand Over Selection')) || first('.multibutton', text: _('Edit Selection'))
  multibutton.find('.dropdown-toggle').click if multibutton
  find('#swap-user', match: :first).click
  within '.modal' do
    find('#user input#user-id', match: :first).set @new_user.name
    find('.ui-menu-item a', match: :first, text: @new_user.name).click
    find(".button[type='submit']", match: :first).click
  end
  step 'the modal is closed'
end

Then /^the modal is closed$/ do
  expect(has_no_selector?('.modal')).to be true
end

#Dann(/^ist in der Bestellung der Benutzer aufgeführt$/) do
Then(/^the order shows the user$/) do
  find('.content-wrapper', text: @new_user.name, match: :first)
  @contract.reservations.each do |line|
    expect(line.reload.user).to eq @new_user
  end
end

#Dann(/^es ist keine Kontaktperson aufgeführt$/) do
Then(/^no contact person is shown$/) do
  expect(has_no_content?("(#{@delegated_user.name})")).to be true
  @contract.reservations.each do |line|
    expect(line.reload.delegated_user).to eq nil
  end
end

#Wenn(/^keine Bestellung, Aushändigung oder ein Vertrag für eine Delegation besteht$/) do
When(/^there is no order, hand over or contract for a delegation$/) do
  @delegations = User.as_delegations.select {|d| d.reservations_bundles.blank?}
end

#Wenn(/^wenn für diese Delegation keine Zugriffsrechte für irgendwelches Gerätepark bestehen$/) do
When(/^that delegation has no access rights to any inventory pool$/) do
  @delegation = @delegations.find {|d| d.access_rights.empty?}
  expect(@delegation).not_to be_nil
end

#Dann(/^kann ich diese Delegation löschen$/) do
Then(/^I can delete that delegation$/) do
  step %Q(I search for "%s") % @delegation.name
  line = find('.line', text: @delegation.name)
  line.find('.dropdown-toggle').click
  find("[data-method='delete']").click
  expect(has_selector?('.success')).to be true
  expect { @delegation.reload }.to raise_error ActiveRecord::RecordNotFound
end

# Angenommen(/^ich in den Admin\-Bereich wechsle$/) do
#   click_link _("Admin")
# end

#Dann(/^kann ich dieser Delegation ausschliesslich Zugriff als Kunde zuteilen$/) do
Then(/^I can at most give the delegation access on the customer level$/) do
  roles = all("[name='access_right[role]'] option")
  expect(roles.size).to eq 2
  values = roles.map(&:value)
  expect(values.include? 'no_access').to be true
  expect(values.include? 'customer').to be true
end

#Wenn(/^ich keinen Verantwortlichen zuteile$/) do
When(/^I do not enter any responsible person for the delegation$/) do
  expect(find("input[name='user[delegator_user_id]']", visible: false)['value'].empty?).to be true
end

#Dann(/^ich keinen Namen angebe$/) do
When(/^I do not enter any name$/) do
  find("input[name='user[firstname]']").set ''
end

#Wenn(/^ich eine Delegation editiere$/) do
#When(/^I edit a delegation$/) do
#  @delegation = User.find {|u| u.is_delegation and u.delegated_users.exists? }
#  visit manage_edit_inventory_pool_user_path(@current_inventory_pool, @delegation)
#end

#Wenn(/^ich den Verantwortlichen ändere$/) do
When(/^I change the responsible person$/) do
  expect(has_no_selector?('ul.ui-autocomplete')).to be true
  @responsible = @current_inventory_pool.users.not_as_delegations.find {|u| u != @delegation.delegator_user }
  find('.row.emboss', text: _('Responsible')).find("input[data-type='autocomplete']").set @responsible.name
  sleep(0.55) # NOTE this sleep is required waiting the search result
  find('ul.ui-autocomplete > li > a', text: @responsible.name).click
  expect(has_no_selector?('ul.ui-autocomplete')).to be true
end

#Wenn(/^ich einen bestehenden Benutzer lösche$/) do
When(/^I delete an existing user from the delegation$/) do
  @delegated_users = @delegation.delegated_users
  inline_user_entry = find('.row.emboss', text: _('Users')).find('[data-users-list] .row.line', match: :first)
  @removed_delegated_user = User.find {|u| u.name == inline_user_entry.find('[data-user-name]').text}
  inline_user_entry.find('button[data-remove-user]').click
  @delegated_users.delete @removed_delegated_user
end

#Wenn(/^ich der Delegation einen neuen Benutzer hinzufüge$/) do
When(/^I add a user to the delegation$/) do
  expect(has_no_selector?('ul.ui-autocomplete')).to be true
  find('[data-search-users]').set ' '
  find('ul.ui-autocomplete > li > a', match: :first)
  el = all('ul.ui-autocomplete > li > a').to_a.sample
  user = User.find {|u| u.name == el.text}
  @delegated_users << user
  el.click
  expect(has_no_selector?('ul.ui-autocomplete')).to be true
  find('#users .line', text: user.name)
end

#Dann(/^ist die bearbeitete Delegation mit den aktuellen Informationen gespeichert$/) do
Then(/^the edited delegation is saved with its current information$/) do
  expect(@delegation.reload.delegator_user).to eq @responsible
  @delegation.delegated_users.each {|du| @delegated_users.include? du}
  @delegation.delegated_users.count == (@delegated_users + [@responsible]).uniq.count
  expect(@delegation.groups).to eq @current_inventory_pool.groups
end

#Wenn(/^ich eine Delegation mit Zugriff auf das aktuelle Gerätepark editiere$/) do
When(/^I edit a delegation that has access to the current inventory pool$/) do
  @delegation = @current_inventory_pool.users.find {|u| u.is_delegation and not u.visits.take_back.exists? and u.inventory_pools.count >= 2}
  expect(@delegation).not_to be_nil
  visit manage_edit_inventory_pool_user_path(@current_inventory_pool, @delegation)
end

#Wenn(/^ich dieser Delegation den Zugriff für den aktuellen Gerätepark entziehe$/) do
When(/^I remove access to the current inventory pool from this delegation$/) do
  @ip_name = @current_inventory_pool.name
  select _('No access'), from: 'access_right[role]'
end

#Dann(/^können keine Bestellungen für diese Delegation für dieses Gerätepark erstellt werden$/) do
Then(/^no orders can be created for this delegation in the current inventory pool$/) do
  step 'I log out'
  step %Q(I am logged in as '#{@delegation.delegator_user.login}' with password 'password')
  find('.dropdown-holder', text: @current_user.lastname).click
  find(".dropdown-item[href*='delegations']").click
  find('.row.line', text: @delegation.name).click_link _('Switch to')
  FastGettext.set_locale @delegation.language.locale_name # switch the locale in order to translate properly in the next step
  find('.topbar-item', text: _('Inventory Pools')).click
  expect(has_no_content?(@ip_name)).to be true
end

#Wenn(/^ich eine Bestellung für eine Delegationsgruppe erstelle$/) do
When(/^I create an order for a delegation$/) do
  steps %{
    When I hover over my name
    And I click on "Delegations"
    Then I see the delegations I am assigned to
    When I pick a delegation to represent
    Then I am logged in as that delegation
    Given I am listing models
    When I add an existing model to the order
    Then the calendar opens
    When everything I input into the calendar is valid
    Then the model has been added to the order with the respective start and end date, quantity and inventory pool
    When I open my list of orders
    And I enter a purpose
    And I take note of the contract
    And I submit the order
    And I reload the order
    Then the order's status changes to submitted
    And the delegation is saved as borrower
  }
end

# Dann(/^bin ich die Kontaktperson für diesen Auftrag$/) do
#   step "ich werde als Kontaktperson hinterlegt"
# end

#Wenn(/^ich die Gegenstände für die Delegation an "(.*?)" aushändige$/) do |contact_person|
When(/^I hand over the items ordered for this delegation to "(.*?)"$/) do |contact_person|
  @contract = @delegation.reservations_bundles.submitted.first
  @contract.approve Faker::Lorem.sentence
  visit manage_hand_over_path(@current_inventory_pool, @delegation)
  expect(has_selector?('input[data-assign-item]')).to be true
  all('input[data-assign-item]').detect{|el| not el.disabled?}.click
  find('.ui-autocomplete .ui-menu-item', match: :first).click
  expect(has_selector? '[data-remove-assignment]').to be true
  find('.multibutton button[data-hand-over-selection]').click
  @contact = User.find_by_login(contact_person.downcase)
  #step "ich die Kontaktperson wechsle"
  step 'I change the contact person'
  within '.modal' do
    find('.button.green[data-hand-over]', text: _('Hand Over')).click
    expect(has_content?(_('Hand over completed'))).to be true
    expect(has_no_selector?('button[data-hand-over]')).to be true
  end
end

#Dann(/^ist "(.*?)" die neue Kontaktperson dieses Auftrages$/) do |contact_person|
Then(/^"(.*?)" is the new contact person for this contract$/) do |contact_person|
  expect(@delegation.reservations_bundles.signed.first.delegated_user).to eq @contact
end

#Dann(/^ist in der Aushändigung der Benutzer aufgeführt$/) do
Then(/^the hand over shows the user$/) do
  find('.content-wrapper', text: @new_user.name, match: :first)
  expect(current_path).to eq manage_hand_over_path(@current_inventory_pool, @new_user)
  expect(@delegation.visits.hand_over.where(inventory_pool_id: @current_inventory_pool).empty?).to be true
end

#Dann(/^ich öffne eine Aushändigung für eine Delegation$/) do
Then(/^I open a hand over for a delegation$/) do
  @hand_over = @current_inventory_pool.visits.hand_over.find {|v| v.user.is_delegation }
  @delegation = @hand_over.user
  visit manage_hand_over_path @current_inventory_pool, @delegation
end

#Wenn(/^ich statt eines Benutzers eine Delegation wähle$/) do
When(/^I pick a delegation instead of a user$/) do
  @contract ||= @hand_over.reservations.map(&:contract).uniq.first
  @user = @contract.user
  @delegation = @current_inventory_pool.users.as_delegations.order('RAND()').first
  expect(has_selector?('input[data-select-lines]', match: :first)).to be true
  step 'I select all reservations selecting all linegroups'
  multibutton = first('.multibutton', text: _('Hand Over Selection')) || first('.multibutton', text: _('Edit Selection'))
  multibutton.find('.dropdown-toggle').click if multibutton
  find('#swap-user', match: :first).click
  find('.modal', match: :first)
  find('#user input#user-id', match: :first).set @delegation.name
  find('.ui-menu-item a', match: :first, text: @delegation.name).click
end

#Und(/^ich eine Kontaktperson aus der Delegation wähle$/) do
When(/^I pick a contact person from the delegation$/) do
  @contact = @delegation.delegated_users.order('RAND()').first
  find('#contact-person input#user-id', match: :first).click
  find('#contact-person input#user-id', match: :first).set @contact.name
  find('.ui-menu-item a', match: :first, text: @contact.name).click
end

#Dann(/^ist in der Bestellung der Name der Delegation aufgeführt$/) do
Then(/^the order shows the delegation$/) do
  expect(has_content?(@delegation.name)).to be true
end

#Dann(/^ist in der Bestellung der Name der Kontaktperson aufgeführt$/) do
Then(/^the order shows the name of the contact person$/) do
  expect(has_content?(@contact.name)).to be true
end

#Dann(/^ich bestätige den Benutzerwechsel$/) do
When(/^I confirm the user change$/) do
  find(".modal button[type='submit']").click
end

#Wenn(/^ich die Gegenstände aushändige$/) do
When(/^I hand over the items$/) do
  line = find(".line[data-line-type='item_line'] input[id*='assigned-item'][value][disabled]", match: :first).find(:xpath, 'ancestor::div[@data-line-type]')
  line.find('input[data-select-line]').click
  find('.multibutton', text: _('Hand Over Selection')).find('button').click
end

#Dann(/^muss ich eine Kontaktperson hinzufügen$/) do
Then(/^I have to specify a contact person$/) do
  within '.modal' do
    find('.button.green[data-hand-over]', text: _('Hand Over')).click
    expect(has_selector?('#contact-person')).to be true
    expect(find('#error').text.empty?).to be false
  end
end

#Dann(/^die neu gewählte Kontaktperson wird gespeichert$/) do
Then(/^the newly selected contact person is saved$/) do
  @contract.reservations.each do |line|
    expect(line.reload.delegated_user).to eq @contact
  end
end

#Dann(/^sehe ich genau ein Kontaktpersonfeld$/) do
Then(/^I see exactly one contact person field$/) do
  find('#contact-person')
end

#Wenn(/^ich keine Kontaktperson angebe$/) do
When(/^I do not enter any contact person$/) do
  expect(find('#contact-person input#user-id', match: :first).value.empty?).to be true
end

# Wenn(/^ich den Benutzerwechsel bestätige$/) do
#   step "ich bestätige den Benutzerwechsel"
# end

#Dann(/^sehe ich im Dialog die Fehlermeldung "(.*?)"$/) do |text|
Then(/^an error message pops up saying "(.*?)"$/) do |text|
  expect(has_selector?('.modal .red', text: text)).to be true
end

#Wenn(/^ich die Aushändigung abschliesse$/) do
When(/^I finish this hand over$/) do
  find(:xpath, "//*[@data-line-type and descendant::*[contains(@id, 'assigned-item')]]//*[@data-select-line]", match: :first).click
  find('button[data-hand-over-selection]').click
end

#Wenn(/^ich eine gesperrte Kontaktperson wähle$/) do
When(/^I choose a suspended contact person$/) do
  delegated_user = @hand_over.user.delegated_users.order('RAND()').detect {|u| u.suspended? @current_inventory_pool}
  delegated_user ||= begin
    user = @hand_over.user.delegated_users.order('RAND()').first
    ensure_suspended_user(user, @current_inventory_pool)
    user
  end
  find('input#user-id', match: :first).set delegated_user.name
  find('.ui-menu-item a', match: :first, text: delegated_user.name).click
end

# Dann(/^muss ich eine Kontaktperson auswählen$/) do
#   within ".modal" do
#     find("[data-hand-over]").click
#     has_selector? ".red", text: _("Specification of the contact person is required")
#   end
# end

#Angenommen(/^ich befinde mich in der Editieransicht einer Delegation$/) do
Given(/^I am editing a delegation$/) do
  @delegation = @current_inventory_pool.users.as_delegations.order('RAND()').first
  visit manage_edit_inventory_pool_user_path(@current_inventory_pool, @delegation)
end

#Wenn(/^ich einen Verantwortlichen zuteile, der für diesen Gerätepark gesperrt ist$/) do
When(/^I assign a responsible person that is suspended for the current inventory pool$/) do
  @responsible = @current_inventory_pool.users.order('RAND()').detect {|u| u.suspended? @current_inventory_pool}
  #step 'ich genau einen Verantwortlichen eintrage'
  step 'I enter exactly one responsible person'
end

# Wenn(/^ich einen Benutzer hinzufüge, der für diesen Gerätepark gesperrt ist$/) do
#   @delegated_user = @current_inventory_pool.users.order("RAND()").detect{|u| u.suspended? @current_inventory_pool}
#   @delegated_user ||= begin
#       user = @current_inventory_pool.users.not_as_delegations.order("RAND()").first
#       ensure_suspended_user(user, @current_inventory_pool)
#       user
#   end
#   fill_in_autocomplete_field _("Users"), @delegated_user.name
# end

#Angenommen(/^ich wechsle den Benutzer$/) do
Given(/^I swap the user$/) do
  click_button 'swap-user'
  find('.modal', match: :first)
end

#Angenommen(/^ich wähle eine Delegation$/) do
Given(/^I pick a delegation$/) do
  @delegation = @current_inventory_pool.users.as_delegations.order('RAND()').first
  find('#user input#user-id', match: :first).set @delegation.name
  find('.ui-menu-item a', match: :first, text: @delegation.name).click
end

#Wenn(/^ich eine Kontaktperson wähle, der für diesen Gerätepark gesperrt ist$/) do
When(/^I pick a contact person that is suspended for the current inventory pool$/) do
  delegated_user = @delegation.delegated_users.order('RAND()').detect {|u| u.suspended? @current_inventory_pool}
  delegated_user ||= begin
    user = @delegation.delegated_users.order('RAND()').first
    ensure_suspended_user(user, @current_inventory_pool)
    user
  end
  find('input#user-id', match: :first).set delegated_user.name
  find('.ui-menu-item a', match: :first, text: delegated_user.name).click
end

#Und(/^man merkt sich die Bestellung$/) do
And(/^I take note of the contract$/) do
  @contracts = @current_user.reservations_bundles.unsubmitted
end

#Und(/^ich refreshe die Bestellung$/) do
And(/^I reload the order$/) do
  reloaded_contracts = @contracts.map do |contract|
    contract.user.reservations_bundles.find_by(status: :submitted, inventory_pool_id: contract.inventory_pool)
  end
  @contracts = reloaded_contracts
end
