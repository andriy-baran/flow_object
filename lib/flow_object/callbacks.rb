module FlowObject
  class Callbacks
    SUPPORTED = %i[
      after_input_initialize
      after_flow_initialize
      after_input_check
      after_flow_check
      after_output_initialize
    ].freeze

    NOOP = proc {}.freeze

    def initialize
      @callbacks = Hash.new { |hash, key| hash[key] = NOOP }
    end

    def method_missing(name, *_attrs, &block)
      if SUPPORTED.include?(name)
        block_given? ? @callbacks[name] = block : @callbacks[name]
      else
        super
      end
    end

    def respond_to_missing?(name, *)
      SUPPORTED.include?(name)
    end
  end
end
