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
          input :mash, base_class: OpenStruct
          output :rake

          flow do
            stage :authorize
            stage :provide
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
      operation_class.after_input_initialize {|o| i += o.id }
      operation_class.after_flow_initialize {|o| i += 3 }
      operation_class.after_input_check {|o| i += 1 }
      operation_class.after_flow_check {|o| o.val = i += 1 }
      operation_class.after_output_initialize {|o| i += 4 }
      child_class = Class.new(operation_class)
      operation = child_class.accept(value).call
      expect(i).to eq 13
      expect(operation.output.val).to eq 9
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
