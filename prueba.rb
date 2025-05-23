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
    puts "vida seteada #{vida}"
    self.vida= vida
    puts "-------------------------------------------------------------------------------"
    puts "fuerza seteada #{fuerza}"
    self.fuerza= fuerza

  end
  invariant { vida >= 0 }
  def modificar_vida(cantidad)
    self.vida += cantidad
  end
  def modificar_fuerza(cantidad)
    self.fuerza += cantidad
    self.vida += cantidad / 2
  end
  invariant { fuerza > 0 && fuerza < 100 }
  def atacar(otro)
    otro.vida -= fuerza
  end


end

mili = Guerrero.new(4,2)
mili.modificar_vida(1)