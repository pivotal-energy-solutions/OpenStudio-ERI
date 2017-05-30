class XMLHelper

  # Adds the child element with 'element_name' and sets its value. Returns the
  # child element.
  def self.add_element(parent, element_name, value=nil)
    added = nil
    element_name.split("/").each do |name|
      added = REXML::Element.new(name)
      parent << added
      parent = added
    end
    if not value.nil?
      added.text = value
    end
    return added
  end
  
  # Deletes the child element with element_name. Returns the deleted element.
  def self.delete_element(parent, element_name)
    element = parent.elements.delete(element_name)
    return element
  end
  
  # Returns the value of 'element_name' in the parent element or nil.
  def self.get_value(parent, element_name)
    val = parent.elements[element_name]
    if val.nil?
      return val
    end
    return val.text
  end  
  
  # Returns true if the element exists.
  def self.has_element(parent, element_name)
    element_name.split("/").each do |name|
      element = parent.elements[name]
      return false if element.nil?
      parent = element
    end
    return true
  end
  
  # Returns the attribute added
  def self.add_attribute(element, attr_name, attr_val)
    attr_val = self.valid_attr(attr_val).to_s
    added = element.add_attribute(attr_name, attr_val)
    return added
  end
  
  def self.valid_attr(attr)
    attr = attr.to_s
    attr = attr.gsub(" ", "_")
    attr = attr.gsub("|", "_")
    return attr
  end
  
  # Copies the element if it exists
  def self.copy_element(dest, src, element_name)
    if not src.elements[element_name].nil?
      dest << src.elements[element_name].dup
    end
  end  
  
  def self.validate(doc, xsd_path)
    require 'nokogiri'
    xsd = Nokogiri::XML::Schema(File.open(xsd_path))
    doc = Nokogiri::XML(doc)
    xsd.validate(doc)
  end
  
  def self.write_file(hpxml_doc, hpxml_out_path)
    # Write HPXML file
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    formatter.width = 1000
    File.open(hpxml_out_path, 'w') do |f|
      formatter.write(hpxml_doc, f)
    end
  end  
  
end