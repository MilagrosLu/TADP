# frozen_string_literal: true

module Contracts
  def self.extended(base)
    @normal = false
    anteriores = base.instance_methods(true)
    anteriores.delete(:self)
    anteriores.each do |method|
      method_unbound= base.instance_method(method)
      # base.define_method(method) do |*args, &block|
      #   puts "METODO #{method}"
      #   result = method_unbound.bind(self).call(*args, &block)
      #   "puts TERMINE DE EJECUTAR EN CORE-----------------------"
      #   result
      # end
      base.method_added(method)
    end
    @normal = true
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
    return if @method_adding
    @method_adding = true
    original_method = instance_method(method_name)
    if @normal
      return if !@procs || @procs.empty?
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
        #if self.class.procs != nil
          self.class.procs.each do |before, _|
            puts "HAGO BEFORE #{before}"
            argument_context.instance_exec(&before) if before
          end
          #end
        puts "voy a hacer el original"
        result = original_method.bind(self).call(*args, &block)
        #if self.class.procs != nil
          self.class.procs.each do |_, after|
            puts "after proc #{after.inspect}"
            argument_context.instance_exec(result, &after) if after
          end
        #end
        argument_context.instance_exec(result, &pos) if pos
        result
      end
    else
      define_method method_name do |*args, &block| #dentro del define es la isntancia del guerrero self
        puts "voy a ejecutar #{method_name} en #{self}"
        unless @llamado
          @llamado = true
          if self.class.procs != nil
            self.class.procs.each do |before, _|
              puts "HAGO BEFORE #{before}"
              instance_exec(&before) if before
            end
          end
          puts "voy a hacer el original"
          result = original_method.bind(self).call(*args, &block)
          if self.class.procs != nil
            self.class.procs.each do |_, after|
              puts "after proc #{after.inspect}"
              instance_exec(result, &after) if after
            end
          else
            result = original_method.bind(self).call(*args, &block)
            @llamado = false
        end
        end
        result
      end
    end

    #cleanup_procs
    @pre_procs = nil
    @post_procs = nil
    @method_adding = false
  end


end