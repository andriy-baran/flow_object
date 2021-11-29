# frozen_string_literal: true

class MashClass < OpenStruct; end

class RakeClass; end

class AuthorizeClass; end

class ProvideClass; end

RSpec.describe FlowObject do
  it 'has a version number' do
    expect(FlowObject::VERSION).not_to be nil
  end

  describe 'inheritance' do
    vars do
      operation_class do
        Class.new(FlowObject::Base) do
          from :mash
          to :rake
          input :mash, base_class: MashClass
          output :rake, base_class: RakeClass

          flow do
            stage :authorize, base_class: AuthorizeClass
            stage :provide, base_class: ProvideClass
          end

          provide_stage { attr_accessor :val }

          rake_output do
            attr_accessor :context
          end

          def on_success
            output.context = ''
          end
        end
      end
      value { { id: 3 } }
    end

    it 'has callbacks' do
      i = 1
      mash = nil
      mash_ac = nil
      authorize = nil
      provide = nil
      rake = nil
      child_class = Class.new(operation_class)
      handler = child_class.call(input: value) do |callbacks|
        callbacks.mash_input_initialized { |o| mash = o; p i += o.id } # 1 + 3 = 4
        callbacks.authorize_stage_initialized { |o| authorize = o; p i += 3 } # 5 + 3 = 8
        callbacks.mash_input_checked { |o| mash_ac = o; p i += 1 } # 4 + 1 = 5
        callbacks.provide_stage_checked { |o| provide = o; p o.val = i += 1 } # 8 + 1 = 9
        callbacks.rake_output_initialized { |o| rake = o; p i += 4 } # 9 + 4 = 13
      end
      expect(i).to eq 13
      expect(handler.output.val).to eq 9
      expect(mash).to be_a(MashClass)
      expect(authorize).to be_a(AuthorizeClass)
      expect(mash_ac).to be_a(MashClass)
      expect(provide).to be_a(ProvideClass)
      expect(rake).to be_a(RakeClass)
    end

    it 'inherits proprties of superclass' do
      child_class = Class.new(operation_class)
      operation = child_class.call(input: value)
      expect(child_class.mash_input_class).to eq operation_class.mash_input_class
      expect(child_class.rake_output_class).to eq operation_class.rake_output_class
      expect(child_class.authorize_stage_class).to eq operation_class.authorize_stage_class
      expect(child_class.main_wrapped_struct_class).to eq operation_class.main_wrapped_struct_class
      expect(operation.output).to be_a operation_class.rake_output_class
      expect(operation.output).to be_a child_class.rake_output_class
    end
  end

  describe 'error handling' do
    vars do
      operation_class do
        Class.new(FlowObject::Base) do
          from :mash
          to :rake
          input :mash, base_class: MashClass
          output :rake, base_class: RakeClass

          flow do
            stage :authorize, base_class: AuthorizeClass
            stage :provide, base_class: ProvideClass
          end

          provide_stage do
            attr_accessor :val

            def initialize
              raise 'No way'
            end
          end

          rake_output do
            attr_accessor :context
          end

          def on_success
            output.context = ''
          end

          def on_exception(exception)
            output.context = exception.step_id.to_s
          end
        end
      end
      value { { id: 3 } }
    end

    it 'raises proper error' do
      child_class = Class.new(operation_class)
      operation = child_class.call(input: value)
      expect(operation.output).to respond_to(:mash)
      expect(operation.output).to respond_to(:authorize)
      expect(operation.output).to_not respond_to(:provide)
      expect(operation.output.context).to eq 'provide_stage'
    end
  end
end
