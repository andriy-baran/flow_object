class MashClass < OpenStruct; end
class RakeClass; end
class AuthorizeClass; end
class ProvideClass; end

RSpec.describe FlowObject do
  it "has a version number" do
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

          def on_sucess
            output.context = given
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
      operation_class.after_input_initialize {|o| mash = o; i += o.id }
      operation_class.after_flow_initialize {|o| authorize = o; i += 3 }
      operation_class.after_input_check {|o| mash_ac = o; i += 1 }
      operation_class.after_flow_check {|o| provide = o; o.val = i += 1 }
      operation_class.after_output_initialize {|o| rake = o; i += 4 }
      child_class = Class.new(operation_class)
      operation = child_class.accept(value).call
      expect(i).to eq 13
      expect(operation.output.val).to eq 9
      expect(mash).to be_a(MashClass)
      expect(authorize).to be_a(AuthorizeClass)
      expect(mash_ac).to be_a(MashClass)
      expect(provide).to be_a(ProvideClass)
      expect(rake).to be_a(RakeClass)
    end

    it 'inherits proprties of superclass' do
      child_class = Class.new(operation_class)
      operation = child_class.accept(value).call
      expect(child_class.mash_input_class).to eq operation_class.mash_input_class
      expect(child_class.rake_output_class).to eq operation_class.rake_output_class
      expect(child_class.authorize_stage_class).to eq operation_class.authorize_stage_class
      expect(child_class.main_wrapped_struct_class).to eq operation_class.main_wrapped_struct_class
      expect(operation.output).to be_a operation_class.rake_output_class
      expect(operation.output).to be_a child_class.rake_output_class
    end
  end
end
