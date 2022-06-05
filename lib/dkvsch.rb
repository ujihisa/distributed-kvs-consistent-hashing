# frozen_string_literal: true

require 'digest/sha1'

module DKVSCH
  PORTS = %w[3000 3001 3002]

  # resolve('key31', %w[3000 3001 3002]) #=> '3001'
  # resolve('key31', %w[3000 3002]) #=> '3000'
  def self.resolve(key, available_ports)
    port_ranges = ranges(available_ports.map { hash128(_1) })
    belonging_index = port_ranges.find { _1.include?(hash128(key)) || _1.include?(hash128(key) + 128) }.begin
    port_map = port_ranges.map(&:first).zip(available_ports).to_h
    port_map[belonging_index]
  end

  def self.recover(self_port, available_ports)
    self_index = hash128(self_port)
  end

  # ranges([30, 80, 50]) #=> [30...50, 80...158(*), 50...80] where 150 = 30+128
  def self.ranges(indices)
    sorted_indices_loop = indices.sort + indices.sort.map { 128 + _1 }

    indices.map {|index|
      next_index = sorted_indices_loop.bsearch { _1 > index }
      index...next_index
    }
  end

  # ports_for_write('key31', %w[3000 3001 3002]) #=> %w[3001 3000]
  # ports_for_write('key31', %w[3000 3002]) #=> %w[3002 3000]
  def self.ports_for_write(key, available_ports)
    port1 = resolve(key, available_ports)
    port2 = resolve(key, available_ports - [port1])
    [port1, port2]
  end

  # port_for_replicate('3001', %w[3000 3002]) #=> '3000'
  def self.port_for_replicate(new_port, existing_ports)
    resolve(new_port, existing_ports)
  end

  private_class_method def self.hash128(str)
    Integer("0x#{Digest::SHA1.hexdigest(str)}") % 128
  end
end
