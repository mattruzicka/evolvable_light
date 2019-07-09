class EvolvableLight::LightSetting
  def delay_time
    @rand_time ||= rand(0..0.3)
  end

  def position
    @position ||= rand
  end

  def on_or_off
    @on_or_off ||= [:on, :off].sample
  end
end
