require "recurrence_detector/version"

class RecurrenceDetector
  ORDINALS = %w(first second third fourth fifth)
  WEEKDAYS = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  attr_reader :dates
  attr_accessor :recurrence

  def initialize dates
    raise ArgumentError, "dates must be Date class" unless dates.map{ |date| date.is_a? Date }.all?
    @dates = dates
  end

  def detect
    self.recurrence =
      detect_consecutive_years ||
      detect_consecutive_months ||
      detect_consecutive_weeks ||
      detect_consecutive_days ||
      detect_consecutive_weekdays ||
      detect_custom_months ||
      detect_custom_weeks ||
      detect_custom_days ||
      {}
  end

  def detect_consecutive_years
    detect_consecutive(:every_year) { |prev, date| prev == date << 12 }
  end

  def detect_consecutive_months
    detect_consecutive(:every_month) { |prev, date| prev == date << 1 }
  end

  def detect_consecutive_weeks
    detect_consecutive(:every_week) { |prev, date| prev == date - 7 }
  end

  def detect_consecutive_days
    detect_consecutive(:every_day) { |prev, date| prev == date - 1 }
  end

  def detect_consecutive_weekdays
    detect_consecutive(:every_weekday) { |prev, date|
      previous_weekday =  date.wday == 1 ? 5 : (date - 1).wday
      !([0, 6].include? date.wday) && prev&.wday == previous_weekday
    }
  end

  def detect_custom_months
    days_of_month = dates.sort.map &:day
    months_of_year = dates.sort.map &:month

    first_repeating_day = days_of_month.each_index.select{ |i| days_of_month[i] == days_of_month[0] }[1]

    if first_repeating_day
      pattern = days_of_month.each_slice(first_repeating_day).to_a
      pattern.pop if pattern[0].length != pattern[-1].length
    end

    pattern_repeats = pattern && pattern.count > 1 && !!pattern.reduce { |prev, month| month if prev == month }

    frequency = dates.sort.map.with_index do |date, i|
      next if i == 0
      prev = dates.sort[i - 1].month
      prev_month = prev == 12 && date.month == 1 ? 0 : prev
      (date.month - prev_month).to_i
    end.compact.delete_if &:zero?


    if pattern_repeats && frequency.uniq.count == 1
      {
        recurrence: :custom_months,
        every: frequency.first,
        each: pattern.first
      }
    end
  end

  def detect_custom_weeks
    days_of_week = dates.sort.map &:wday

    first_repeating_day = days_of_week.each_index.select{ |i| days_of_week[i] == days_of_week[0] }[1]
    return unless first_repeating_day

    pattern = days_of_week.each_slice(first_repeating_day).to_a
    pattern.pop if pattern[0].length != pattern[-1].length
    return unless pattern.count > 1

    pattern_repeats = !!pattern.reduce { |prev, week| week if prev == week }

    frequency = dates.sort.map.with_index do |date, i|
      next if i == 0
      prev = dates.sort[i - 1]
      ((date.jd / 7) - (prev.jd / 7)).to_i
    end.compact.delete_if &:zero?

    if pattern_repeats && frequency.uniq.count == 1
      {
        recurrence: :custom_weeks,
        every: frequency.first,
        on: pattern.first.map { |day| WEEKDAYS.key day }
      }
    end
  end

  def detect_custom_days
    frequency = dates.sort.map.with_index do |date, i|
      next if i == 0
      (date - dates.sort[i - 1]).to_i
    end.compact

    if frequency.uniq.count == 1
      {
        recurrence: :custom_days,
        every: frequency.first
      }
    end
  end

  def detect_consecutive period, &condition
    if dates.sort.reduce { |prev, date| date if condition.call prev, date }
      { recurrence: period }
    end
  end

  private

  def beginning_of_week day
    days_to_monday = day.wday != 0 ? day.wday - 1 : 6
    day - days_to_monday
  end
end
