class Softkey < ActiveRecord::Base
  attr_accessible :softkey_function_id, :number, :label, :uuid, :softkeyable_type, :softkeyable_id

  belongs_to :sip_account
  belongs_to :softkey_function
  belongs_to :softkeyable, :polymorphic => true

  validates_presence_of :softkeyable_id, :if => Proc.new{ |softkey| self.softkey_function_id != nil && 
                                                                     self.softkey_function_id == SoftkeyFunction.find_by_name('call_forwarding').try(:id) }

  # These functions need a number to act.
  #
  validates_presence_of :number, :if => Proc.new{ |softkey| self.softkey_function_id != nil &&  
                                                            ['blf','speed_dial','dtmf','conference'].include?(softkey.softkey_function.name) }

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  acts_as_list :scope => :sip_account

  before_validation :clean_up_and_leave_only_values_which_make_sense_for_the_current_softkey_function_id
  after_save :resync_phone
  after_destroy :resync_phone

  def possible_blf_call_forwards
    if self.sip_account.phone_numbers.count == 0
      nil
    else
      if self.sip_account.callforward_rules_act_per_sip_account == true
        # We pick one phone_number and display the rules of it.
        #
        phone_number = self.sip_account.phone_numbers.order(:number).first
        call_forwards = self.sip_account.call_forwards.where(:phone_number_id => phone_number.id)
      else
        call_forwards = self.sip_account.call_forwards
      end
      
      phone_numbers_ids = self.sip_account.phone_number_ids
      phone_numbers = PhoneNumber.where(:id => phone_numbers_ids).pluck(:number)

      hunt_group_ids = PhoneNumber.where(:phone_numberable_type => 'HuntGroupMember', :number => phone_numbers).
                                   map{ |phone_number| phone_number.phone_numberable.hunt_group.id }.
                                   uniq

      call_forwards + CallForward.where(:call_forwardable_type => 'HuntGroup', :call_forwardable_id => hunt_group_ids).
                                  where('phone_number_id NOT IN (?)', phone_numbers_ids)
    end
  end

  def to_s
    if self.softkeyable.blank?
      if ['log_out', 'log_in'].include?(self.softkey_function.name)
        I18n.t("softkeys.functions.#{self.softkey_function.name}")        
      else
        "#{self.softkey_function.name} : #{self.number.to_s}"
      end
    else
      "#{self.softkeyable}"
    end
  end

  def resync_phone
    phone_sip_account = PhoneSipAccount.find_by_sip_account_id(self.sip_account_id)
    if phone_sip_account && phone_sip_account.phone
      phone_sip_account.phone.resync()
    end
  end

  def move_up?
    return self.position.to_i > Softkey.where(:sip_account_id => self.sip_account_id ).order(:position).first.position.to_i
  end

  def move_down?
    return self.position.to_i < Softkey.where(:sip_account_id => self.sip_account_id ).order(:position).last.position.to_i
  end

  private
  # Make sure that no number is set when there is no need for one.
  # And make sure that there is no CallForward connected when not needed.
  #
  def clean_up_and_leave_only_values_which_make_sense_for_the_current_softkey_function_id
    if self.softkey_function_id != nil
      case self.softkey_function.name
      when 'blf'
        self.softkeyable = PhoneNumber.where(:number => self.number, :phone_numberable_type => 'SipAccount').first.try(:phone_numberable)
      when 'conference'
        self.softkeyable = PhoneNumber.where(:number => self.number, :phone_numberable_type => 'Conference').first.try(:phone_numberable)
      when 'call_forwarding'
        self.softkeyable = CallForward.where(:id => self.softkeyable_id).first
        self.number = nil
      else
        self.softkeyable_id = nil
        self.softkeyable_type = nil  
      end
    end
  end

end
