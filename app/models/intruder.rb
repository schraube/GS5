class Intruder < ActiveRecord::Base
  attr_accessible :list_type, :key, :points, :bans, :ban_last, :ban_end, :contact_ip, :contact_port, :contact_count, :contact_last, :contacts_per_second, :contacts_per_second_max, :user_agent, :to_user, :comment

  LIST_TYPES = ['blacklist', 'whitelist']

  validates :list_type,
            :presence => true,
            :inclusion => { :in => LIST_TYPES }

  validates :key,
            :presence => true,
            :uniqueness => true

  validates :contact_ip,
            :presence => true,
            :uniqueness => true

  before_validation :set_key_if_empty

  def to_s
    key
  end

  def whois(ip_address = self.contact_ip)
    if ! ip_address.blank?
      begin
        return Whois.whois(ip_address).to_s.gsub(/[^\u{0000}-\u{007F}]/, '')
      rescue
        return nil
      end
    end
  end

  private
  def set_key_if_empty
    if self.key.blank?
      self.key = self.contact_ip
    end
  end
end
