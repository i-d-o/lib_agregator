module WebParser
  class Initializator
    def initialize(init_vars = {})
      init_vars.each do |k, v|
        instance_variable_set("@#{k}", v)
        instance_eval("def #{k};@#{k};end")
        # self.instance_eval("def #{k}=(val);@#{k}=val;end")
      end
      @use_cache = true
    end
  end
end
