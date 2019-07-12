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

class EvolvableLight::PressureSensor
  def initialize(pin, sound_file = nil, pressure_threshold = 195)
    @pin = pin
    @sound_file = sound_file
    board = EvolvableLight::ArduinoUno.board
    @dino_sensor = Dino::Components::Sensor.new(pin: pin, board: board)
    @passed_threshold_count = 0
    @pressure_threshold = pressure_threshold
  end

  attr_accessor :sibling_sensors,
                :on_at,
                :pressure_threshold

  attr_reader :evolvable_light,
              :pin,
              :dino_sensor

  def light_population
    @light_population ||= init_evolvable_light_population
  end

  def population_size
    @population_size ||= light_population.size
  end

  def above_threshold_callback
    puts "Above #{pin}"
    play_sound_file
    @object_index = @passed_threshold_count % population_size
    @evolvable_light = light_population.objects[@object_index]
    @evolvable_light.turn_on
    @evolvable_light.on_at = Time.now.utc
    self.on_at = Time.now.utc
    @passed_threshold_count += 1
  end

  def below_threshold_callback
    puts "Below #{pin}"
    max_on_sibling = sibling_sensors.select(&:on_at).max_by(&:on_at)
    if max_on_sibling
      max_on_sibling.evolvable_light.turn_on if max_on_sibling.on_at <= on_at
    else
      @evolvable_light.turn_off
    end
    @evolvable_light.off_at = Time.now.utc
    self.on_at = nil
    light_population.evolve! if @object_index == population_size - 1
  end

  def start
    dino_sensor.when_data_received do |pressure|
      pressure = pressure.to_i
      # puts "#{pin} #{pressure}" if pin == 'A2'
      if on_at.nil? && pressure >= pressure_threshold
        above_threshold_callback
      elsif on_at && pressure < pressure_threshold
        below_threshold_callback
      end
    end
  end

  INTERFERENCE_BUFFER = 75

  def calibrate_pressure_threshold(seconds = 1)
    puts "Calibrating #{pin}..."
    calibration_readings = []
    dino_sensor.when_data_received do |pressure|
      calibration_readings << pressure.to_i
    end
    sleep(seconds)
    @dino_sensor.reset
    median = find_median(calibration_readings)
    max = calibration_readings.max
    self.pressure_threshold = ((median + max) / 2) + INTERFERENCE_BUFFER
    puts "Median: #{median}, Max: #{max}, Threshold: #{pressure_threshold}"
  end

  def find_median(array)
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def play_sound_file
    return unless @sound_file

    Thread.new do
      if RUBY_PLATFORM == 'x86_64-darwin18'
        system("afplay #{@sound_file}")
      else
        system("omxplayer --no-keys -o local #{@sound_file} &")
      end
    end
  end

  private

  def init_evolvable_light_population
    EvolvableLight.evolvable_population(name: @pin,
                                        size: 5,
                                        mutation: Evolvable::Mutation.new(rate: 0.2))
  end
end
