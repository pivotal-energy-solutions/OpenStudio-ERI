# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERIMechVentTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.xml'))
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@results_path) if Dir.exist? @results_path
  end

  def test_mech_vent_none
    hpxml_name = 'base.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 0.3, hours: 24, power: 0.2 }]) # Supplemental balanced ventilation to meet total airflow requirement
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_none_attached_housing
    hpxml_name = 'base-bldgtype-mf-unit.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 20.1, hours: 24, power: 14.1 }]) # Supplemental balanced ventilation to meet total airflow requirement
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 57.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 102.0, hours: 24, power: 71.4 }])
      end
    end
  end

  def test_mech_vent_exhaust
    hpxml_name = 'base-mechvent-exhaust.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.hours_in_operation = 12
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 22.2, power: 30.0 }]) # Increased fan power
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 21.7, power: 30.0 }]) # Increased fan power
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 110.0, hours: 16.5, power: 30.0 }]) # Increased fan power
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.hours_in_operation = 12
    vent_fan.tested_flow_rate = 10.0
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 101.8, hours: 24, power: 35.6 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 99.6, hours: 24, power: 34.9 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 24
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 2.0 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.2 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_exhaust_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 24
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 2.0 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 5.3 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.2 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 15.0, hours: 24, power: 5.3 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_supply
    hpxml_name = 'base-mechvent-supply.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 110.0, hours: 24, power: 30.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_balanced
    hpxml_name = 'base-mechvent-balanced.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 52.8 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 52.8 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 110.0, hours: 24, power: 60.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_erv
    hpxml_name = 'base-mechvent-erv.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72, tre: 0.48 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72, tre: 0.48 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_erv_adjusted
    hpxml_name = 'base-mechvent-erv-atre-asre.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79, atre: 0.526 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeERV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79, atre: 0.526 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_hrv
    hpxml_name = 'base-mechvent-hrv.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, sre: 0.72 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_hrv_adjusted
    hpxml_name = 'base-mechvent-hrv-asre.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 75.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeHRV, flowrate: 110.0, hours: 24, power: 60.0, asre: 0.79 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_cfis
    hpxml_names = ['base-mechvent-cfis.xml',
                   'base-mechvent-cfis-supplemental-fan-exhaust.xml',
                   'base-mechvent-cfis-no-additional-runtime.xml',
                   'base-mechvent-cfis-no-outdoor-air-control.xml']

    hpxml_names.each do |hpxml_name|
      cfis_suppl_flowrate = nil
      cfis_suppl_power = nil
      cfis_is_dumvs = true
      if hpxml_name == 'base-mechvent-cfis.xml'
        cfis_mode = HPXML::CFISModeAirHandler
      elsif hpxml_name == 'base-mechvent-cfis-no-outdoor-air-control.xml'
        cfis_mode = HPXML::CFISModeAirHandler
        cfis_is_dumvs = false
      elsif hpxml_name == 'base-mechvent-cfis-supplemental-fan-exhaust.xml'
        cfis_mode = HPXML::CFISModeSupplementalFan
        cfis_suppl_flowrate = 120.0
        cfis_suppl_power = 30.0
      elsif hpxml_name == 'base-mechvent-cfis-no-additional-runtime.xml'
        cfis_mode = HPXML::CFISModeNone
        cfis_is_dumvs = false
      end

      _all_calc_types.each do |calc_type|
        _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
        if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
          if not cfis_is_dumvs
            # CFIS doesn't qualify as a Dwelling Unit Mechanical Ventilation System, so rated home gets 0.3 nACH and
            # ventilation requirement is lower, resulting in lower Reference Home fan power
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 2.1 }])
          else
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 35.6 }])
          end
        elsif [Constants::CalcTypeERIRatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power }])
        elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
        end
      end

      hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

      _all_calc_types.each do |calc_type|
        _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
        if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
          if not cfis_is_dumvs
            # CFIS doesn't qualify as a Dwelling Unit Mechanical Ventilation System, so rated home gets 0.3 nACH and
            # ventilation requirement is lower, resulting in lower Reference Home fan power
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 0.2 }])
          else
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 27.0, hours: 24, power: 34.9 }])
          end
        elsif [Constants::CalcTypeERIRatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power }])
        elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 42.0 }])
        end
      end

      hpxml_name = _change_eri_version(hpxml_name, '2014')

      _all_calc_types.each do |calc_type|
        _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
        if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
          if not cfis_is_dumvs
            # CFIS doesn't qualify as a Dwelling Unit Mechanical Ventilation System, so rated home gets 0.3 nACH and
            # ventilation requirement is lower, resulting in lower Reference Home fan power
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 13.0 }])
          else
            _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
          end
        elsif [Constants::CalcTypeERIRatedHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8, cfis_mode: cfis_mode,
                                          cfis_suppl_flowrate: cfis_suppl_flowrate, cfis_suppl_power: cfis_suppl_power }])
        elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
        elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
          _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
        end
      end
    end
  end

  def test_mech_vent_cfis_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation }
    vent_fan.tested_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    vent_fan.hours_in_operation = 8
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    calc_type = Constants::CalcTypeERIRatedHome
    _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
    _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 45.0, hours: 8, cfis_mode: HPXML::CFISModeAirHandler }])

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis-supplemental-fan-exhaust.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan_suppl = hpxml_bldg.ventilation_fans.find { |vf| vf.is_cfis_supplemental_fan }
    vent_fan_suppl.fan_power = nil
    vent_fan_suppl.fan_power_defaulted = true
    vent_fan_suppl.tested_flow_rate = nil
    vent_fan_suppl.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    calc_type = Constants::CalcTypeERIRatedHome
    _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
    _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeCFIS, flowrate: 330.0, hours: 8,
                                    cfis_mode: HPXML::CFISModeSupplementalFan, cfis_suppl_flowrate: 110.0, cfis_suppl_power: 38.5 }])
  end

  def test_mech_vent_cfm50_infiltration
    # Create derivative file for testing
    hpxml_name = _change_eri_version('base-enclosure-infil-cfm50.xml', '2014')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 0.0 }]) # Should have airflow but not fan energy
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg)
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end
  end

  def test_mech_vent_multiple
    calc_types = [Constants::CalcTypeERIRatedHome,
                  Constants::CalcTypeERIReferenceHome]

    # 1. Supply (measured) + Exhaust (measured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 50.0, hours: 18.1, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 37.7 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.0, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 34.0, hours: 24, power: 42.0 }])
      end
    end

    # 2. Exhaust (measured) + Supply (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 75.4, hours: 24, power: 37.7 },
                                      { fantype: HPXML::MechVentTypeSupply, flowrate: 30.0, hours: 12, power: 25.0 }])
      end
    end

    # 3. Exhaust (measured) + Exhaust (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 26.4 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 50.0, hours: 24, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 50.9, hours: 12, power: 25.0 }])
      end
    end

    # 4. Exhaust (measured) + Balanced (measured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: 25,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 39.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeExhaust, flowrate: 50.0, hours: 18.1, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeBalanced, flowrate: 37.7, hours: 24, power: 37.7 }])
      end
    end

    # 5. Supply (measured) + Exhaust (measured) + Balanced (measured) + Supply (unmeasured) + Exhaust (unmeasured) + Balanced (unmeasured)
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: 45,
                                    hours_in_operation: 8,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 50,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation3',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: 20,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation4',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 8,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation5',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation6',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 36.5 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 50.0, hours: 12, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeBalanced, flowrate: 20.0, hours: 24, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 30.0, hours: 12, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeBalanced, flowrate: 23.7, hours: 24, power: 25.0 }])
      end
    end

    # 6. Supply (measured) + Exhaust (measured) + Balanced (measured) + Supply (unmeasured) + Exhaust (unmeasured) + Balanced (unmeasured)
    #    where total flow rate > minimum requirement
    # Create derivative file for testing
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: 45,
                                    hours_in_operation: 8,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation2',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 200,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation3',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: 20,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation4',
                                    fan_type: HPXML::MechVentTypeSupply,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 8,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation5',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 12,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation6',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: nil,
                                    flow_rate_not_tested: true,
                                    hours_in_operation: 24,
                                    fan_power: 25,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    hpxml_name = _change_eri_version(hpxml_name, '2014') # Avoid min nACH for unmeasured systems

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 37.0, hours: 24, power: 31.5 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 200.0, hours: 12, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeBalanced, flowrate: 20.0, hours: 24, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeSupply, flowrate: 45.0, hours: 8, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 30.0, hours: 12, power: 25.0 },
                                      { fantype: HPXML::MechVentTypeBalanced, flowrate: 15.0, hours: 24, power: 25.0 }])
      end
    end
  end

  def test_mech_vent_shared
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end

    hpxml_name = _change_eri_version(hpxml_name, '2019ABCD')

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.0 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentDesign].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 60.1, hours: 24, power: 42.0 }])
      elsif [Constants::CalcTypeERIIndexAdjustmentReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 8.7, hours: 24, power: 49.4 }])
      end
    end
  end

  def test_mech_vent_shared_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    calc_types = [Constants::CalcTypeERIRatedHome,
                  Constants::CalcTypeERIReferenceHome]

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 19.6 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 800.0, in_unit_flowrate: 80.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_shared_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    calc_types = [Constants::CalcTypeERIRatedHome,
                  Constants::CalcTypeERIReferenceHome]

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 13.7 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 240.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_shared_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml_bldg = hpxml.buildings[0]
    vent_fan = hpxml_bldg.ventilation_fans.find { |vf| vf.used_for_whole_building_ventilation && vf.is_shared_system }
    vent_fan.fan_power = nil
    vent_fan.fan_power_defaulted = true
    vent_fan.in_unit_flow_rate = nil
    vent_fan.flow_rate_not_tested = true
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    calc_types = [Constants::CalcTypeERIRatedHome,
                  Constants::CalcTypeERIReferenceHome]

    calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIReferenceHome, Constants::CalcTypeCO2eReferenceHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeBalanced, flowrate: 31.1, hours: 24, power: 13.7 }])
      elsif [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_mech_vent(hpxml_bldg, [{ fantype: HPXML::MechVentTypeSupply, flowrate: 800.0, hours: 24, power: 800.0, in_unit_flowrate: 30.0, frac_recirc: 0.5, has_preheat: true, has_precool: true },
                                      { fantype: HPXML::MechVentTypeExhaust, flowrate: 72.0, hours: 24, power: 26.0 }])
      end
    end
  end

  def test_mech_vent_iecc_eri_exception
    IECCConstants::AllVersions.each do |iecc_version|
      _all_calc_types.each do |calc_type|
        hpxml_name = _change_iecc_version('base-mechvent-exhaust.xml', iecc_version)

        # Run IECC calculation
        iecc_hpxml, iecc_hpxml_bldg = _test_ruleset(hpxml_name, calc_type, iecc_version)

        # Run non-IECC calculation (using same ERI version as above)
        hpxml_name = _change_eri_version(hpxml_name, iecc_hpxml.header.eri_calculation_version)
        _base_hpxml, base_hpxml_bldg = _test_ruleset(hpxml_name, calc_type)

        if ['2018', '2021'].include?(iecc_version) && calc_type == Constants::CalcTypeERIReferenceHome
          # Check that ventilation exception in 2018/2021 IECC is being applied to the ERI Reference Home
          refute_equal(iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate, base_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
          assert_equal(57.0, iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
        else
          # In all other cases, check for the same ventilation as the standard ERI
          assert_equal(base_hpxml_bldg.ventilation_fans[0].tested_flow_rate, iecc_hpxml_bldg.ventilation_fans[0].tested_flow_rate)
        end
      end
    end
  end

  def test_whole_house_fan
    hpxml_name = 'base-mechvent-whole-house-fan.xml'

    _all_calc_types.each do |calc_type|
      _hpxml, hpxml_bldg = _test_ruleset(hpxml_name, calc_type)
      if [Constants::CalcTypeERIRatedHome].include? calc_type
        _check_whf(hpxml_bldg, flowrate: 4500, power: 300)
      else
        _check_whf(hpxml_bldg)
      end
    end
  end

  def _test_ruleset(hpxml_name, calc_type, iecc_version = nil)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: calc_type,
                          output_dir: @sample_files_path,
                          iecc_version: iecc_version)]

    hpxml_input_path = File.join(@sample_files_path, hpxml_name)
    success, errors, _, _, hpxml = run_rulesets(hpxml_input_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    # validate against OS-HPXML schematron
    assert_equal(true, @epvalidator.validate(designs[0].hpxml_output_path))
    @results_path = File.dirname(designs[0].hpxml_output_path)

    return hpxml, hpxml.buildings[0]
  end

  def _check_mech_vent(hpxml_bldg, all_expected_values = [])
    num_mech_vent = 0
    hpxml_bldg.ventilation_fans.each_with_index do |ventilation_fan, idx|
      next unless ventilation_fan.used_for_whole_building_ventilation
      next if ventilation_fan.is_cfis_supplemental_fan

      expected_values = all_expected_values[idx]
      num_mech_vent += 1
      assert_equal(expected_values[:fantype], ventilation_fan.fan_type)
      assert_in_delta(expected_values[:flowrate], ventilation_fan.rated_flow_rate.to_f + ventilation_fan.tested_flow_rate.to_f, 0.1)
      assert_in_delta(expected_values[:hours], ventilation_fan.hours_in_operation, 0.1)
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
        if ventilation_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler
          # Power based on W/cfm x autosized blower fan airflow rate, so just check that it's non-zero
          assert_operator(ventilation_fan.fan_power, :>, 0)
        else
          assert_nil(ventilation_fan.fan_power)
        end
      else
        assert_in_delta(expected_values[:power], ventilation_fan.fan_power, 0.1)
      end
      if expected_values[:sre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency)
      else
        assert_equal(expected_values[:sre], ventilation_fan.sensible_recovery_efficiency)
      end
      if expected_values[:tre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency)
      else
        assert_equal(expected_values[:tre], ventilation_fan.total_recovery_efficiency)
      end
      if expected_values[:asre].nil?
        assert_nil(ventilation_fan.sensible_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:asre], ventilation_fan.sensible_recovery_efficiency_adjusted)
      end
      if expected_values[:atre].nil?
        assert_nil(ventilation_fan.total_recovery_efficiency_adjusted)
      else
        assert_equal(expected_values[:atre], ventilation_fan.total_recovery_efficiency_adjusted)
      end
      if expected_values[:in_unit_flowrate].nil?
        assert_nil(ventilation_fan.in_unit_flow_rate)
      else
        assert_equal(true, ventilation_fan.is_shared_system)
        assert_in_delta(expected_values[:in_unit_flowrate], ventilation_fan.in_unit_flow_rate, 0.1)
      end
      if expected_values[:frac_recirc].nil?
        assert_nil(ventilation_fan.fraction_recirculation)
      else
        assert_equal(expected_values[:frac_recirc], ventilation_fan.fraction_recirculation)
      end
      if expected_values[:has_preheat].nil? || (not expected_values[:has_preheat])
        assert_nil(ventilation_fan.preheating_fuel)
      else
        refute_nil(ventilation_fan.preheating_fuel)
      end
      if expected_values[:has_precool].nil? || (not expected_values[:has_precool])
        assert_nil(ventilation_fan.precooling_fuel)
      else
        refute_nil(ventilation_fan.precooling_fuel)
      end
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS && ventilation_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler
        assert_equal(1.0, ventilation_fan.cfis_vent_mode_airflow_fraction)
      else
        assert_nil(ventilation_fan.cfis_vent_mode_airflow_fraction)
      end
      if expected_values[:cfis_mode].nil?
        assert_nil(ventilation_fan.cfis_addtl_runtime_operating_mode)
      else
        assert_equal(expected_values[:cfis_mode], ventilation_fan.cfis_addtl_runtime_operating_mode)
      end
      cfis_suppl_fan = ventilation_fan.cfis_supplemental_fan
      if expected_values[:cfis_suppl_flowrate].nil?
        assert_nil(cfis_suppl_fan)
      else
        assert_in_delta(expected_values[:cfis_suppl_flowrate], cfis_suppl_fan.rated_flow_rate.to_f + cfis_suppl_fan.tested_flow_rate.to_f, 0.1)
      end
      if expected_values[:cfis_suppl_power].nil?
        assert_nil(cfis_suppl_fan)
      else
        assert_in_delta(expected_values[:cfis_suppl_power], cfis_suppl_fan.fan_power, 0.1)
      end
    end
    assert_equal(all_expected_values.size, num_mech_vent)
  end

  def _check_whf(hpxml_bldg, flowrate: nil, power: nil)
    num_whf = 0
    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
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
