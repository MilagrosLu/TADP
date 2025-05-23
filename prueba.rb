# frozen_string_literal: true

require_relative 'TP_RESOL.rb'

class Atacante
  attr_accessor :vida, :fuerza
  def descansar
    self.fuerza += 50
  end

end

class Guerrero < Atacante
  extend Contracts
  def initialize (vida , fuerza)
    self.vida= vida
    puts "VIDAAAAAA : #{self.vida}"
    self.fuerza= fuerza
    puts "FUERZAAAAAA : #{self.fuerza}"
  end
  invariant { vida >= 0 }
  def modificar_vida(cantidad)
    self.vida += cantidad
  end
  pre { fuerza == 3}
  post {vida > 1}
  def modificar_fuerza(cantidad)
    self.fuerza += cantidad
    self.vida += cantidad / 2
  end
  invariant { fuerza > 0 && fuerza < 100 }
  pre {divisor > 0}
  def atacar(otro,divisor)
    otro.vida -= fuerza
    otro.fuerza = otro.fuerza / divisor
  end


end

mili = Guerrero.new(6,10)

