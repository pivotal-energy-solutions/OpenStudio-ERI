# frozen_string_literal: true

require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative 'util.rb'

class VentTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_mech_vent_none
    hpxml_name = 'base.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.tested_flow_rate = 1.0
    vent_fan.hours_in_operation = 1
    vent_fan.fan_power = 1.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 34.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 99.6, 24, 99.6) # Increased runtime and fan power

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 26.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 75.4, 24, 75.4) # Increased runtime and fan power

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.tested_flow_rate = nil
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 0.1)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 0.1, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 13.0)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_IR_301_2019_001
    # Test IR 301-2019-001: Fan Energy for Unmeasured Mechanical Ventilation
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.tested_flow_rate = nil
    vent_fan.hours_in_operation = 8
    hpxml.building_construction.conditioned_floor_area = 2750 # Update CFA/Volume to trigger IR
    hpxml.building_construction.conditioned_building_volume = 8.0 * hpxml.building_construction.conditioned_floor_area
    hpxml.air_infiltration_measurements[0].infiltration_volume = 8.0 * hpxml.building_construction.conditioned_floor_area
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 0.0)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 0.0, 24, 0.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)
  end

  def test_mech_vent_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.hours_in_operation = 8
    vent_fan.tested_flow_rate = 10.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 34.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 99.6, 24, 34.8)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 26.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 75.4, 24, 26.4)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.tested_flow_rate = nil
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 0.1)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 0.1, 24, 0.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 13.0)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 12.95)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_and_defaulted_fan_power_cfis
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    vent_fan = hpxml.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation }[0]
    vent_fan.fan_power = nil
    vent_fan.tested_flow_rate = nil
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 47.2, 24, 0.1)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeCFIS, 0.1, 24, 800.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)
  end

  def test_mech_vent_attached_or_multifamily
    hpxml_name = 'base-enclosure-other-housing-unit.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 68.2, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 96.3, 24, 67.4)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 32.1, 24, 55.0)

    # Test w/ 301-2014
    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 70.5, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 102.0, 24, 71.4)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 102.0, 24, 71.4)

    # FIXME: Add tests for new 301-2019 space types HPXML file
  end

  def test_mech_vent_exhaust
    hpxml_name = 'base-mechvent-exhaust.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 47.2, 24, 34.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 110.0, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 26.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 110.0, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_supply
    hpxml_name = 'base-mechvent-supply.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 47.2, 24, 34.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 110.0, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 37.0, 24, 26.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 110.0, 24, 30.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_balanced
    hpxml_name = 'base-mechvent-balanced.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 26.8, 24, 52.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 110.0, 24, 60.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 37.0, 24, 52.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 110.0, 24, 60.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_erv
    hpxml_name = 'base-mechvent-erv.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 26.8, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeERV, 110.0, 24, 60.0, 0.72, 0.48)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 37.0, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeERV, 110.0, 24, 60.0, 0.72, 0.48)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_erv_adjusted
    hpxml_name = 'base-mechvent-erv-atre-asre.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 26.8, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeERV, 110.0, 24, 60.0, nil, nil, 0.79, 0.526)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 37.0, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeERV, 110.0, 24, 60.0, nil, nil, 0.79, 0.526)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_hrv
    hpxml_name = 'base-mechvent-hrv.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 26.8, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeHRV, 110.0, 24, 60.0, 0.72)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 37.0, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeHRV, 110.0, 24, 60.0, 0.72)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_hrv_adjusted
    hpxml_name = 'base-mechvent-hrv-asre.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 26.8, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeHRV, 110.0, 24, 60.0, nil, nil, 0.79, nil)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 37.0, 24, 75.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeHRV, 110.0, 24, 60.0, nil, nil, 0.79, nil)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_cfis
    hpxml_name = 'base-mechvent-cfis.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 47.2, 24, 34.8)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeCFIS, 330.0, 8, 300.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 8.5, 24, 42.0)

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeSupply, 37.0, 24, 26.4)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeCFIS, 330.0, 8, 300.0)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_mech_vent_cfm50_infiltration
    # Create derivative file for testing
    hpxml_name = _change_eri_version('base-enclosure-infil-cfm50.xml', '2014')

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeExhaust, 37.0, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 60.0, 24, 42.0)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml, HPXML::MechVentTypeBalanced, 34.0, 24, 42.0)
  end

  def test_whole_house_fan
    hpxml_name = 'base-misc-whole-house-fan.xml'

    # Reference Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_whf(hpxml)

    # Rated Home
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_whf(hpxml, 4500, 300)

    # IAD
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_whf(hpxml)

    # IAD Reference
    hpxml = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_whf(hpxml)
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['calc_type'] = calc_type

    # create an instance of the measure
    measure = EnergyRatingIndex301Measure.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    return measure.new_hpxml
  end

  def _check_mech_vent(hpxml, fantype = nil, flowrate = nil, hours = nil, power = nil, sre = nil, tre = nil, asre = nil, atre = nil)
    num_mech_vent = 0
    hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_whole_building_ventilation

      num_mech_vent += 1
      assert_equal(fantype, ventilation_fan.fan_type)
      assert_in_delta(flowrate, ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_equal(hours, ventilation_fan.hours_in_operation)
      assert_in_delta(power, ventilation_fan.fan_power, 0.1)
      if sre.nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency)
      else
        assert_equal(sre, ventilation_fan.sensible_recovery_efficiency)
      end
      if tre.nil?
        assert_nil(ventilation_fan.total_recovery_efficiency)
      else
        assert_equal(tre, ventilation_fan.total_recovery_efficiency)
      end
      if asre.nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency_adjusted)
      else
        assert_equal(asre, ventilation_fan.sensible_recovery_efficiency_adjusted)
      end
      if atre.nil?
        assert_nil(ventilation_fan.total_recovery_efficiency_adjusted)
      else
        assert_equal(atre, ventilation_fan.total_recovery_efficiency_adjusted)
      end
    end
    if fantype.nil?
      assert_equal(0, num_mech_vent)
    else
      assert_equal(1, num_mech_vent)
    end
  end

  def _check_whf(hpxml, flowrate = nil, power = nil)
    num_whf = 0
    hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_seasonal_cooling_load_reduction

      num_whf += 1
      assert_in_epsilon(flowrate, ventilation_fan.rated_flow_rate, 0.01)
      assert_in_epsilon(power, ventilation_fan.fan_power, 0.01)
    end
    if flowrate.nil?
      assert_equal(0, num_whf)
    else
      assert_equal(1, num_whf)
    end
  end
end
