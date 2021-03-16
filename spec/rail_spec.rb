require 'spec_helper'

RSpec.describe FlowObject::Base do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :json
            flow do
              input :mash, base_class: Class.new(OpenStruct), init: ->(klass, value) { klass.new(value) }
              stage :authorize, base_class: Class.new(Object)
              stage :sync, base_class: Class.new(Object)
              stage :store, base_class: Class.new(Object)
              stage :formatter, base_class: Class.new(Object)
              output :json
            end
            mash_input do
              def a; 'a'; end
              def valid?; true; end
            end
            authorize_stage do
              def o; 'o'; end
              def valid?; true; end
            end
            sync_stage do
              def u; 'u'; end
              def valid?; true; end
            end
            store_stage do
              def e; 'e'; end
              def valid?; true; end
            end
            formatter_stage do
              def i; 'i'; end
              def valid?; true; end
            end
            json_output do
              attr_accessor :str
            end
            def on_success
              output.str = "#{flow.a}#{flow.o}#{flow.u}#{flow.e}y#{flow.i}#{flow.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'flow has access to all nested methods' do
        operation = operation_class.accept(value).call
        expect(operation.output.str).to eq('aoueyi3')
      end
    end

    context 'when something went wrong' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :json
            flow do
              input :mash, base_class: Class.new(OpenStruct), init: ->(klass, values) { klass.new(values) }
              stage :authorize, base_class: Class.new(Object)
              stage :sync, base_class: Class.new(Object)
              stage :store, base_class: Class.new(Object)
              stage :formatter, base_class: Class.new(Object)
              output :json
            end
            def self.halt_flow?(object, id)
              !object.valid?
            end
            mash_input do
              def a; 'a'; end
              def valid?; true; end
            end
            authorize_stage do
              def o; 'o'; end
              def valid?; false; end
              def errors
                ['error']
              end
            end
            sync_stage do
              def u; 'u'; end
            end
            store_stage do
              def e; 'e'; end
            end
            formatter_stage do
              def i; 'i'; end
            end
            json_output do
              attr_accessor :step, :errors
            end
            def on_failure(step)
              output.errors = flow.errors
              output.step = step
            end
          end
        end
        value { { id: 3 } }
      end

      it 'flow has errors' do
        operation = operation_class.accept(value).call
        expect(operation.output.errors).to_not be_empty
      end
    end
  end
end
