# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlowObject::Base do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :json
            input :mash, base_class: Struct.new(:id), init: ->(klass, value) { klass.new(value) }
            output :rake, base_class: OpenStruct
            output :json, base_class: OpenStruct
            def self.halt_flow?(object, _id)
              !object.valid?
            end
            flow do
              stage :authorize
              stage :sync
              stage :store
              stage :formatter
            end
            mash_input do
              def a
                'a'
              end

              def valid?
                true
              end
            end
            authorize_stage do
              def o
                'o'
              end

              def valid?
                true
              end
            end
            sync_stage do
              def u
                'u'
              end

              def valid?
                true
              end
            end
            store_stage do
              def e
                'e'
              end

              def valid?
                true
              end
            end
            formatter_stage do
              def i
                'i'
              end

              def valid?
                true
              end
            end
            json_output do
              attr_accessor :string

              def on_success
                self.string = "#{a}#{o}#{u}#{e}y#{i}#{id}"
              end
            end
            rake_output do
              def on_success
                self.obj = {
                  a: a,
                  o: o,
                  u: u,
                  e: e,
                  i: i,
                  id: id
                }
              end
            end

            def on_success
              output.string = "#{output.a}#{output.o}#{output.u}#{output.e}y#{output.i}#{output.id}"
            end
          end
        end
        value { 3 }
        rake_result do
          {
            a: 'a',
            o: 'o',
            u: 'u',
            e: 'e',
            i: 'i',
            id: 3
          }
        end
      end

      it 'calls on_success of :json output' do
        operation = operation_class.call(input: value)
        expect(operation.output.string).to eq('aoueyi3')
      end
    end

    context 'when something went wrong' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :json
            input :mash, base_class: Struct.new(:id), init: ->(klass, value) { klass.new(value) }
            output :rake, base_class: OpenStruct
            output :json
            flow do
              stage :authorize
              stage :sync
              stage :store
              stage :formatter
            end
            def self.halt_flow?(object, _id)
              !object.valid?
            end
            mash_input do
              def a
                'a'
              end

              def valid?
                true
              end
            end
            authorize_stage do
              def o
                'o'
              end

              def valid?
                false
              end

              def errors
                ['Error with id=3']
              end
            end
            sync_stage do
              def u
                'u'
              end
            end
            store_stage do
              def e
                'e'
              end
            end
            formatter_stage do
              def i
                'i'
              end
            end
            json_output do
              attr_accessor :error, :step

              def on_authorize_failure
                self.error = errors.join
                self.step = :authorize_stage
              end
            end
            rake_output do
              def on_failure(_step)
                self.error = errors.join
              end
            end

            def on_authorize_failure
              output.errors.join
            end
          end
        end
        value { 3 }
      end

      it 'calls on_authorize_failure of :json output' do
        operation = operation_class.call(input: value)
        expect(operation.output).to have_attributes(step: :authorize_stage, error: 'Error with id=3')
      end
    end

    context 'when something went wrong in inputs' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :json
            input :mash, base_class: Struct.new(:id), init: ->(klass, value) { klass.new(value) }
            output :rake, base_class: OpenStruct
            output :json
            flow do
              stage :authorize
              stage :sync
              stage :store
              stage :formatter
            end
            def self.halt_flow?(object, _id)
              !object.valid?
            end
            mash_input do
              def a
                'a'
              end

              def valid?
                false
              end

              def errors
                ['Error with id=3']
              end
            end
            authorize_stage do
              def o
                'o'
              end

              def valid?
                false
              end
            end
            sync_stage do
              def u
                'u'
              end
            end
            store_stage do
              def e
                'e'
              end
            end
            formatter_stage do
              def i
                'i'
              end
            end
            json_output do
              attr_accessor :error, :step

              def on_mash_failure
                self.error = errors.join
                self.step = :mash_input
              end
            end
            rake_output do
              def on_failure(_step)
                self.error = errors.join
              end
            end

            def on_authorize_failure
              output.errors.join
            end
          end
        end
        value { 3 }
      end

      it 'calls on_authorize_failure of :json output' do
        operation = operation_class.call(input: value)
        expect(operation.output).to have_attributes(step: :mash_input, error: 'Error with id=3')
      end
    end
  end
end
