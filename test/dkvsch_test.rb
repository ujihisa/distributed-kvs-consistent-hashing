require 'test/unit'
require './lib/dkvsch'

class DKVSCHyTest < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_resolve
    assert_equal('3002', DKVSCH.resolve('key1', %w[3000 3001 3002]))
    assert_equal('3002', DKVSCH.resolve('key2', %w[3000 3001 3002]))
    assert_equal('3000', DKVSCH.resolve('key3', %w[3000 3001 3002]))
    assert_equal('3002', DKVSCH.resolve('key4', %w[3000 3001 3002]))

    assert_equal('3001', DKVSCH.resolve('key31', %w[3000 3001 3002]))
    assert_equal('3000', DKVSCH.resolve('key31', %w[3000 3002]))
  end

  def test_ranges
    assert_equal(
      [30...50, 80...158, 50...80],
      DKVSCH.ranges([30, 80, 50]))
  end

  def test_ports_for_write
    assert_equal(
      %w[3001 3000],
      DKVSCH.ports_for_write('key31', %w[3000 3001 3002]))
  end

  def test_port_for_replicate
    assert_equal(
      '3000',
      DKVSCH.port_for_replicate('3001', %w[3000 3002]))
  end
end
