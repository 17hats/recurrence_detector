require 'test_helper'

# TODO: Months: ordinal/last weekday
# TODO: Months: ordinal/last weekend
# TODO: Months: ordinal/last days repeating every 2, 3, 4, etc months
# TODO: Custom Years: Every three years in Aug and Sept on the third weekend

class RecurrenceDetectorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RecurrenceDetector::VERSION
  end

  def test_detects_days
    dates = [
      Date.new(2001, 2, 1),
      Date.new(2001, 2, 2),
      Date.new(2001, 1, 30),
      Date.new(2001, 1, 31),
      Date.new(2001, 2, 3),
      Date.new(2001, 2, 4),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 6)
    ]

    expected_recurrence = { recurrence: :every_day }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_days
    dates = [
      Date.new(2001, 2, 1),
      Date.new(2001, 2, 2),
      Date.new(2001, 1, 30),
      Date.new(2001, 1, 31),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 6),
      Date.new(2001, 2, 8)
    ]

    expected_recurrence = {}
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_days
    dates = [
      Date.new(2001, 1, 27),
      Date.new(2001, 1, 30),
      Date.new(2001, 2, 2),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 8)
    ]

    expected_recurrence = { recurrence: :custom_days, every: 3 }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_custom_days
    dates = [
      Date.new(2001, 1, 27),
      Date.new(2001, 1, 30),
      Date.new(2001, 2, 2),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 9)
    ]

    expected_recurrence = {}
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_two_weeks_on_monday
    dates = [
      Date.new(2001, 1, 29),
      Date.new(2001, 2, 12),
      Date.new(2001, 2, 26),
      Date.new(2001, 3, 12),
      Date.new(2001, 3, 26),
    ]

    expected_recurrence = { recurrence: :custom_weeks, every: 2, on: [:monday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_weeks_on_mon_wed_fri
    dates = [
      Date.new(2001, 1, 29), # Monday
      Date.new(2001, 1, 31), # Wednesday
      Date.new(2001, 2, 2),  # Friday
      Date.new(2001, 2, 5),  # Monday
      Date.new(2001, 2, 7),  # Wednesday
      Date.new(2001, 2, 9),  # Friday
      Date.new(2001, 2, 12)  # Monday
    ]

    expected_recurrence = { recurrence: :custom_weeks, every: 1, on: %i[monday wednesday friday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_weeks_two_weeks_on_mon_wed_fri
    dates = [
      Date.new(2001, 1, 29), # Monday
      Date.new(2001, 1, 31), # Wednesday
      Date.new(2001, 2, 2),  # Friday
      Date.new(2001, 2, 12), # Monday (Skips a week)
      Date.new(2001, 2, 14), # Wednesday
      Date.new(2001, 2, 16), # Friday
      Date.new(2001, 2, 26), # Monday (Skips a week)
      Date.new(2001, 2, 28), # Wednesday
      Date.new(2001, 3, 2)   # Friday
    ]

    expected_recurrence = { recurrence: :custom_weeks, every: 2, on: %i[monday wednesday friday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_weeks_on_tues_wed
    dates = [
      Date.new(2001, 1, 30),
      Date.new(2001, 1, 31),
      Date.new(2001, 2, 6),
      Date.new(2001, 2, 7),
      Date.new(2001, 2, 13),
      Date.new(2001, 2, 14)
    ]

    expected_recurrence = { recurrence: :custom_weeks, every: 1, on: %i[tuesday wednesday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_custom_weeks
    dates = [
      Date.new(2001, 1, 27),
      Date.new(2001, 1, 30),
      Date.new(2001, 2, 2),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 9)
    ]

    expected_recurrence = {}
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_months
    dates = [
      Date.new(2000, 12, 12),
      Date.new(2000, 12, 10),
      Date.new(2001, 1, 10),
      Date.new(2001, 1, 12),
      Date.new(2001, 2, 10),
      Date.new(2001, 2, 12),
      Date.new(2001, 3, 10),
      Date.new(2001, 3, 12)
    ]

    expected_recurrence = { recurrence: :custom_months, every: 1, each: [10, 12] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_two_months
    dates = [
      Date.new(2001, 1, 10),
      Date.new(2001, 1, 12),
      Date.new(2001, 3, 10),
      Date.new(2001, 3, 12),
      Date.new(2001, 5, 10),
      Date.new(2001, 5, 12)
    ]

    expected_recurrence = { recurrence: :custom_months, every: 2, each: [10, 12] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_months_first_weekday
    skip
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2001, 2, 1),
      Date.new(2001, 3, 1),
      Date.new(2001, 4, 2)
    ]

    expected_recurrence = { recurrence: :custom_months, every: 1, on: [:first, :weekday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_months_last_tuesday
    dates = [
      Date.new(2001, 1, 30),
      Date.new(2001, 2, 27),
      Date.new(2001, 3, 27),
      Date.new(2001, 4, 24),
      Date.new(2001, 5, 29)
    ]

    expected_recurrence = { recurrence: :custom_months, every: 1, on: [:last, :tuesday] }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_custom_years
    skip
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2001, 2, 1),
      Date.new(2001, 3, 1),
      Date.new(2001, 4, 2)
    ]

    expected_recurrence = { recurrence: :custom_months, every: :first, on: :weekday }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_weekdays
    dates = [
      Date.new(2001, 2, 1),
      Date.new(2001, 2, 2),
      Date.new(2001, 1, 30),
      Date.new(2001, 1, 31),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 6)
    ]

    expected_recurrence = { recurrence: :every_weekday }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_weekdays
    dates = [
      Date.new(2001, 2, 1),
      Date.new(2001, 2, 2),
      Date.new(2001, 1, 30),
      Date.new(2001, 1, 31),
      Date.new(2001, 2, 4),
      Date.new(2001, 2, 5),
      Date.new(2001, 2, 6)
    ]

    expected_recurrence = {}
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_weekly
    dates = [
      Date.new(2001, 1, 8),
      Date.new(2001, 1, 15),
      Date.new(2001, 1, 22),
      Date.new(2001, 1, 29),
      Date.new(2001, 2, 5)
    ]

    expected_recurrence = { recurrence: :every_week, on: :monday }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_weekly
    dates = [
      Date.new(2001, 1, 8),
      Date.new(2001, 1, 15),
      Date.new(2001, 1, 22),
      Date.new(2001, 1, 29),
      Date.new(2001, 2, 6)
    ]

    expected_recurrence = { }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_monthly
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2001, 2, 1),
      Date.new(2001, 4, 1),
      Date.new(2001, 3, 1)
    ]

    expected_recurrence = { recurrence: :every_month, on: 1 }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_monthly
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2001, 2, 2),
      Date.new(2001, 4, 1),
      Date.new(2001, 3, 1)
    ]

    expected_recurrence = { }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_detects_yearly
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2002, 1, 1),
      Date.new(2003, 1, 1),
      Date.new(2004, 1, 1)
    ]

    expected_recurrence = { recurrence: :every_year, in: :january }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_rejects_yearly
    dates = [
      Date.new(2001, 1, 1),
      Date.new(2002, 2, 1),
      Date.new(2003, 1, 1),
      Date.new(2005, 1, 1)
    ]

    expected_recurrence = { }
    recurrence = RecurrenceDetector.new(dates).detect

    assert_equal expected_recurrence, recurrence
  end

  def test_raises_if_array_not_dates
    assert_raises ArgumentError do
      RecurrenceDetector.new [
        Date.new(2001, 1, 1),
        Time.now,
        Date.new(2001, 1, 2)
      ]
    end

    RecurrenceDetector.new [
      Date.new(2001, 1, 1),
      Date.new(2001, 1, 2),
      Date.new(2001, 1, 3)
    ]
  end
end
