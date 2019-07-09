require 'evolvable_light/version'
require 'evolvable_light/pressure_sensor'
require 'evolvable_light/light_setting'
require 'evolvable'
require 'dino'
require 'byebug'

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
    [[LightSetting, LIGHTS.count]]
  end

  def self.evolvable_genes_count
    LIGHTS.count
  end

  def self.evolvable_before_evaluation(population)
    puts "\n Population #{population.generation_count}"
    population.objects.each do |object|
      puts object.genes.map(&:on_or_off).inspect
      puts object.on_at
      puts object.off_at
      puts object.fitness
    end
  end

  attr_accessor :on_at,
                :off_at

  def fitness
    @fitness ||= off_at - on_at
  end

  def turn_on
    self.on_at = Time.now.utc

    @genes.sort_by(&:position).each_with_index do |light_setting_gene, index|
      sleep light_setting_gene.delay_time
      LIGHTS[index].send(light_setting_gene.on_or_off)
    end
  end

  def turn_off
    self.off_at = Time.now.utc
    LIGHTS.each(&:off)
  end
end
