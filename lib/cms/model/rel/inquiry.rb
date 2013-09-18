# encoding: utf-8
module Cms::Model::Rel::Inquiry
  attr_accessor :in_inquiry
  
  @@inquiry_presence_of = [:group_id, :tel, :email]
  
  def self.included(mod)
    mod.belongs_to :inquiry, :foreign_key => 'unid', :primary_key => 'parent_unid', :class_name => 'Cms::Inquiry',
      :dependent => :destroy

    mod.after_save :save_inquiry
  end

  def in_inquiry
    unless val = read_attribute(:in_inquiry)
      val = {}
      val = inquiry.attributes if inquiry
      write_attribute(:in_inquiry, val)
    end
    read_attribute(:in_inquiry)
  end

  def in_inquiry=(values)
    @inquiry = {}
    values.each {|k,v| @inquiry[k.to_s] = v if !v.blank? }
    write_attribute(:in_inquiry, @inquiry)
  end

  def inquiry_states
   {'visible' => '表示', 'hidden' => '非表示'}
  end
  
  def default_inquiry(params = {})
    unless g = Core.user.group
      return params
    end
    {:state => 'hidden', :group_id => g.id, :tel => g.tel, :email => g.email}.merge(params)
  end
  
  def inquiry_presence?(name)
    @@inquiry_presence_of.index(name) != nil
  end
  
  def validate_inquiry
    if @inquiry && @inquiry['state'] == 'visible'
      if inquiry_presence?(:group) && @inquiry['group_id'].blank?
        errors["連絡先（課）"] = "を入力してください。"
      end
      if inquiry_presence?(:tel) && @inquiry['tel'].blank?
        errors["連絡先（電話番号）"] = "を入力してください。"
      end
      errors["連絡先（電話番号）"] = :onebyte_characters if @inquiry['tel'].to_s !~/^[ -~｡-ﾟ]*$/
      errors["連絡先（ファクシミリ）"] = :onebyte_characters if @inquiry['fax'].to_s !~/^[ -~｡-ﾟ]*$/
      
      if inquiry_email_setting != "hidden"
        if inquiry_presence?(:email) && @inquiry['email'].blank?
          errors["連絡先（メールアドレス）"] = "を入力してください。"
        end
        errors["連絡先（メールアドレス）"] = "を正しく入力してください。" if @inquiry['email'].to_s !~/^[ -~｡-ﾟ]*$/
      end
    end
  end

  def save_inquiry
    return false unless unid
    return true unless @inquiry
    return true unless @inquiry.is_a?(Hash)
    
    values = @inquiry
    @inquiry = nil
    
    _inq = inquiry  || Cms::Inquiry.new
    _inq.created_at ||= Core.now
    _inq.updated_at   = Core.now
    _inq.state        = values['state']
    _inq.group_id     = values['group_id']
    _inq.charge       = values['charge']
    _inq.tel          = values['tel']
    _inq.fax          = values['fax']
    if inquiry_email_setting != "hidden"
      _inq.email      = values['email']
    end

    if _inq.new_record?
      _inq.parent_unid = unid
      return false unless _inq.save_with_direct_sql
    else
      return false unless _inq.save
    end
    inquiry(true)
    return true
  end
  
  def inquiry_email_setting
    "visible"
  end
end
