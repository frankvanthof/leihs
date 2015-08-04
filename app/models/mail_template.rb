class MailTemplate < ActiveRecord::Base
  audited

  belongs_to :inventory_pool # NOTE when null, then is system-wide
  belongs_to :language

  validates_uniqueness_of :name, scope: [:inventory_pool_id, :language_id, :format]
  validate :syntax_validation

  after_save do
    destroy if body.blank?
  end

  def self.available_liquid_variables_for_order
    [
        'user.name',
        'inventory_pool.name',
        'inventory_pool.description',
        'email_signature',
        {'reservations' => [
            'l.quantity',
            'l.model_name',
            'l.start_date',
            'l.end_date'
        ]},
        'comment',
        'purpose'
    ]
  end

  def self.liquid_variables_for_order(order, comment = nil)
    {user: {name: order.target_user.name},
     inventory_pool: {name: order.inventory_pool.name,
                      description: order.inventory_pool.description},
     email_signature: Setting.email_signature,
     reservations: order.reservations.map do |l|
       {quantity: l.quantity,
        model_name: l.model.name,
        start_date: l.start_date,
        end_date: l.end_date}
     end,
     comment: comment,
     purpose: order.purpose
    }.deep_stringify_keys
  end

  def self.available_liquid_variables_for_user
    [
        'user.name',
        'inventory_pool.name',
        'inventory_pool.description',
        'email_signature',
        {'reservations' => [
            'l.quantity',
            'l.model_name',
            'l.item_inventory_code',
            'l.start_date',
            'l.end_date'
        ]},
        'quantity',
        'due_date'
    ]
  end

  def self.liquid_variables_for_user(user, inventory_pool, reservations)
    {user: {name: user.name},
     inventory_pool: {name: inventory_pool.name,
                      description: inventory_pool.description},
     email_signature: Setting.email_signature,
     reservations: reservations.map do |l|
       {quantity: l.quantity,
        model_name: l.model.name,
        item_inventory_code: l.item.inventory_code,
        start_date: l.start_date,
        end_date: l.end_date}
     end,
     quantity: reservations.to_a.sum(&:quantity),
     due_date: reservations.first.end_date
    }.deep_stringify_keys
  end

  def self.get_template(scope, inventory_pool, name, language)
    mt = MailTemplate.find_by(inventory_pool_id: inventory_pool, name: name, language: language, format: 'text')
    mt ||= MailTemplate.where(inventory_pool_id: inventory_pool, name: name, format: 'text')

    if mt.blank?
      mt = MailTemplate.find_by(inventory_pool_id: nil, name: name, language: language, format: 'text')
      mt ||= MailTemplate.where(inventory_pool_id: nil, name: name, format: 'text')
    end

    if mt.blank?
      File.read(File.join(Rails.root, "app/views/mailer/#{scope}/", "#{name}.text.liquid"))
    else
      Array(mt).map(&:body).join('\n\n- - - - - - - - - -\n\n')
    end
  end

  private

  def syntax_validation
    begin
      Liquid::Template.parse(body, error_mode: :strict)
    rescue => e
      errors.add :base, e.to_s
    end
  end

end
