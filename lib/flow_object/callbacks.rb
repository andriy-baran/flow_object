# frozen_string_literal: true

module FlowObject
  # Storage for users callbacks
  class Callbacks
    NOOP = proc {}.freeze

    Iteration = Struct.new(:idx, :type, :list_size) do
      def output_checked?
        output? && checked?
      end

      def generic_alias
        return :"input_#{type}" if input?
        return :flow_initialized if flow_initialized?
        return :flow_checked if flow_checked?
        return :output_initialized if output_initialized?
      end

      private

      def flow_initialized?
        idx == 1 && initialized?
      end

      def flow_checked?
        idx == list_size - 2 && checked?
      end

      def output_initialized?
        output? && initialized?
      end

      def input?
        idx.zero?
      end

      def initialized?
        type == :initialized
      end

      def checked?
        type == :checked
      end

      def output?
        idx == list_size - 1
      end
    end

    def initialize(list)
      @callbacks = Hash.new { |hash, key| hash[key] = NOOP }
      each_callback(list) do |callback, callback_alias|
        define_singleton_method(callback) do |&block|
          block.nil? ? @callbacks[callback] : @callbacks[callback] = block
        end
        singleton_class.class_eval { alias_method(callback_alias, callback) } if callback_alias
      end
    end

    private

    def each_callback(list)
      list_size = list.size
      list.each.with_index do |method_name, idx|
        { initialized: :"#{method_name}_initialized", checked: :"#{method_name}_checked" }.each do |type, callback|
          callback_alias = Iteration.new(idx, type, list_size).generic_alias
          yield(callback, callback_alias)
        end
      end
    end
  end
end
