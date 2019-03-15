require_relative '../../../workflow/tests/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class EnclosureTest < MiniTest::Test
  def test_enclosure
    hpxml_name = "valid.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_infiltration(hpxml_doc, 3.0)
    _check_attics(hpxml_doc)
    _check_foundations(hpxml_doc)
    _check_walls_and_rim_joists(hpxml_doc)
    _check_windows(hpxml_doc, [240, 180, 0.33, 0.45],
                   [120, 0, 0.33, 0.45],
                   [120, 90, 0.33, 0.45],
                   [120, 270, 0.33, 0.45])
    _check_overhangs(hpxml_doc)
    _check_skylights(hpxml_doc)
    _check_doors(hpxml_doc, [80, 270, 4.4])

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_infiltration(hpxml_doc, 5.87)
    _check_attics(hpxml_doc)
    _check_foundations(hpxml_doc)
    _check_walls_and_rim_joists(hpxml_doc)
    _check_windows(hpxml_doc, [266.68, 0, 0.35, 0.40],
                   [266.68, 180, 0.35, 0.40],
                   [266.68, 90, 0.35, 0.40],
                   [266.68, 270, 0.35, 0.40])
    _check_overhangs(hpxml_doc)
    _check_skylights(hpxml_doc)
    _check_doors(hpxml_doc, [40, 0, 2.86])

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_infiltration(hpxml_doc, 3.0)
    _check_attics(hpxml_doc)
    _check_foundations(hpxml_doc)
    _check_walls_and_rim_joists(hpxml_doc)
    _check_windows(hpxml_doc, [108, 0, 0.33, 0.45],
                   [108, 180, 0.33, 0.45],
                   [108, 90, 0.33, 0.45],
                   [108, 270, 0.33, 0.45])
    _check_overhangs(hpxml_doc)
    _check_skylights(hpxml_doc)
    _check_doors(hpxml_doc, [80, 270, 4.4])

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_infiltration(hpxml_doc, 6.67)
    _check_attics(hpxml_doc)
    _check_foundations(hpxml_doc)
    _check_walls_and_rim_joists(hpxml_doc)
    _check_windows(hpxml_doc, [108, 0, 0.35, 0.40],
                   [108, 180, 0.35, 0.40],
                   [108, 90, 0.35, 0.40],
                   [108, 270, 0.35, 0.40])
    _check_overhangs(hpxml_doc)
    _check_skylights(hpxml_doc)
    _check_doors(hpxml_doc, [40, 0, 2.86])
  end

  def test_enclosure_skylights
    hpxml_name = "valid-enclosure-skylights.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_skylights(hpxml_doc, [15, 90, 0.33, 0.45],
                     [15, 270, 0.35, 0.47])

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_skylights(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_skylights(hpxml_doc, [15, 90, 0.33, 0.45],
                     [15, 270, 0.35, 0.47])

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_skylights(hpxml_doc)
  end

  def test_enclosure_overhangs
    hpxml_name = "valid-enclosure-overhangs.xml"

    # Rated Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIRatedHome)
    _check_overhangs(hpxml_doc, [2.5, 0, 4],
                     [1.5, 2, 6],
                     [1.5, 2, 7])

    # Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIReferenceHome)
    _check_overhangs(hpxml_doc)

    # IAD Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentDesign)
    _check_overhangs(hpxml_doc)

    # IAD Reference Home
    hpxml_doc = _test_measure(hpxml_name, Constants.CalcTypeERIIndexAdjustmentReferenceHome)
    _check_overhangs(hpxml_doc)
  end

  def test_enclosure_multiple_walls
    # TODO
  end

  def test_enclosure_orientation_45
    # TODO
  end

  def test_enclosure_pier_beam_foundation
    # TODO
  end

  def test_enclosure_slab_foundation
    # TODO
  end

  def test_enclosure_unconditioned_basement_foundation
    # TODO
  end

  def test_enclosure_unvented_crawlspace_foundation
    # TODO
  end

  def test_enclosure_vented_crawlspace_foundation
    # TODO
  end

  def _test_measure(hpxml_name, calc_type)
    root_path = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
    args_hash = {}
    args_hash['hpxml_path'] = File.join(root_path, "workflow", "sample_files", hpxml_name)
    args_hash['weather_dir'] = File.join(root_path, "weather")
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
    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(File.exists? args_hash['hpxml_output_path'])

    hpxml_doc = REXML::Document.new(File.read(args_hash['hpxml_output_path']))
    File.delete(args_hash['hpxml_output_path'])

    return hpxml_doc
  end

  def _check_infiltration(hpxml_doc, ach50)
    assert_in_epsilon(ach50, Float(hpxml_doc.elements["/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].text), 0.01)
  end

  def _check_attics(hpxml_doc)
    # TODO
  end

  def _check_foundations(hpxml_doc)
    # TODO
  end

  def _check_walls_and_rim_joists(hpxml_doc)
    # TODO
  end

  def _check_windows(hpxml_doc, *windows)
    num_windows = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |window|
      area, azimuth, ufactor, shgc = windows[num_windows]
      assert_in_epsilon(area, Float(window.elements["Area"].text), 0.01)
      assert_equal(azimuth, Float(window.elements["Azimuth"].text))
      assert_equal(ufactor, Float(window.elements["UFactor"].text))
      assert_equal(shgc, Float(window.elements["SHGC"].text))
      num_windows += 1
    end
    assert_equal(windows.size, num_windows)
  end

  def _check_overhangs(hpxml_doc, *overhangs)
    num_overhangs = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |window|
      next if window.elements["Overhangs"].nil?

      overhang_depth, overhang_top, overhang_bottom = overhangs[num_overhangs]
      assert_equal(overhang_depth, Float(window.elements["Overhangs/Depth"].text))
      assert_equal(overhang_top, Float(window.elements["Overhangs/DistanceToTopOfWindow"].text))
      assert_equal(overhang_bottom, Float(window.elements["Overhangs/DistanceToBottomOfWindow"].text))
      num_overhangs += 1
    end
    assert_equal(overhangs.size, num_overhangs)
  end

  def _check_skylights(hpxml_doc, *skylights)
    num_skylights = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight") do |skylight|
      area, azimuth, ufactor, shgc = skylights[num_skylights]
      assert_in_epsilon(area, Float(skylight.elements["Area"].text), 0.01)
      assert_equal(azimuth, Float(skylight.elements["Azimuth"].text))
      assert_equal(ufactor, Float(skylight.elements["UFactor"].text))
      assert_equal(shgc, Float(skylight.elements["SHGC"].text))
      num_skylights += 1
    end
    assert_equal(skylights.size, num_skylights)
  end

  def _check_doors(hpxml_doc, *doors)
    num_doors = 0
    hpxml_doc.elements.each("/HPXML/Building/BuildingDetails/Enclosure/Doors/Door") do |door|
      area, azimuth, rvalue = doors[num_doors]
      assert_in_epsilon(area, Float(door.elements["Area"].text), 0.01)
      assert_equal(azimuth, Float(door.elements["Azimuth"].text))
      assert_in_epsilon(rvalue, Float(door.elements["RValue"].text), 0.01)
      num_doors += 1
    end
    assert_equal(doors.size, num_doors)
  end
end