module OutputHelpers
  def silence_streams(*streams)
    unless ENV['SHOW_STDOUT'].to_i == 1
      begin
        on_hold = streams.collect { |stream| stream.dup }
        streams.each do |stream|
          stream.reopen('/dev/null')
          stream.sync = true
        end
        yield
      ensure
        streams.each_with_index do |stream, i|
          stream.reopen(on_hold[i])
        end
      end
    end
  end

  def format_error(expected_data, actual_result)
    expectation_count = (expected_data.rows.count rescue nil) || 0
    if expectation_count == 0
      table_headings = actual_result[0].keys
    else
      table_headings = expected_data.hashes[0].keys
    end
    print_data = Hash[table_headings.map { |key| [key, key.length] }]

    actual_result.each do |row|
      row.each do |key, value|
        print_data[key] = value.length if (value.to_s.length > print_data[key].to_i)
      end
    end

    error = '| ' + table_headings.map { |k| k.ljust(print_data[k], ' ') }.join(' | ') + " |\n"
    error << actual_result.map do |row|
      '| ' + table_headings.map { |k| (row[k] || '').ljust(print_data[k], ' ') }.join(' | ') + ' |'
    end.join("\n") + "\n"

    error
  end
end

World(OutputHelpers)
