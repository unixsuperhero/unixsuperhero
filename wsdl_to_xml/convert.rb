require 'multi_xml'

## TODO
# CODE GENERATOR CLASSES:
#   Have methods for generating the code to actually send the packets.  Example
# mediums would be: curl, HTTParty.  Eg. Generate the curl commands with -H for
# the headers, or a whole ruby class with the proper includes and standard
# methods for settings tags and firing off the request.  This should be a
# wrapper class that extends from BaseGenerator.  BaseGenerator should have a
# public API that all these classes use, and their private methods handle the
# nuances between mediums such as rendering a view if that's how the ruby class
# is templated out.
# Example:
#
# class CurlGenerator < WsdlConvert::Generator
#   def generate
#   end
#   private
#   def compile_shell_command
#   end
# end

## OTHER NOTES:
# Class Hierarchy:
#   At this point, I'm not sure if the classes should be encapsulated:
# class WsdlConvert
#   class Definitions
#     class Binding
#       class Operation
#       end
#     end
#   end
# end
#
# vs.
#
# class WsdlConvert
#   class Definitions
#   end
#   class Binding
#   end
#   class Operation
#   end
# end

# I think they should be encapsulated, and each one should have a setup
# method, that takes the parsed wsdl, and initializes each sub-object.

class String
  def camelize
    self.gsub(/(.)([A-Z])/, '\1_\2').to_s.downcase
  end

  def classify
    self.gsub(/(?:^|_)([a-z])/){|x| "#{x.to_s.gsub(/_/,'').upcase}"}
  end
end

class WsdlConvert
  include MultiXml

  attr_accessor :parsed

  # public api
  attr_accessor :definitions
  attr_accessor :types, :elements
  attr_accessor :message
  attr_accessor :port_type
  attr_accessor :binding, :operations
  attr_accessor :service

  #options
  attr_accessor :generator

  def initialize(file, options={})
    wsdl = File.read(file)
    @parsed = MultiXml.parse(wsdl)
    #@generator = options[:generator] || CurlGenerator
  end

  def definitions
    @parsed['definitions']
  end

  def service
    definitions['service']
  end

  def bindings
    definitions['binding']
  end

  class XmlNode
    attr_accessor :node, :name, :type
    def initialize(node)
      @node = node
      extract
    end

    def extract
      @node.each{|k,v|
        ks = k.to_s
        if self.class.const_defined?(ks.classify)
          instance_variable_set("@#{ks}".to_sym, self.class.const_get(ks.classify).new(v)) if respond_to?("#{ks}=")
        else
          instance_variable_set("@#{ks}", v) if respond_to?("#{ks}=")
        end
      }
    end
  end

  class Packet < XmlNode
    attr_accessor :header, :body
    class Header < XmlNode
    end
    class Body < XmlNode
    end
  end

  class Definition < XmlNode
    attr_accessor :port_type
    class Type < XmlNode
      attr_accessor :schema
      class Schema < XmlNode
        attr_accessor :element
        class Element < XmlNode
          attr_accessor :complex_type
          class ComplexType < XmlNode
            attr_accessor :sequence
            class Sequence < XmlNode
              attr_accessor :element
            end
          end
          class SimpleType < XmlNode
            attr_accessor :restriction
            class Restriction < XmlNode
              attr_accessor :length, :pattern, :enumeration
            end
          end
        end
      end
    end

    class Message < XmlNode
      attr_accessor :part
      class Part < XmlNode
        attr_accessor :element
      end
    end

    class PortType < XmlNode
      attr_accessor :operation
      class Operation < XmlNode
        attr_accessor :input, :output
        class Input < Packet
        end
        class Output < Packet
        end
      end
    end

    class Binding < XmlNode
      attr_accessor :operations
      class SoapBinding < XmlNode
        attr_accessor :soap_action
      end
      class Operation < XmlNode
        attr_accessor :input, :output
        class Input < Packet
        end
        class Output < Packet
        end
      end
    end

    class Service < XmlNode
      attr_accessor :documentation, :port
      class Port < XmlNode
        attr_accessor :address
        class Address < XmlNode
          attr_accessor :location
        end
      end
    end
  end
end

node = WsdlConvert.new('example_api.wsdl')
puts node

#convert = WsdlConvert.new('example_api.wsdl')
