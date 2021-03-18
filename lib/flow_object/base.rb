module FlowObject
  class Base
    include MatureFactory
    include MatureFactory::Features::Assemble

    produces :stages, :inputs, :outputs

    class << self
      extend Forwardable
      attr_reader :in, :out, :initial_values
      def_delegators :callbacks, :after_input_initialize, :after_flow_initialize,
        :after_input_check, :after_flow_check, :after_output_initialize
    end

    attr_reader :output

    def initialize(flow, step_name = :flow)
      @output = self.class.send(:__fo_wrap_output__)
      self.class.link_with_delegation(@output, flow, step_name, true)
      self.class.after_output_initialize.call(@output)
    end

    def on_failure(failed_step = nil)
      # NOOP
    end

    def on_success
      # NOOP
    end

    module ClassMethods
      def inherited(subclass)
        super
        subclass.from(self.in)
        subclass.to(self.out)
        subclass.after_input_initialize(&self.after_input_initialize)
        subclass.after_flow_initialize(&self.after_flow_initialize)
        subclass.after_input_check(&self.after_input_check)
        subclass.after_flow_check(&self.after_flow_check)
        subclass.after_output_initialize(&self.after_output_initialize)
      end

      def callbacks
        @callbacks ||= Callbacks.new
      end

      def from(input)
        @in = input
        self
      end

      def to(output)
        @out = output
        self
      end

      def accept(*values)
        @initial_values = values
        self
      end

      def call(flow: :main)
        __fo_resolve__(__fo_process__(flow: flow))
      end

      def flow(name = :main, &block)
        wrap(name, delegate: true, &block)
      end

      def link_with_delegation(target, object, accessor, delegate)
        MatureFactory::Features::Assemble::AbstractBuilder
          .link_with_delegation(target, object, accessor, delegate)
      end

      private

      def halt_flow?(object, id)
        false
      end

      def __fo_process__(flow: :main)
        plan    = __fo_build_flow__(flow, self.in, :input, __fo_wrap_input__)
        Runner.new(plan, callbacks, method(:halt_flow?)).execute_plan
      end

      def __fo_build_flow__(flow, step_name, group, object)
        public_send(:"build_#{flow}", title: step_name, group: group, object: object)
      end

      def __fo_wrap_input__
        return initial_values if self.in.nil?
        input_class = public_send(:"#{self.in}_input_class")
        return initial_values if input_class.nil?
        public_send(:"new_#{self.in}_input_instance", *initial_values)
      end

      def __fo_wrap_output__
        # rescue NoMethodError => ex
        # "You have not define output class. Please add `output :#{self.out}`"
        return if self.out.nil?
        return unless self.respond_to?(:"#{self.out}_output_class")
        output_class = public_send(:"#{self.out}_output_class")
        return if output_class.nil?
        public_send(:"new_#{self.out}_output_instance")
      end

      def __fo_resolve__(runner)
        new(runner.flow, runner.step_name).tap do |handler|
          if runner.failure
            __fo_notify_error__(handler, runner.step_name)
          else
            __fo_notify_success__(handler)
          end
        end
      end

      def __fo_notify_error__(handler, step)
        if handler.output.respond_to?(:"on_#{step}_failure")
          handler.output.public_send(:"on_#{step}_failure")
        elsif handler.output.respond_to?(:on_failure)
          handler.output.on_failure(step)
        elsif handler.respond_to?(:"on_#{step}_failure")
          handler.public_send(:"on_#{step}_failure")
        else
          handler.on_failure(step)
        end
      end

      def __fo_notify_success__(handler)
        if handler.output.respond_to?(:on_success)
          handler.output.on_success
        else
          handler.on_success
        end
      end
    end

    extend ClassMethods
  end
end
