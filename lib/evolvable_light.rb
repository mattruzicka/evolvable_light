require 'dino'
require 'evolvable_light/version'
require 'evolvable_light/pressure_sensor'
require 'evolvable_light/arduino_uno'
require 'evolvable_light/light_gene'
require 'evolvable'
require 'byebug'

class EvolvableLight
  include Evolvable

  def self.evolvable_gene_pool
    [[LightGene, ArduinoUno.lights.count]]
  end

  def self.evolvable_genes_count
    ArduinoUno.lights.count
  end

  def self.evolvable_initialize(genes, population, object_index)
    evolvable_light = new
    evolvable_light.genes = genes
    evolvable_light.population = population
    evolvable_light.object_index = object_index
    evolvable_light
  end

  def self.evolvable_before_evaluation(population)
    open('./lib/evolvable_log.csv', 'a') do |f|
      population_log_attrs = "#{population.name}, #{population.generation_count}"
      log_lines = population.objects.map do |object|
        gene_log_attrs = object.genes.map(&:log_attrs).join(', ')
        "#{population_log_attrs}, #{object.on_at}, #{object.off_at}, " \
        "#{object.fitness}, #{gene_log_attrs}"
      end
      f << "#{log_lines.join("\n")}\n"
    end
  end

  attr_accessor :on_at,
                :off_at,
                :object_index

  def fitness
    @fitness ||= off_at - on_at
  end

  def turn_on
    kill_turn_on_threads
    Thread.new do
      Thread.current[:type] = :turn_on
      LightGene.assign_lights(ArduinoUno.lights, @genes)
      @genes.each do |light_gene|
        sleep light_gene.delay_time
        light_gene.update_light
      end
    end
  end

  OFF_DELAY = 0.05

  def turn_off
    kill_turn_on_threads
    genes.reverse_each do |light_gene|
      sleep OFF_DELAY if light_gene.on?
      light_gene.turn_off_light
    end
  end

  private

  def kill_turn_on_threads
    Thread.list.each { |t| t.kill if t[:type] == :turn_on }
  end
end
