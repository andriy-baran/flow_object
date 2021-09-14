# frozen_string_literal: true

module FlowObject
  # Triggers flow execution and users callbacks
  class Runner
    attr_reader :step_name, :failure, :flow, :callbacks

    def initialize(plan, callbacks, halt_if_proc)
      @plan = plan
      @flow = flow
      @failure = false
      @step_name = nil
      @callbacks = callbacks
      @halt_if_proc = halt_if_proc
    end

    def execute_plan
      @flow = flow_builder.call
      self
    end

    private

    def flow_builder
      @plan.do_until do |object, id|
        @step_name = id.title
        after_initialize(object, id)
        @failure = @halt_if_proc.call(object, id)
        next true if @failure

        after_check(object, id)
      end
    end

    def after_initialize(object, id)
      @callbacks.public_send(:"#{id}_initialized").call(object)
    end

    def after_check(object, id)
      @callbacks.public_send(:"#{id}_checked").call(object)
      false
    end
  end
end
