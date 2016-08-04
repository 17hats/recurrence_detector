require "recurrence_detector/version"

class ::Hash
  def deep_array_merge second
    merger = proc do |key, v1, v2|
      if Hash === v1 && Hash === v2
        v1.merge v2, &merger
      elsif v1.is_a?(Array) && v2.is_a?(Array)
        v1 + v2
      end
    end

    self.merge second, &merger
  end
end

class RecurrenceDetector
  ORDINALS = %i(first second third fourth fifth last)
  WEEKDAYS = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  MONTHS = {
    january: 1,
    february: 2,
    march: 3,
    april: 4,
    may: 5,
    june: 6,
    july: 7,
    august: 8,
    september: 9,
    october: 10,
    november: 11,
    december: 12,
  }


  attr_reader :dates
  attr_accessor :recurrence

  def initialize dates
    argument_error = "dates must be an array of Date classes"
    raise ArgumentError, argument_error unless dates.is_a? Array
    raise ArgumentError, argument_error unless dates.map{ |date| date.is_a? Date }.all?
    @dates = dates.sort
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

  private

  def detect_consecutive dates, &condition
    !!dates.reduce { |prev, date| date if condition.call prev, date }
  end

  def detect_consecutive_years
    if detect_consecutive(dates) { |prev, date| prev == date << 12 }
      { recurrence: :every_year, in: MONTHS.key(dates.first.month) }
    end
  end

  def detect_consecutive_months
    if detect_consecutive(dates) { |prev, date| prev == date << 1 }
      { recurrence: :every_month, on: dates.first.mday }
    end
  end

  def detect_consecutive_weeks
    if detect_consecutive(dates) { |prev, date| prev == date - 7 }
      { recurrence: :every_week, on: WEEKDAYS.key(dates.first.wday) }
    end
  end

  def detect_consecutive_days
    if detect_consecutive(dates) { |prev, date| prev == date - 1 }
      { recurrence: :every_day }
    end
  end

  def detect_consecutive_weekdays
    if detect_consecutive(dates) { |prev, date|
      previous_weekday =  date.wday == 1 ? 5 : (date - 1).wday
      !([0, 6].include? date.wday) && prev&.wday == previous_weekday
    }
      { recurrence: :every_weekday }
    end
  end

  def detect_custom_months
    days_of_month = dates.map &:day
    months_of_year = dates.map &:month

    first_repeating_day = days_of_month.each_index.select{ |i| days_of_month[i] == days_of_month[0] }[1]

    if first_repeating_day
      day_pattern = days_of_month.each_slice(first_repeating_day).to_a
      day_pattern.pop if day_pattern[0].length != day_pattern[-1].length
    end

    day_pattern_repeats = day_pattern && day_pattern.count > 1 && !!day_pattern.reduce { |prev, month| month if prev == month }

    frequency = dates.map.with_index do |date, i|
      next if i == 0
      prev = dates[i - 1].month
      prev_month = prev == 12 && date.month == 1 ? 0 : prev
      (date.month - prev_month).to_i
    end.compact.delete_if &:zero?

    days_mapped = monthly_recurrences_for dates.first.year..dates.last.year

    month_pattern = nil
    days_mapped.each do |(ordinal, weekdays)|
      weekdays.each do |(weekday, days)|
        month_pattern = [ordinal, weekday] if (dates - days).empty?
      end
    end

    if day_pattern_repeats && frequency.uniq.count == 1
      {
        recurrence: :custom_months,
        every: frequency.first,
        each: day_pattern.first
      }
    elsif month_pattern
      {
        recurrence: :custom_months,
        every: 1,
        on: month_pattern
      }
    end
  end

  def detect_custom_weeks
    days_of_week = dates.map &:wday

    first_repeating_day = days_of_week.each_index.select{ |i| days_of_week[i] == days_of_week[0] }[1]
    return unless first_repeating_day

    pattern = days_of_week.each_slice(first_repeating_day).to_a
    pattern.pop if pattern[0].length != pattern[-1].length
    return unless pattern.count > 1

    pattern_repeats = !!pattern.reduce { |prev, week| week if prev == week }

    frequency = dates.map.with_index do |date, i|
      next if i == 0
      prev = dates[i - 1]
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
    frequency = dates.map.with_index do |date, i|
      next if i == 0
      (date - dates[i - 1]).to_i
    end.compact

    if frequency.uniq.count == 1
      {
        recurrence: :custom_days,
        every: frequency.first
      }
    end
  end

  def monthly_recurrences_for years
    ORDINALS.map { |ordinal| { ordinal => years_map(years, ORDINALS.index(ordinal)) } }.reduce Hash.new, :merge
  end

  def years_map years, ordinal
    years.map { |year| weekdays_map year, ordinal }.reduce Hash.new, :deep_array_merge
  end

  def weekdays_map year, ordinal
    WEEKDAYS.map { |weekday_name, weekday| [weekday_name, months_map(year, ordinal, weekday)] }.to_h
  end

  def months_map year, ordinal, day_of_week, months=1..12
    months.map do |month|
      date = if ordinal == 5
        last_day_of_month day_of_week, year, month
      else
        ordinal_day_of_month ordinal, day_of_week, year, month
      end
      date if date.month == month #TODO: Is this even needed?
    end.compact
  end

  def last_day_of_month day_of_week, year, month
    date = Date.new year, month, -1
    offset = date.wday - day_of_week
    date -= offset % 7
  end

  def ordinal_day_of_month ordinal, day_of_week, year, month
    date = Date.new year, month, 1
    offset = day_of_week - date.wday
    date += offset % 7
    date += 7 * ordinal
  end
end
