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
      @lights ||= []
    end

    def sound_files
      @sound_files
    end

    def sound_files=(sound_files)
      @sound_files = sound_files
    end

    def pressure_sensors=(analog_pins)
      sensors = analog_pins.map.with_index do |p, i|
        sound_file = sound_files[i] if sound_files
        EvolvableLight::PressureSensor.new(p, sound_file)
      end
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
