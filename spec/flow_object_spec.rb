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
          end
        end
      end
      value { { id: 3 } }
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
