# rubocop:disable LineLength

Then(/^the number of packets sent from "(.*?)" should be:$/) do |host_name, table|
  command = "trema show_stats #{host_name}"
  step "I successfully run `#{command}`"

  result = {}
  in_current_dir do
    output_from(command).split("\n").each do |each|
      case each
      when /Packets sent/
        next
      when /Packets recevied/
        break
      when /-> (\S+) = (\d+) packet/
        result[Regexp.last_match(1)] = Regexp.last_match(2).to_i
      else
        fail "Failed to parse line '#{each}'"
      end
    end
  end
  table.hashes.each do |each|
    ip_address = each.fetch('destination')
    expect(result.fetch(ip_address)).to eq(each.fetch('#packets').to_i)
  end
end

Then(/^the number of packets received by "(.*?)" should be:$/) do |host_name, table|
  command = "trema show_stats #{host_name}"
  step "I successfully run `#{command}`"

  result = {}
  in_current_dir do
    received = false
    output_from(command).split("\n").each do |each|
      case each
      when /Packets sent/
        next
      when /Packets received/
        received = true
        next
      when /(\S+) -> (\S+) = (\d+) packet/
        next unless received
        result[Regexp.last_match(1)] = Regexp.last_match(3).to_i
      else
        fail "Failed to parse line '#{each}'"
      end
    end
  end
  table.hashes.each do |each|
    ip_address = each.fetch('source')
    expect(result.fetch(ip_address)).to eq(each.fetch('#packets').to_i)
  end
end

# rubocop:enable LineLength
