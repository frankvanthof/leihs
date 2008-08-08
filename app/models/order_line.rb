class OrderLine < DocumentLine

  belongs_to :order
  belongs_to :inventory_pool
  belongs_to :model # common for sibling classes
  belongs_to :line_group # common for sibling classes
  
  
  has_many :options


  before_save :assign_inventory_pool

  
###############################################  
# TODO named_scope with lambda
  
  def self.current_reservations(model_id, date = Date.today)
    find(:all, :conditions => ['model_id = ? and start_date < ? and end_date > ?', model_id, date, date])
  end
  
  def self.future_reservations(model_id, date = Date.today)
    find(:all, :conditions => ['model_id = ? and start_date > ?', model_id, date])
  end
  
  def self.current_and_future_reservations(model_id, order_line_id = 0, date = Date.today)
    find(:all, :conditions => ['model_id = ? and ((start_date < ? and end_date > ?) or start_date > ?) and id <> ?', model_id, date, date, date, order_line_id])
  end

###############################################

  def order_to_exclude
    id
  end
  
  def contract_to_exclude
    0
  end
  

  # TODO temp check, remove it 
  def correct_inventory_pool?
    model.inventory_pools.any?{|ip| ip == order.inventory_pool }
  end

  private
  
  # OPTIMIZE suggest best possible inventory pool according to the other order_lines
  def assign_inventory_pool
    if self.inventory_pool.nil?
      if line_group and line_group.model_group.is_a?(Package)
        self.inventory_pool = line_group.model_group.inventory_pool
      else
        inventory_pool = nil
        model.inventory_pools.each do |ip|
           if ip.items.count(:conditions => {:model_id => model.id}) >= quantity
             inventory_pool = ip
             break
           end
        end
        self.inventory_pool = inventory_pool
      end
    end
  end
  
end
