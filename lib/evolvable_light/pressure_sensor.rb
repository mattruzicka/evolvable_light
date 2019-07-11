class EvolvableLight::PressureSensor
  def initialize(pin, pressure_threshold = 195)
    @pin = pin
    @dino_sensor = Dino::Components::Sensor.new(pin: pin, board: EvolvableLight::BOARD)
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
    @object_index = @passed_threshold_count % population_size
    @evolvable_light = light_population.objects[@object_index]
    @evolvable_light.turn_on
    self.on_at = Time.now.utc
    @passed_threshold_count += 1
  end

  def below_threshold_callback
    puts "Below #{pin}"
    max_on_sibling = sibling_sensors.select(&:on_at).max_by(&:on_at)
    if max_on_sibling
      max_on_sibling.evolvable_light.turn_on if max_on_sibling.on_at <= on_at
      @evolvable_light.off_at = Time.now.utc
    else
      @evolvable_light.turn_off
    end
    self.on_at = nil
    light_population.evolve! if @object_index == population_size - 1
  end

  def start
    dino_sensor.when_data_received do |pressure|
      puts "#{pin} #{pressure}"
      pressure = pressure.to_i
      if on_at.nil? && pressure >= pressure_threshold
        above_threshold_callback
      elsif on_at && pressure < pressure_threshold
        below_threshold_callback
      end
    end
  end

  CALIBRATION_BUFFER = 45

  def calibrate_pressure_threshold(seconds = 5)
    puts "Calibrating #{pin}..."
    calibration_readings = []
    dino_sensor.when_data_received do |pressure|
      calibration_readings << pressure.to_i
    end
    sleep(seconds)
    @dino_sensor.reset
    median = find_median(calibration_readings)
    max = calibration_readings.max
    self.pressure_threshold = ((median + max) / 2) + CALIBRATION_BUFFER
    puts "Median: #{median}, Max: #{max}, Threshold: #{pressure_threshold}"
  end

  def find_median(array)
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  private

  def init_evolvable_light_population
    EvolvableLight.evolvable_population(name: @pin,
                                        size: 5,
                                        mutation: Evolvable::Mutation.new(rate: 0.2))
  end
end