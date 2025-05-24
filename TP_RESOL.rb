# frozen_string_literal: true

module Contracts
  def self.extended(base)
    anteriores = base.instance_methods(false)
    ancestros = base.ancestors
    punto_corte = ancestros.index(Object)
    puts punto_corte
    final = ancestros.slice(0, punto_corte )
    puts final
    final.each do |anc|
      # puts anc
      @ant_final = anteriores + anc.instance_methods(false)
    end
    puts @ant_final.inspect

    (@ant_final).each do |method|
      original_method = base.instance_method(method)
      base.define_method(method) do |*args, &block|
        unless @llamado
          @llamado = true
          instance = self
          argument_context = Object.new
          original_method.parameters.each_with_index do |(_, parameter_name), index|
            argument_context.define_singleton_method(parameter_name) { args[index] } if parameter_name
          end
          argument_context.define_singleton_method(:method_missing) do |method, *m_args, &m_block|
            if instance.methods.include?(method)
              instance.send(method, *m_args, &m_block)
            else
              super(method, *m_args, &m_block)
            end

          end
          puts 'evaluo hacer before '
          base.exclude_procs_with_method(method).each do |before, _|
            puts "HAGO BEFORE #{before} CON METODO #{method}"
            argument_context.instance_exec(&before) if before
          end

          result = original_method.bind(self).call(*args, &block)

          base.exclude_procs_with_method(method).each do |_, after|
            puts "after proc #{after.inspect}"
            argument_context.instance_exec(result, &after) if after
          end
          @llamado = false
          result

        else
          result = original_method.bind(self).call(*args, &block)

          result
        end
      end
    end
  end
  def before_and_after_each_call(before_proc, after_proc)
    @procs ||= []
    @procs << [before_proc, after_proc]
  end

  def procs
    @procs ||=[]
  end

  def pre_procs
    @pre_procs
  end

  def post_procs
    @post_procs
  end

  def pre(&block)
    pre_proc = proc do
      raise 'RuntimeError: Failed to meet preconditions' unless instance_exec(&block)
    end
    @pre_procs = pre_proc
  end

  def post(&block)
    post_proc = proc do |result|
      raise 'RuntimeError: Failed to meet postconditions' unless instance_exec(result, &block)
    end
    @post_procs = post_proc
  end
  def invariant(&block)

    invariant_proc = proc do |result|
      raise "RuntimeError: Failed to meet invariant #{block}"unless instance_exec(result, &block)
    end
    before_and_after_each_call(nil, invariant_proc)
    puts "llama a invariant #{@procs.inspect}"
  end

  def method_added(method_name) # self es la clase
    return if @method_adding || !@procs || @procs.empty?
    @method_adding = true
    original_method = instance_method(method_name)
    contract_class = self
      pre = @pre_procs
      pos = @post_procs
      define_method method_name do |*args, &block| #dentro del define es la isntancia del guerrero self
        puts "tengo define method de method added #{method_name}"
        instance = self
        argument_context = Object.new
        original_method.parameters.each_with_index do |(_, parameter_name), index|
          argument_context.define_singleton_method(parameter_name) { args[index] } if parameter_name
        end
        argument_context.define_singleton_method(:method_missing) do |method, *m_args, &m_block|
          if instance.methods.include?(method)
            instance.send(method, *m_args, &m_block)
          else
            super(method, *m_args, &m_block)
          end

        end
        argument_context.instance_exec(&pre) if pre
        puts 'evaluo hacer before '
        contract_class.exclude_procs_with_method(method_name).each do |before, _|
            puts "HAGO BEFORE #{before}"
            argument_context.instance_exec(&before) if before
          end

        result = original_method.bind(self).call(*args, &block)

        contract_class.exclude_procs_with_method(method_name).each do |_, after|
            puts "after proc #{after.inspect}"
            argument_context.instance_exec(result, &after) if after
          end
        argument_context.instance_exec(result, &pos) if pos
        result
      end
    #cleanup_procs
    @pre_procs = nil
    @post_procs = nil
    @method_adding = false
  end
  def exclude_procs_with_method(method_name)
    procs.dup.reject do |proc_pair|
      [proc_pair[0], proc_pair[1]].compact.any? do |proc|
        proc.inspect.include?(method_name.to_s)
      end
    end
  end

end