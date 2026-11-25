
class BowlingGame
  class InvalidGameError < StandardError; end

  PINS = 10
  FRAMES = 10

  def self.from_text(text)
    raise InvalidGameError, "input must be a string" unless text.is_a?(String)

    frames = text.lines.map(&:strip).reject(&:empty?).map do |line|
      line.split.map { |token| parse_roll(token) }
    end

    new(frames)
  end

  def self.parse_roll(token)
    Integer(token, 10)
  rescue ArgumentError
    raise InvalidGameError, "invalid roll #{token.inspect}: expected a whole number"
  end
  private_class_method :parse_roll

  def initialize(frames)
    @frames = frames
    validate!
  end

  def score
    rolls = @frames.flatten
    roll_index = 0
    total = 0

    @frames.each_with_index do |frame, index|
      following_rolls = rolls.drop(roll_index + frame.size)
      total += frame.sum + bonus_for(frame, index, following_rolls)
      roll_index += frame.size
    end

    total
  end

  private

  def bonus_for(frame, index, following_rolls)
    return 0 if last_frame?(index)

    if strike?(frame)
      following_rolls.first(2).sum
    elsif spare?(frame)
      following_rolls.first(1).sum
    else
      0
    end
  end

  def strike?(frame)
    frame.first == PINS
  end

  def spare?(frame)
    !strike?(frame) && frame.first(2).sum == PINS
  end

  def last_frame?(index)
    index == FRAMES - 1
  end

  def validate!
    raise InvalidGameError, "frames must be an array" unless @frames.is_a?(Array)
    raise InvalidGameError, "a game has at most #{FRAMES} frames, got #{@frames.size}" if @frames.size > FRAMES

    @frames.each_with_index do |frame, index|
      validate_rolls!(frame, index)

      if last_frame?(index)
        validate_last_frame!(frame, index)
      else
        validate_regular_frame!(frame, index)
      end
    end
  end

  def validate_rolls!(frame, index)
    unless frame.is_a?(Array) && !frame.empty?
      raise InvalidGameError, "frame #{index + 1} must be a non-empty list of rolls"
    end

    frame.each do |roll|
      unless roll.is_a?(Integer) && roll.between?(0, PINS)
        raise InvalidGameError, "frame #{index + 1} has an invalid roll #{roll.inspect}: must be 0 to #{PINS}"
      end
    end
  end

  def validate_regular_frame!(frame, index)
    if strike?(frame)
      raise InvalidGameError, "frame #{index + 1} is a strike and must have only one roll" unless frame.size == 1
    else
      raise InvalidGameError, "frame #{index + 1} must have two rolls" unless frame.size == 2
      raise InvalidGameError, "frame #{index + 1} knocks down more than #{PINS} pins" if frame.sum > PINS
    end
  end

  def validate_last_frame!(frame, index)
    first, second, third = frame
    earns_bonus_roll = strike?(frame) || spare?(frame)
    expected_size = earns_bonus_roll ? 3 : 2

    unless frame.size == expected_size
      raise InvalidGameError, "frame #{index + 1} must have #{expected_size} rolls, got #{frame.size}"
    end

    if first < PINS && first + second > PINS
      raise InvalidGameError, "frame #{index + 1} knocks down more than #{PINS} pins"
    end

    if first == PINS && second < PINS && second + third > PINS
      raise InvalidGameError, "frame #{index + 1} knocks down more than #{PINS} pins with its bonus rolls"
    end
  end
end
