# frozen_string_literal: true

module Contracts
  def before_and_after_each_call(before_proc, after_proc)
    @procs ||= []
    @procs << [before_proc, after_proc]
    @counter ||= 0
  end

  def procs
    @procs ||= []
  end

  def pre_procs
    @pre_procs ||= []
  end

  def post_procs
    @post_procs ||= []
  end

  def pre(&block)
    pre_proc = proc do
      raise 'RuntimeError: Failed to meet preconditions' unless instance_exec(&block)
    end
    pre_procs << pre_proc
    before_and_after_each_call(pre_proc, nil)
  end

  def post(&block)
    post_proc = proc do |result|
      raise 'RuntimeError: Failed to meet postconditions' unless instance_exec(result, &block)
    end
    post_procs << post_proc
    before_and_after_each_call(nil, post_proc)
  end
  def invariant(&block)
    invariant_proc = proc do |result|
      raise "RuntimeError: Failed to meet invariant #{block}"unless instance_exec(result, &block)
    end
    metodos_anteriores = instance_methods()# tomo los metodos de instancia, y a ellos les pongo la evaluacion de invariant al final
    metodos_anteriores.each do |metodo|
      original_method = instance_method(metodo)
      define_method metodo do |*args, &block|
        @invariant_executing ||= false #para que el originla method no vuelva recursivamente a llamar
        unless @invariant_executing == true
          puts "ENTRO EN IF "
          @invariant_executing = true
          # Ejecuta el método original
          result = original_method.bind(self).call(*args, &block)
          @invariant_executing = false
          invariant_proc.call
          return result
        end
      end
    end
    before_and_after_each_call(nil, invariant_proc)
  end

  def method_added(method_name) # self es la clase
    return if @method_adding || !@procs || @procs.empty?
    @method_adding = true
    original_method = instance_method(method_name)
    proc_dupes = @procs.dup
    define_method method_name do |*args, &block| #dentro del define es la isntancia del guerrero self
      instance = self
      argument_context = Object.new
      original_method.parameters.each_with_index do |(_, parameter_name), index|
        argument_context.define_singleton_method(parameter_name) { args[index] } if parameter_name
      end
      argument_context.define_singleton_method(:method_missing) do |method, *m_args, &m_block|
        instance.send(method, *m_args, &m_block)
        super()
      end
      proc_dupes.each do |before, _|

        argument_context.instance_exec(&before) if before
      end

      result = original_method.bind(self).call(*args, &block)

      proc_dupes.each do |_, after|

        argument_context.instance_exec(result, &after) if after
      end
      result
    end
    cleanup_procs
    @method_adding = false



  end

  private

  def cleanup_procs
    @procs = @procs.reject do |before_proc, after_proc|
      (before_proc && pre_procs.include?(before_proc)) ||
        (after_proc && post_procs.include?(after_proc))
    end
  end

end