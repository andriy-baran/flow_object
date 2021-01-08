module FlowObject
  class Base
    include MatureFactory
    include MatureFactory::Features::Assemble

    composed_of :stages, :inputs, :outputs

    class << self
      attr_accessor :in, :out, :initial_values
    end

    attr_reader :output, :given

    def initialize(given)
      @given = given
      @output = self.class.__fo_wrap_output__
    end

    def self.inherited(subclass)
      super
      subclass.from(self.in)
      subclass.to(self.out)
    end

    def self.from(input)
      self.in = input
      self
    end

    def self.to(output)
      self.out = output
      self
    end

    def self.__fo_wrap_input__
      return initial_values if self.in.nil?
      input_class = public_send(:"#{self.in}_input_class")
      return initial_values if input_class.nil?
      public_send(:"new_#{self.in}_input_instance", *initial_values)
    end

    def self.__fo_wrap_output__
      # rescue NoMethodError => ex
      # "You have not define output class. Please add `output :#{self.out}`"
      return if self.out.nil?
      return unless self.respond_to?(:"#{self.out}_output_class")
      output_class = public_send(:"#{self.out}_output_class")
      return if output_class.nil?
      public_send(:"new_#{self.out}_output_instance")
    end

    def self.accept(*values)
      self.initial_values = values
      self
    end

    def self.__fo_resolve_cascade__(cascade, step, failure)
      new(cascade).tap do |flow|
        if failure
          __fo_notify_error__(flow, step)
        else
          __fo_notify_success__(flow)
        end
      end
    end

    def self.__fo_notify_error__(flow, step)
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

    def self.__fo_notify_success__(flow)
      if flow.output.respond_to?(:on_success)
        flow.output.on_success(flow.given)
      else
        flow.on_success
      end
    end

    def self.call(flow: :main)
      failure, previous_step, object = false, :"#{self.in}_input", __fo_wrap_input__
      plan    = public_send(:"build_#{flow}", previous_step, object)
      cascade = plan.call do |object, id|
                  previous_step = id.to_sym
                  if !object.valid?
                    failure = true
                    throw :halt
                  end
                end
      __fo_resolve_cascade__(cascade, previous_step, failure)
    end

    def self.flow(name = 'main', &block)
      wrap(name, delegate: true, &block)
    end

    def on_failure(failed_step = nil)
      # NOOP
    end

    def on_success
      # NOOP
    end
  end
end
