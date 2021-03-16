module FlowObject
  class Runner
    attr_reader :step_name, :failure, :flow

    def initialize(plan, callbacks, halt_if_proc)
      @plan = plan
      @flow = flow
      @failure = false
      @step_name = nil
      @callbacks = callbacks
      @step_index = 0
      @halt_if_proc = halt_if_proc
    end

    def execute_plan
      @flow = call_flow_builder
      after_flow_check(flow.public_send(@step_name))
      self
    end

    private

    def call_flow_builder
      @plan.call do |object, id|
        handle_step(object, id) { throw :halt }
      end
    end

    def after_flow_check(object)
      @callbacks.after_flow_check.call(object)
    end

    def after_input_initialize(object)
      @callbacks.after_input_initialize.call(object)
    end

    def after_flow_initialize(object)
      @callbacks.after_flow_initialize.call(object)
    end

    def after_input_check(object)
      @callbacks.after_input_check.call(object)
    end

    def second_step?
      @step_index == 1
    end

    def input_step?(id)
      id.group == :input
    end

    def flow_step?(id)
      id.group == :stage
    end

    def handle_step(object, id)
      after_input_initialize(object) if input_step?(id)
      after_flow_initialize(object) if second_step? && flow_step?(id)
      @step_name = id.title
      @step_index += 1
      yield if @failure = @halt_if_proc.call(object, id)
      after_input_check(object) if input_step?(id)
    end

  end
end
