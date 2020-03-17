require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

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
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_below_ashrae_622
    # Test Rated Home:
    # For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate
    # combined with the time-averaged Whole-House Mechanical Ventilation System rate, which shall
    # not be less than 0.03 x CFA + 7.5 x (Nbr+1) cfm

    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements['TestedFlowRate'].text = 1.0
    vent_fan.elements['HoursInOperation'].text = 1
    vent_fan.elements['FanPower'].text = 1.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 35.4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 101.2, 24, 101.2) # Increased runtime and fan power

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 27.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 78.1, 24, 78.1) # Increased runtime and fan power

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements.delete('TestedFlowRate')
    vent_fan.elements['HoursInOperation'].text = 8.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 0.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 0.1, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 13.0)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_IR_301_2019_001
    # Test IR 301-2019-001: Fan Energy for Unmeasured Mechanical Ventilation
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements.delete('TestedFlowRate')
    vent_fan.elements['HoursInOperation'].text = 8.0

    # Update CFA/Volume to trigger IR
    cfa = 2750
    hpxml_doc.elements['/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea'].text = cfa
    hpxml_doc.elements['/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume'].text = cfa * 8.0
    hpxml_doc.elements['/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume'].text = cfa * 8.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.7, 24, 0.0)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 0.0, 24, 0.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)
  end

  def test_mech_vent_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements.delete('FanPower')
    vent_fan.elements['HoursInOperation'].text = 8.0
    vent_fan.elements['TestedFlowRate'].text = 10.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 35.4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 101.2, 24, 35.4)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 27.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 78.1, 24, 27.3)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_and_defaulted_fan_power
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-exhaust.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements.delete('FanPower')
    vent_fan.elements.delete('TestedFlowRate')
    vent_fan.elements['HoursInOperation'].text = 8.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 0.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 0.1, 24, 0.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 13.0)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 12.95)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_unmeasured_airflow_rate_and_defaulted_fan_power_cfis
    # Create derivative file for testing
    hpxml_name = 'base-mechvent-cfis.xml'
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))

    # Update mech vent object
    vent_fan = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    vent_fan.elements.delete('FanPower')
    vent_fan.elements.delete('TestedFlowRate')
    vent_fan.elements['HoursInOperation'].text = 8.0

    # Save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'supply only', 56.5, 24, 0.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'central fan integrated supply', 0.1, 24, 800.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)
  end

  def test_mech_vent_attached_or_multifamily
    hpxml_name = 'base-enclosure-adiabatic-surfaces.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 68.2, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 96.3, 24, 67.4)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 32.1, 24, 55.0)

    # Test w/ 301-2014
    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 70.5, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 102.0, 24, 71.4)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 102.0, 24, 71.4)

    # FIXME: Add tests for new 301-2019 space types HPXML file
  end

  def test_mech_vent_exhaust
    hpxml_name = 'base-mechvent-exhaust.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 56.5, 24, 35.4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 110.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 27.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 110.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_supply
    hpxml_name = 'base-mechvent-supply.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'supply only', 56.5, 24, 35.4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'supply only', 110.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'supply only', 37.0, 24, 27.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'supply only', 110.0, 24, 30.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_balanced
    hpxml_name = 'base-mechvent-balanced.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 33.2, 24, 54.7)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'balanced', 110.0, 24, 60.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 37.0, 24, 54.7)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'balanced', 110.0, 24, 60.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_erv
    hpxml_name = 'base-mechvent-erv.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 33.2, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'energy recovery ventilator', 110.0, 24, 60.0, 0.72, 0.48)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 37.0, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'energy recovery ventilator', 110.0, 24, 60.0, 0.72, 0.48)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_erv_adjusted
    hpxml_name = 'base-mechvent-erv-atre-asre.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 33.2, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'energy recovery ventilator', 110.0, 24, 60.0, nil, nil, 0.79, 0.526)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 37.0, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'energy recovery ventilator', 110.0, 24, 60.0, nil, nil, 0.79, 0.526)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_hrv
    hpxml_name = 'base-mechvent-hrv.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 33.2, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'heat recovery ventilator', 110.0, 24, 60.0, 0.72)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 37.0, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'heat recovery ventilator', 110.0, 24, 60.0, 0.72)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_hrv_adjusted
    hpxml_name = 'base-mechvent-hrv-asre.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 33.2, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'heat recovery ventilator', 110.0, 24, 60.0, nil, nil, 0.79, nil)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 37.0, 24, 78.1)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'heat recovery ventilator', 110.0, 24, 60.0, nil, nil, 0.79, nil)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_cfis
    hpxml_name = 'base-mechvent-cfis.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'supply only', 56.5, 24, 35.4)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'central fan integrated supply', 330.0, 8, 300.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 8.5, 24, 42.0)

    hpxml_name = _change_to_301_2014(hpxml_name)

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'supply only', 37.0, 24, 27.3)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc, 'central fan integrated supply', 330.0, 8, 300.0)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_mech_vent_cfm50_infiltration
    # Create derivative file for testing
    hpxml_name = _change_to_301_2014('base-enclosure-infil-cfm50.xml')

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_mech_vent(hpxml_doc, 'exhaust only', 37.0, 24, 0.0) # Should have airflow but not fan energy

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_mech_vent(hpxml_doc)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_mech_vent(hpxml_doc, 'balanced', 60.0, 24, 42.0)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_mech_vent(hpxml_doc, 'balanced', 34.0, 24, 42.0)
  end

  def test_whole_house_fan
    hpxml_name = 'base-misc-whole-house-fan.xml'

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_whf(hpxml_doc)

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_whf(hpxml_doc, 4500, 300)

    # IAD
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_whf(hpxml_doc)

    # IAD Reference
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_whf(hpxml_doc)
  end

  def _test_measure(hpxml_name, calc_type)
    args_hash = {}
    args_hash['hpxml_input_path'] = File.join(@root_path, 'workflow', 'sample_files', hpxml_name)
    args_hash['hpxml_output_path'] = File.join(File.dirname(__FILE__), "#{calc_type}.xml")
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
    assert(File.exist? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_mech_vent(hpxml_doc, fantype = nil, flowrate = nil, hours = nil, power = nil, sre = nil, tre = nil, asre = nil, atre = nil)
    mechvent = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not fantype.nil?
      assert_equal(fantype, mechvent.elements['FanType'].text)
      if not mechvent.elements['RatedFlowRate'].nil?
        assert_in_delta(flowrate, Float(mechvent.elements['RatedFlowRate'].text), 0.1)
      else
        assert_in_delta(flowrate, Float(mechvent.elements['TestedFlowRate'].text), 0.1)
      end
      assert_equal(hours, Float(mechvent.elements['HoursInOperation'].text))
      assert_in_delta(power, Float(mechvent.elements['FanPower'].text), 0.1)
      if sre.nil?
        assert_nil(mechvent.elements['SensibleRecoveryEfficiency'])
      else
        assert_equal(sre, Float(mechvent.elements['SensibleRecoveryEfficiency'].text))
      end
      if tre.nil?
        assert_nil(mechvent.elements['TotalRecoveryEfficiency'])
      else
        assert_equal(tre, Float(mechvent.elements['TotalRecoveryEfficiency'].text))
      end
      if asre.nil?
        assert_nil(mechvent.elements['AdjustedSensibleRecoveryEfficiency'])
      else
        assert_equal(asre, Float(mechvent.elements['AdjustedSensibleRecoveryEfficiency'].text))
      end
      if atre.nil?
        assert_nil(mechvent.elements['AdjustedTotalRecoveryEfficiency'])
      else
        assert_equal(atre, Float(mechvent.elements['AdjustedTotalRecoveryEfficiency'].text))
      end
    else
      assert_nil(mechvent)
    end
  end

  def _check_whf(hpxml_doc, flowrate = nil, power = nil)
    whf = hpxml_doc.elements["/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction='true']"]
    if not flowrate.nil?
      assert_in_epsilon(flowrate, Float(whf.elements['RatedFlowRate'].text), 0.01)
      assert_in_epsilon(power, Float(whf.elements['FanPower'].text), 0.01)
    else
      assert_nil(whf)
    end
  end

  def _change_to_301_2014(hpxml_name)
    # Create derivative file for 301-2014 testing
    hpxml_doc = REXML::Document.new(File.read(File.join(@root_path, 'workflow', 'sample_files', hpxml_name)))
    hpxml_doc.elements['/HPXML/SoftwareInfo/extension/ERICalculation/Version'].text = '2014'
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
    return hpxml_name
  end
end
