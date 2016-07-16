module MatcherHelpers
  def values_match(actual, expected)
    if expected.eql?('today')
      actual.match(/#{Regexp.quote(Date.today.to_s)}/)
    elsif expected.eql?('yesterday')
      actual.match(/#{Regexp.quote((Date.today - 1).to_s)}/)
    elsif expected.eql?('any_date')
      actual.match(/^\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}$/)
    elsif expected.eql?('any_string')
      true if actual.is_a?(String) or actual.nil?
    elsif expected.eql?('false') or expected.eql?('true')
      true if actual.eql?(expected[0])
    elsif !expected.nil?
      actual ||= ''
      actual.eql?(expected)
    else  # we have not mocked this, so ignore it
      true
    end
  end

  def timetravel(date, i, method); i > 0 ? timetravel(date.send(method.to_sym), i - 1, method) : date; end

  def convert_mock_values(mock_data)
    mock_data.map do |entry|
      entry.each do |key, value|
        entry[key] = case value
          when /today/
            Date.today.to_s
          when /yesterday/
            Date.today.prev_day.to_s
          when /\s*\d+\s+month(s)?\s+ago\s*/
            number_of_months = value.match(/\d+/)[0].to_i
            timetravel(Date.today, number_of_months, :prev_month).to_s
          when /\s*\d+\s+day(s)?\s+ago\s*/
            number_of_days = value.match(/\d+/)[0].to_i
            timetravel(Date.today, number_of_days, :prev_day).to_s
          else
            value
        end
      end
    end
  end
end

World(MatcherHelpers)
