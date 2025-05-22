# frozen_string_literal: true
require 'rspec'
require_relative 'prueba.rb'
require_relative 'TP_RESOL.rb'

describe Guerrero do
  let(:guerrero1) { Guerrero.new(4,5) }
  let(:guerrero2) { Guerrero.new(2,1) }
  let(:guerrero70) {Guerrero.new(4,70)}
  describe '#inariant' do
    it 'deberia tirar error el invariant' do
      expect{guerrero3 = Guerrero.new(-3,0)}.to raise_error(RuntimeError)
    end
    it "deberia tirar error el invariant settear vida en -1" do
      expect{guerrero2.vida=-1}.to raise_error(RuntimeError)
    end
    it 'debería tirar error' do
      expect {guerrero2.modificar_vida(-3)}.to raise_error(RuntimeError)
    end
    it 'La vida deberia quedar en 0' do
      guerrero2.modificar_vida(-2)
      expect(guerrero2.vida).to eq(0)
    end
    it 'deberia tirar error por invariant' do
      expect {guerrero1.modificar_fuerza(200)}.to raise_error(RuntimeError)
    end
    it "deberia tirar error invariant" do
      expect{guerrero70.descansar}.to raise_error(RuntimeError)
    end
    it "deberia funcionar " do
      guerrero2.descansar
      expect(guerrero2.fuerza).to eq(51)
    end
  end
end