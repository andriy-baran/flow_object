module FlowObject
  class Base
    include MatureFactory
    include MatureFactory::Features::Assemble

    composed_of :stages, :inputs, :outputs

    class << self
      attr_reader :in, :out, :initial_values
    end

    attr_reader :output, :given

    def initialize(given)
      @given = given
      @output = self.class.send(:__fo_wrap_output__)
      self.class.after_output_initialize.call(@output) if self.class.after_output_initialize
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
        __fo_resolve_cascade__(*__fo_process__(flow: flow))
      end

      def flow(name = :main, &block)
        wrap(name, delegate: true, &block)
      end

      def after_input_initialize(&block)
        block_given? ? @after_input_initialize = block : @after_input_initialize
      end

      def after_flow_initialize(&block)
        block_given? ? @after_flow_initialize = block : @after_flow_initialize
      end

      def after_input_check(&block)
        block_given? ? @after_input_check = block : @after_input_check
      end

      def after_flow_check(&block)
        block_given? ? @after_flow_check = block : @after_flow_check
      end

      def after_output_initialize(&block)
        block_given? ? @after_output_initialize = block : @after_output_initialize
      end

      private

      def halt_flow?(object, id)
        false
      end

      def __fo_process__(flow: :main)
        failure, step_name, group = false, self.in, :input
        plan    = __fo_build_flow__(flow, step_name, group, __fo_wrap_input__)
        cascade = __fo_run_flow__(plan,
                    proc{|_,id| step_name = id.title},
                    proc{ failure = true },
                    after_input_initialize,
                    after_flow_initialize)
        after_flow_check.call(cascade.public_send(step_name)) if after_flow_check
        [cascade, step_name, failure]
      end

      def __fo_build_flow__(flow, step_name, group, object)
        public_send(:"build_#{flow}", title: step_name, group: group, object: object)
      end

      def __fo_run_flow__(plan, on_step, on_failure, on_input, on_flow)
        step_index = 0
        plan.call do |object, id|
          on_input.call(object) if on_input && id.group == :input
          on_flow.call(object) if step_index == 1 && on_flow && id.group == :stage
          on_step.call(object, id)
          step_index += 1
          if halt_flow?(object, id)
            on_failure.call(object, id)
            throw :halt
          end
          after_input_check.call(object) if after_input_check && id.group == :input
        end
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

      def __fo_resolve_cascade__(cascade, step, failure)
        new(cascade).tap do |flow|
          if failure
            __fo_notify_error__(flow, step)
          else
            __fo_notify_success__(flow)
          end
        end
      end

      def __fo_notify_error__(flow, step)
        if flow.output.respond_to?(:"on_#{step}_failure")
          flow.output.public_send(:"on_#{step}_failure", flow.given)
        elsif flow.output.respond_to?(:on_failure)
          flow.output.on_failure(flow.given, step)
        elsif flow.respond_to?(:"on_#{step}_failure")
          flow.public_send(:"on_#{step}_failure")
        else
          flow.on_failure(step)
        end
      end

      def __fo_notify_success__(flow)
        if flow.output.respond_to?(:on_success)
          flow.output.on_success(flow.given)
        else
          flow.on_success
        end
      end
    end

    extend ClassMethods
  end
end
