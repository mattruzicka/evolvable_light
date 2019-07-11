class EvolvableLight::LightGene
  def self.assign_lights(lights, genes)
    genes.sort_by(&:position).each_with_index { |s, i| s.light = lights[i] }
  end

  attr_accessor :light

  def delay_time
    @delay_time ||= on? ? rand : 0
  end

  def position
    @position ||= rand
  end

  def update_light
    light.send(on_or_off) if light
  end

  def turn_off_light
    light.off
  end

  def on_or_off
    @on_or_off ||= [:on, :off].sample
  end

  def on?
    on_or_off == :on
  end

  # Test lights

  # def delay_time
  #   @delay_time ||= 0
  # end

  # def on_or_off
  #   @on_or_off ||= :on
  # end
end
