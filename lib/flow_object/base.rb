# frozen_string_literal: true

module FlowObject
  class Base
    include Hospodar
    include Hospodar::Builder

    produces :stages, :inputs, :outputs

    class << self
      attr_reader :in, :out, :initial_values
    end

    extend Forwardable
    def_delegators :callbacks, :output_initialized

    attr_reader :output, :callbacks

    def initialize(flow, callbacks, step_name = :flow)
      @output = self.class.send(:fo_wrap_output)
      @callbacks = callbacks
      Hospodar::Builder.def_accessor(step_name, on: @output, to: flow, delegate: true)
      output_initialized.call(@output)
    end

    def on_exception(exception = nil)
      # NOOP
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
        subclass.to(out)
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

      def call(flow: :main, &block)
        fo_resolve(fo_process(flow: flow, &block))
      end

      def flow(name = :main, &block)
        wrap(name, delegate: true, on_exception: :halt, &block)
      end

      private

      def halt_flow?(_object, _id)
        false
      end

      def fo_process(flow: :main, &block)
        plan = fo_build_flow(flow, self.in, :input, fo_wrap_input)
        callbacks = Callbacks.new(@callbacks_allowlist)
        block.call(callbacks) if block_given?
        Runner.new(plan, callbacks, method(:halt_flow?)).execute_plan
      end

      def fo_build_flow(flow, step_name, group, object)
        plan = send(:"hospodar_perform_planing_for_#{flow}", object, step_name, group)
        @callbacks_allowlist = plan.map(&:last).map(&:to_sym) + [:"#{out}_output"]
        send(:"hospodar_execute_plan_for_#{flow}", plan)
      end

      def fo_wrap_input
        return initial_values if self.in.nil?

        input_class = public_send(:"#{self.in}_input_class")
        return initial_values if input_class.nil?

        public_send(:"new_#{self.in}_input_instance", *initial_values)
      end

      def fo_wrap_output
        # rescue NoMethodError => ex
        # "You have not define output class. Please add `output :#{self.out}`"
        return if out.nil?
        return unless respond_to?(:"#{out}_output_class")

        output_class = public_send(:"#{out}_output_class")
        return if output_class.nil?

        public_send(:"new_#{out}_output_instance")
      end

      def fo_resolve(runner)
        new(runner.flow.public_send(runner.step_name), runner.callbacks, runner.step_name).tap do |handler|
          if runner.flow.exceptional?
            fo_notify_exception(handler, runner.flow.exception)
          elsif runner.failure
            fo_notify_error(handler, runner.step_name)
          else
            fo_notify_success(handler)
          end
        end
      end

      def fo_notify_exception(handler, exception)
        step = exception.step_id.title
        if handler.output.respond_to?(:"on_#{step}_exception")
          handler.output.public_send(:"on_#{step}_exception", exception)
        elsif handler.output.respond_to?(:on_exception)
          handler.output.on_exception(exception)
        elsif handler.respond_to?(:"on_#{step}_exception")
          handler.public_send(:"on_#{step}_exception", exception)
        else
          handler.on_exception(exception)
        end
        fo_notify_error(handler, exception.step_id.title)
      end

      def fo_notify_error(handler, step)
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

      def fo_notify_success(handler)
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
