require 'active_fedora'

ActiveFedora::Attributes::ClassMethods.module_eval do
  # Override DatastreamAttribute to dynamically select the correct
  # terminology path based on DRI metadata class

 # module ClassMethods
  #  private

    def create_attribute_setter(field, dsid, args)
      self.defined_attributes[field] ||= {}
      self.defined_attributes[field][:setter] = lambda do |v|
        ds = self.send(dsid)
        mark_as_changed(field) if value_has_changed?(field, v)
        if ds.kind_of?(ActiveFedora::RDFDatastream)
          ds.send("#{field}=", v)
        # DRI modifications are in the following elsif statement
        elsif ds.class < DRI::Metadata::Base
          terminology = ds.metadata_path field
          if terminology != []
             ds.send(:update_indexed_attributes, {terminology => v})
          end
        else
          terminology = args[:at] || [field]
          ds.send(:update_indexed_attributes, {terminology => v})
        end
      end
      define_method "#{field}=".to_sym do |v|
        self[field]=v
      end
    end

    def create_attribute_reader(field, dsid, args)
        self.defined_attributes[field] ||= {}
        self.defined_attributes[field][:reader] = lambda do |*opts|
          ds = self.send(dsid)
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send(field)
          elsif ds.class < DRI::Metadata::Base
            terminology = ds.metadata_path field
            if terminology != []
              if terminology.length == 1 && opts.present?
                ds.send(terminology.first, *opts)
              else
                ds.send(:term_values, *terminology)
              end
            else #if the field doesn't exist, let's make the result an empty array - Damien
              []
            end
          else
            terminology = args[:at] || [field]
            if terminology.length == 1 && opts.present?
              ds.send(terminology.first, *opts)
            else
              ds.send(:term_values, *terminology)
            end
          end
        end

        if !args[:multiple].nil?
          self.defined_attributes[field][:multiple] = args[:multiple]
        elsif !args[:unique].nil?
          i = 0 
          begin 
            match = /in `(delegate.*)'/.match(caller[i])
            i+=1
          end while match.nil?

          prev_method = match.captures.first
          Deprecation.warn Attributes, "The :unique option for `#{prev_method}' is deprecated. Use :multiple instead. :unique will be removed in ActiveFedora 7", caller(i+1)
          self.defined_attributes[field][:multiple] = !args[:unique]
        else 
          i = 0 
          begin 
            match = /in `(delegate.*)'/.match(caller[i])
            i+=1
          end while match.nil?

          prev_method = match.captures.first
          Deprecation.warn Attributes, "You have not explicitly set the :multiple option on `#{prev_method}'. The default value will switch from true to false in ActiveFedora 7, so if you want to future-proof this application set `multiple: true'", caller(i+ 1)
          self.defined_attributes[field][:multiple] = true # this should be false for ActiveFedora 7
        end

        define_method field do |*opts|
          val = array_reader(field, *opts)
          self.class.multiple?(field) ? val : val.first
        end
      end
    end
  #end
#end