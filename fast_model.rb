require 'active_support/all'

class FastModel
  class << self
    @@fields = {}
    @@models = {}
    @@hm = {}
    @@bt = {}

    def has_many(other_model)
      @@hm[model_name] ||= []
      @@hm[model_name] << other_model
    end

    def belongs_to(other_model)
      @@bt[model_name] ||= []
      @@bt[model_name] << other_model
    end
    
    def fields(*field_names)
      @@fields[model_name] = field_names
    end

    def all
      @@models[model_name] ||= []
      @@models[model_name]
    end

    def first(count=nil)
      @@models[model_name] ||= []
      @@models[model_name].first(count)
    end

    def where(cond={})
      return_models = []
      @@models[model_name].each do |model|
        found = true
        cond.each do |field, value|
          break if ! found
          found = model.send(field) == value
        end
        return_models << model if found
      end
      return_models
    end


    def to_h 
      {
        :hm => @@hm,
        :bt => @@bt,
        :models => @@models
      }
    end


    def build(attribs)
      new_model = model_name.constantize.new(attribs)
    end

    def create(attribs)
      new_model = build(attribs)
      new_model.save
      new_model
    end

    def model_name
      self.to_s
    end
    alias_method :inspect, :model_name

    def all_for_model(search_model, target_model)
      search_model = search_model.to_s.classify
      models = []
      if @@models[search_model]
        @@models[search_model].each do |m|
          models << m if m.has_bt_association?(target_model)
        end
      end

      models
    end

  end

  attr_accessor :id

  def initialize(attribs={})
    @bt_models = {}
    @hm_models = {}
    @field_values = {}
    @id = "UNSAVED-#{Random.rand(999999)}"
    setup_hm_assoc
    setup_bt_assoc
    setup_fields

    attribs.each do |k, v|
      send("#{k}=", v)
    end
  end

  def to_h
    h = {:id => @id}
    keys = field_attribs + bt_attribs + hm_attribs
    keys.each do |v|
      h[v] = send(v)
    end
    h
  end

  def to_sym
    self.class.to_s.underscore.to_sym
  end

  def to_s
    "#{self.class}-#{@id}"
  end
  alias_method :inspect, :to_s

  def ==(other_model)
    to_s == other_model.to_s
  end

  def has_bt_association?(other_model)
    @bt_models[other_model.to_sym] == other_model
  end

  def save
    model_name = self.class.to_s

    last_model = @@models[model_name].to_a.last
    @id = last_model.nil? ? 1 : last_model.id + 1
    @@models[model_name] ||= []
    @@models[model_name].push self

  end
  alias_method :save!, :save

  #def assign_bt_assoc(field, other_model)
    #@bt_models[field.to_sym] = other_model
  #end

  #def assign_hm_assoc(field, other_model)
    #@hm_models[field.to_sym].push other_model
  #end


  private

  def set_association(field, value)
    @bt_models[field] = value
  end


  def setup_hm_assoc
    hm_attribs.each do |hm_assoc|
      @hm_models[hm_assoc] = []
      define_singleton_method(hm_assoc) { self.class.all_for_model(hm_assoc, self) }
      #define_singleton_method("#{hm_assoc}=") { |val| set_association(:hm, hm_assoc, val) }
    end
    
  end

  def setup_bt_assoc
    bt_attribs.each do |bt_assoc|
      define_singleton_method(bt_assoc) { @bt_models[bt_assoc] }
      define_singleton_method("#{bt_assoc}=") { |val| set_association(bt_assoc, val) }
    end
  end
  
  def setup_fields
    field_attribs.each do |field|
      define_singleton_method(field) { @field_values[field]  }
      define_singleton_method("#{field}=") { |val| @field_values[field] = val }
    end
  end

  def field_attribs
    @@fields[self.class.to_s] || []
  end

  def hm_attribs
    @@hm[self.class.to_s] || []
  end

  def bt_attribs
    @@bt[self.class.to_s] || []
  end
end
