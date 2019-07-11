require 'evolvable_light/version'
require 'evolvable_light/pressure_sensor'
require 'evolvable_light/light_gene'
require 'evolvable'
require 'dino'
require 'byebug'

# Add Dino::Components::Sensor#reset
module Dino
  module Components
    class Sensor < BaseComponent
      def reset
        @data_callbacks = []
        @value = 0
      end
    end
  end
end

class EvolvableLight
  include Evolvable

  BOARD = Dino::Board.new(Dino::TxRx::Serial.new)

  LIGHTS = [Dino::Components::Led.new(pin: 2, board: BOARD),
            Dino::Components::Led.new(pin: 3, board: BOARD),
            Dino::Components::Led.new(pin: 4, board: BOARD),
            Dino::Components::Led.new(pin: 5, board: BOARD),
            Dino::Components::Led.new(pin: 6, board: BOARD),
            Dino::Components::Led.new(pin: 7, board: BOARD)]

  def self.evolvable_gene_pool
    [[LightGene, LIGHTS.count]]
  end

  def self.evolvable_genes_count
    LIGHTS.count
  end

  def self.evolvable_before_evaluation(population)
    # TODO: log population info to file
    # puts "\n#{population.name} | Generation #{population.generation_count}"
    # population.objects.each do |object|
    # puts object.fitness
    # end
  end

  attr_accessor :on_at,
                :off_at

  def fitness
    @fitness ||= off_at - on_at
  end

  def turn_on
    kill_turn_on_threads
    Thread.new do
      Thread.current[:type] = :turn_on
      EvolvableLight::LightGene.assign_lights(LIGHTS, @genes)
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
