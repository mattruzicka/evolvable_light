class EvolvableLight::PressureSensor
  def initialize(pin, pressure_threshold = 170)
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
    most_recent_on_sensor = sibling_sensors.select(&:on_at).max_by(&:on_at)
    if most_recent_on_sensor
      most_recent_on_sensor.evolvable_light.turn_on
      @evolvable_light.off_at = Time.now.utc
    else
      @evolvable_light.turn_off
    end
    self.on_at = nil
    light_population.evolve! if @object_index == population_size - 1
  end

  def listen
    dino_sensor.when_data_received do |pressure|
      pressure = pressure.to_i
      if on_at.nil? && pressure >= pressure_threshold
        above_threshold_callback
      elsif on_at && pressure < pressure_threshold
        below_threshold_callback
      end
    end
  end

  private

  def init_evolvable_light_population
    EvolvableLight.evolvable_population(size: 5,
                                        mutation: Evolvable::Mutation.new(rate: 0.2))
  end
end
