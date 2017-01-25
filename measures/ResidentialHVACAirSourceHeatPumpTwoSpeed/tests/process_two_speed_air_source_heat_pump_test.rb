require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessTwoSpeedAirSourceHeatPumpTest < MiniTest::Test  
  
  def test_new_construction_seer_16_8pt6_hspf
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>1, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_SL_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 5)  
  end
  
  def test_new_construction_fbsmt_seer_16_8pt6_hspf
    args_hash = {}
    args_hash["heat_pump_capacity"] = "3.0"
    args_hash["supplemental_capacity"] = "20"
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "CoolingNominalCapacity"=>[7596.4, 10550.55], "HeatingNominalCapacity"=>[7596.4, 10550.55], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)    
  end 
  
  def test_retrofit_replace_furnace
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end
  
  def test_retrofit_replace_ashp
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingDXSingleSpeed"=>1, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ASHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end  
  
  def test_retrofit_replace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end  
  
  def test_retrofit_replace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1, "FanOnOff"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 7)
  end  
  
  def test_retrofit_replace_electric_baseboard
    args_hash = {}
    expected_num_del_objects = {"ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 8)
  end
  
  def test_retrofit_replace_boiler
    args_hash = {}
    expected_num_del_objects = {"BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  
  
  def test_retrofit_replace_mshp
    args_hash = {}
    expected_num_del_objects = {"FanOnOff"=>2, "AirConditionerVariableRefrigerantFlow"=>2, "ZoneHVACTerminalUnitVariableRefrigerantFlow"=>2, "CoilCoolingDXVariableRefrigerantFlow"=>2, "CoilHeatingDXVariableRefrigerantFlow"=>2, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_MSHP.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end
  
  def test_retrofit_replace_furnace_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  
  
  def test_retrofit_replace_furnace_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilHeatingGas"=>1, "FanOnOff"=>2, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "CoilHeatingElectric"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  
  
  def test_retrofit_replace_electric_baseboard_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end  
  
  def test_retrofit_replace_boiler_central_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilCoolingDXSingleSpeed"=>1, "BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 11)
  end  

  def test_retrofit_replace_electric_baseboard_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "ZoneHVACBaseboardConvectiveElectric"=>2}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_ElectricBaseboard_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  
  
  def test_retrofit_replace_boiler_room_air_conditioner
    args_hash = {}
    expected_num_del_objects = {"CoilCoolingDXSingleSpeed"=>1, "ZoneHVACPackagedTerminalAirConditioner"=>1, "FanOnOff"=>1, "CoilHeatingElectric"=>1, "BoilerHotWater"=>1, "PumpConstantSpeed"=>1, "ZoneHVACBaseboardConvectiveWater"=>2, "SetpointManagerScheduled"=>1, "CoilHeatingWaterBaseboard"=>2, "PlantLoop"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Boiler_RoomAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 10)
  end

  def test_retrofit_replace_gshp_vert_bore
    args_hash = {}
    expected_num_del_objects = {"SetpointManagerFollowGroundTemperature"=>1, "GroundHeatExchangerVertical"=>1, "FanOnOff"=>1, "CoilHeatingWaterToAirHeatPumpEquationFit"=>1, "CoilCoolingWaterToAirHeatPumpEquationFit"=>1, "PumpVariableSpeed"=>1, "CoilHeatingElectric"=>1, "PlantLoop"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>1, "AirLoopHVAC"=>1, "CoilCoolingDXMultiSpeed"=>1, "FanOnOff"=>1, "AirTerminalSingleDuctUncontrolled"=>2, "CoilHeatingElectric"=>1, "CoilHeatingDXMultiSpeed"=>1, "CoilCoolingDXMultiSpeedStageData"=>2, "CoilHeatingDXMultiSpeedStageData"=>2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_GSHPVertBore.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 9)
  end  
  
  def test_single_family_attached_new_construction
    num_units = 4
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units, "CoilCoolingDXMultiSpeed"=>num_units, "FanOnOff"=>num_units, "AirTerminalSingleDuctUncontrolled"=>num_units*2, "CoilHeatingElectric"=>num_units, "CoilHeatingDXMultiSpeed"=>num_units, "CoilCoolingDXMultiSpeedStageData"=>num_units*2, "CoilHeatingDXMultiSpeedStageData"=>num_units*2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("SFA_4units_1story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*6)
  end

  def test_multifamily_new_construction
    num_units = 8
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {"AirLoopHVACUnitarySystem"=>num_units, "AirLoopHVAC"=>num_units, "CoilCoolingDXMultiSpeed"=>num_units, "FanOnOff"=>num_units, "AirTerminalSingleDuctUncontrolled"=>num_units, "CoilHeatingElectric"=>num_units, "CoilHeatingDXMultiSpeed"=>num_units, "CoilCoolingDXMultiSpeedStageData"=>num_units*2, "CoilHeatingDXMultiSpeedStageData"=>num_units*2}
    expected_values = {"CoolingCOP"=>[4.16, 3.69], "HeatingCOP"=>[3.97, 3.43], "MaximumSupplyAirTemperature"=>76.66}
    _test_measure("MF_8units_1story_SL_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units*5)
  end
  
  private
  
  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = ProcessTwoSpeedAirSourceHeatPump.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
    
    return result
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos=0, num_warnings=0, debug=false)
    # create an instance of the measure
    measure = ProcessTwoSpeedAirSourceHeatPump.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)
    
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_objects(model)
    
    # get new and deleted objects
    obj_type_exclusions = ["CurveQuadratic", "CurveBiquadratic", "CurveCubic", "Node", "AirLoopHVACZoneMixer", "SizingSystem", "AirLoopHVACZoneSplitter", "ScheduleTypeLimits", "CurveExponent", "ScheduleConstant", "SizingPlant", "PipeAdiabatic", "ConnectorSplitter", "ModelObjectList", "ConnectorMixer"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            next if not new_object.respond_to?("to_#{obj_type}")
            new_object = new_object.public_send("to_#{obj_type}").get
            if obj_type == "AirLoopHVACUnitarySystem"
                assert_in_epsilon(expected_values["MaximumSupplyAirTemperature"], new_object.maximumSupplyAirTemperature.get, 0.01)
            elsif obj_type == "CoilCoolingDXMultiSpeed"
                new_object.stages.each_with_index do |stage, i|
                    assert_in_epsilon(expected_values["CoolingCOP"][i], stage.grossRatedCoolingCOP, 0.01)
                    if stage.grossRatedTotalCoolingCapacity.is_initialized
                        assert_in_epsilon(expected_values["CoolingNominalCapacity"][i], stage.grossRatedTotalCoolingCapacity.get, 0.01)
                    end
                end
            elsif obj_type == "CoilHeatingDXMultiSpeed"
                new_object.stages.each_with_index do |stage, i|
                    assert_in_epsilon(expected_values["HeatingCOP"][i], stage.grossRatedHeatingCOP, 0.01)
                    if stage.grossRatedHeatingCapacity.is_initialized
                        assert_in_epsilon(expected_values["HeatingNominalCapacity"][i], stage.grossRatedHeatingCapacity.get, 0.01)
                    end
                end
            end
        end
    end
    
    return model
  end  
  
end