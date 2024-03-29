# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlowObject::Base do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(FlowObject::Base) do
            from :mash
            to :rake

            input :array, base_class: OpenStruct, init: lambda { |klass, value, n1, n2|
                                                          klass.new(value.merge(pass: n1, log: n2))
                                                        }
            input :mash, base_class: Struct.new(:id), init: ->(klass, value) { klass.new(value) }
            output :rake, base_class: OpenStruct
            output :json, base_class: OpenStruct

            flow do
              stage :authorize
            end

            array_input do
              def z
                'z'
              end
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

            rake_output do
              attr_accessor :obj

              def on_success
                self.obj = {
                  a: a,
                  o: o,
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
            id: 3
          }
        end
      end

      it 'calls on_success of :rake result' do
        operation = operation_class.call(input: value)
        expect(operation.output.obj).to eq rake_result
      end
    end
  end
end
