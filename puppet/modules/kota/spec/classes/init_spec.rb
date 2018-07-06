require 'spec_helper'
describe 'kota' do

  context 'with defaults for all parameters' do
    it { should contain_class('kota') }
  end
end
