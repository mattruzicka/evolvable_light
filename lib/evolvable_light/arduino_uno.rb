class EvolvableLight::ArduinoUno
  class << self
    def board
      @board ||= Dino::Board.new(Dino::TxRx::Serial.new)
    end

    def lights=(digital_pins)
      @lights = digital_pins.map do |pin|
        Dino::Components::Led.new(pin: pin, board: board)
      end
    end

    def lights
      @lights
    end

    def pressure_sensors=(analog_pins)
      sensors = analog_pins.map { |p| EvolvableLight::PressureSensor.new(p) }
      sensors.each do |sensor|
        sensor.sibling_sensors = sensors.select { |ps| ps != sensor }
      end
      @pressure_sensors = sensors
    end

    def pressure_sensors
      @pressure_sensors
    end

    def calibrate_pressure_thresholds
      pressure_sensors.each(&:calibrate_pressure_threshold)
    end

    def start
      pressure_sensors.each(&:start)
    end
  end
end
