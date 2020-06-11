# frozen_string_literal: true

require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'csv'
require 'oga'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

class EnergyRatingIndexTest < Minitest::Test
  def before_setup
    @test_results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p @test_results_dir
    @test_files_dir = File.join(File.dirname(__FILE__), 'test_files')
    FileUtils.mkdir_p @test_files_dir
  end

  def test_sample_files
    test_name = 'sample_files'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    files = 'base*.xml'
    all_results = {}
    xmldir = "#{File.dirname(__FILE__)}/../sample_files"
    Dir["#{xmldir}/#{files}"].sort.each do |xml|
      hpxmls, csvs, runtime = _run_workflow(xml, test_name, hourly_output: true)
      all_results[File.basename(xml)] = _get_csv_results(csvs[:eri_results])
      all_results[File.basename(xml)]['Workflow Runtime (s)'] = runtime
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['XML'] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Cross-simulation tests

    # Verify that REUL Hot Water is identical across water heater types
    _test_reul(all_results, 'base-dhw', 'REUL Hot Water (MBtu)')

    # Verify that REUL Heating/Cooling are identical across HVAC types
    _test_reul(all_results, 'base-hvac', 'REUL Heating (MBtu)')
    _test_reul(all_results, 'base-hvac', 'REUL Cooling (MBtu)')
  end

  def test_sample_files_301_2014
    test_name = 'sample_files_301_2014'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    files = 'base*.xml'
    all_results = {}
    xmldir = "#{File.dirname(__FILE__)}/../sample_files"
    Dir["#{xmldir}/#{files}"].sort.each do |xml|
      next if xml.include? 'base-version'
      # Create derivative file

      hpxml = HPXML.new(hpxml_path: xml)
      hpxml.header.eri_calculation_version = '2014ADEGL'
      xml2014 = File.absolute_path(File.join(xmldir, File.basename(xml, '.xml') + '_301_2014' + File.extname(xml)))
      XMLHelper.write_file(hpxml.to_oga, xml2014)

      hpxmls, csvs, runtime = _run_workflow(xml2014, test_name, hourly_output: true)
      all_results[File.basename(xml2014)] = _get_csv_results(csvs[:eri_results])
      all_results[File.basename(xml2014)]['Workflow Runtime (s)'] = runtime

      File.delete(xml2014)
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['XML'] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Cross-simulation tests

    # Verify that REUL Hot Water is identical across water heater types
    _test_reul(all_results, 'base-dhw', 'REUL Hot Water (MBtu)')

    # Verify that REUL Heating/Cooling are identical across HVAC types
    _test_reul(all_results, 'base-hvac', 'REUL Heating (MBtu)')
    _test_reul(all_results, 'base-hvac', 'REUL Cooling (MBtu)')
  end

  def test_sample_files_invalid
    test_name = 'invalid_files'
    expected_error_msgs = { 'invalid-wmo.xml' => ["Weather station WMO '999999' could not be found in weather/data.csv."],
                            'invalid-epw-filepath.xml' => ["foo.epw' could not be found."],
                            'dhw-frac-load-served.xml' => ['Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15.'],
                            'missing-elements.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction: NumberofConditionedFloors',
                                                       'Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction: ConditionedFloorArea'],
                            'hvac-frac-load-served.xml' => ['Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is 1.2.',
                                                            'Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is 1.1.'],
                            'hvac-ducts-leakage-exemption-pre-addendum-d.xml' => ['ERI Version 2014A does not support duct leakage testing exemption.'],
                            'hvac-ducts-leakage-total-pre-addendum-l.xml' => ['ERI Version 2014ADEG does not support total duct leakage testing.'] }

    xmldir = "#{File.dirname(__FILE__)}/../sample_files/invalid_files"
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _run_workflow(xml, test_name, expect_error: true, expect_error_msgs: expected_error_msgs[File.basename(xml)])
    end
  end

  def test_weather_cache
    # Move existing -cache.csv file
    weather_dir = File.join(File.dirname(__FILE__), '..', '..', 'weather')
    cache_csv = File.join(weather_dir, 'USA_CO_Denver.Intl.AP.725650_TMY3-cache.csv')
    FileUtils.mv(cache_csv, "#{cache_csv}.bak")

    data_csv = File.join(weather_dir, 'data.csv')
    FileUtils.cp(data_csv, "#{data_csv}.bak")

    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" \"#{File.join(File.dirname(__FILE__), '..', 'energy_rating_index.rb')}\" --cache-weather"
    system(command)

    assert(File.exist?(cache_csv))

    # Restore original and cleanup
    FileUtils.mv("#{cache_csv}.bak", cache_csv)
    File.delete(data_csv)
    FileUtils.mv("#{data_csv}.bak", data_csv)
  end

  def test_resnet_ashrae_140
    test_name = 'RESNET_Test_4.1_Standard_140'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.1_Standard_140')
    all_results = []
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name)
      htg_load, clg_load = _get_simulation_load_results(csv_path)
      if xml.include? 'C.xml'
        all_results << [xml, htg_load, 'N/A']
        assert_operator(htg_load, :>, 0)
      elsif xml.include? 'L.xml'
        all_results << [xml, 'N/A', clg_load]
        assert_operator(clg_load, :>, 0)
      end
    end
    assert(all_results.size > 0)

    # Write results to csv
    htg_loads = {}
    clg_loads = {}
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test', 'Annual Heating Load [MMBtu]', 'Annual Cooling Load [MMBtu]']
      all_results.each do |results|
        next unless results[0].include? 'C.xml'

        csv << results
        test_name = File.basename(results[0], File.extname(results[0]))
        htg_loads[test_name] = results[1]
      end
      all_results.each do |results|
        next unless results[0].include? 'L.xml'

        csv << results
        test_name = File.basename(results[0], File.extname(results[0]))
        clg_loads[test_name] = results[2]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    _check_ashrae_140_results(htg_loads, clg_loads)
  end

  def test_resnet_hers_reference_home_auto_generation
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_4.2_HERS_AutoGen_Reference_Home',
                                                                   'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2019A')
    end
  end

  def test_resnet_hers_reference_home_auto_generation_301_2019_pre_addendum_a
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2019')
    end
  end

  def test_resnet_hers_reference_home_auto_generation_301_2014
    # Older test w/ 301-2014 mechanical ventilation acceptance criteria
    all_results = _test_resnet_hers_reference_home_auto_generation('RESNET_Test_Other_HERS_AutoGen_Reference_Home_301_2014',
                                                                   'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_reference_home_components(results, test_num, '2014')
    end
  end

  def test_resnet_hers_iad_home_auto_generation
    test_name = 'RESNET_Test_Other_HERS_AutoGen_IAD_Home'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home')
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      out_xml = File.join(@test_files_dir, test_name, File.basename(xml), File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIIndexAdjustmentDesign, xml, out_xml)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_iad_home_components(out_xml, test_num)
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Component', 'Test 1 Results', 'Test 2 Results', 'Test 3 Results', 'Test 4 Results']
      all_results['01-L100.xml'].keys.each do |component|
        csv << [component,
                all_results['01-L100.xml'][component],
                all_results['02-L100.xml'][component],
                all_results['03-L304.xml'][component],
                all_results['04-L324.xml'][component]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml)[0, 2].to_i
      _check_iad_home_components(results, test_num)
    end
  end

  def test_resnet_hers_method
    all_results = _test_resnet_hers_method('RESNET_Test_4.3_HERS_Method',
                                           'RESNET_Tests/4.3_HERS_Method')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2019A')
    end
  end

  def test_resnet_hers_method_301_2019_pre_addendum_a
    all_results = _test_resnet_hers_method('RESNET_Test_Other_HERS_Method_301_2019_PreAddendumA.3_HERS_Method',
                                           'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2019')
    end
  end

  def test_resnet_hers_method_301_2014_pre_addendum_e
    # Tests before 301-2019 Addendum E (IAF) was in place
    all_results = _test_resnet_hers_method('RESNET_Test_Other_HERS_Method_301_2014_PreAddendumE.3_HERS_Method',
                                           'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE')

    # Check results
    all_results.each do |xml, results|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      _check_method_results(results, test_num, test_num == 2, '2014')
    end
  end

  def test_resnet_hvac
    test_name = 'RESNET_Test_4.4_HVAC'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.4_HVAC')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name)

      is_heat = false
      if xml.include? 'HVAC2'
        is_heat = true
      end
      is_electric_heat = true
      if xml.include?('HVAC2a') || xml.include?('HVAC2b')
        is_electric_heat = false
      end
      hvac, hvac_fan = _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
      all_results[File.basename(xml)] = [hvac, hvac_fan]
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'HVAC (kWh or therm)', 'HVAC Fan (kWh)']
      all_results.each_with_index do |(xml, results), i|
        csv << [xml, results[0], results[1]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, results), i|
      base_results = nil
      if xml == 'HVAC1b.xml'
        base_results = all_results['HVAC1a.xml']
      elsif xml == 'HVAC2b.xml'
        base_results = all_results['HVAC2a.xml']
      elsif ['HVAC2d.xml', 'HVAC2e.xml'].include? xml
        base_results = all_results['HVAC2c.xml']
      end
      next if base_results.nil?

      _check_hvac_test_results(xml, results, base_results)
    end
  end

  def test_resnet_dse
    test_name = 'RESNET_Test_4.5_DSE'
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    xmldir = File.join(File.dirname(__FILE__), 'RESNET_Tests/4.5_DSE')
    all_results = {}
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      sql_path, csv_path, sim_time = _run_simulation(xml, test_name, true)

      is_heat = false
      if ['HVAC3a.xml', 'HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? File.basename(xml)
        is_heat = true
      end
      is_electric_heat = false
      hvac, hvac_fan = _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
      dse, seasonal_temp, percent_min, percent_max = _calc_dse(xml, sql_path)
      all_results[File.basename(xml)] = [hvac, hvac_fan, seasonal_temp, dse, percent_min, percent_max]
    end
    assert(all_results.size > 0)

    all_results.each_with_index do |(xml, results), i|
      base_results = nil
      if ['HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? xml
        base_results = all_results['HVAC3a.xml']
      elsif ['HVAC3f.xml', 'HVAC3g.xml', 'HVAC3h.xml'].include? xml
        base_results = all_results['HVAC3e.xml']
      end
      next if base_results.nil?

      if ['HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? xml
        curr_val = results[0] / 10.0 + results[1] / 293.0
        base_val = base_results[0] / 10.0 + base_results[1] / 293.0
      else
        curr_val = results[0] + results[1]
        base_val = base_results[0] + base_results[1]
      end

      percent_change = ((curr_val - base_val) / base_val * 100.0).round(1)
      all_results[xml] << percent_change.round(1)
    end

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'Heat/Cool (kWh or therm)', 'HVAC Fan (kWh)', 'Seasonal Duct Zone Temperature (F)', 'Seasonal DSE', 'Criteria Min (%)', 'Criteria Max (%)', 'Test Value (%)']
      all_results.each_with_index do |(xml, results), i|
        next unless ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1], results[2], results[3], results[4], results[5], results[6]]
      end
      all_results.each_with_index do |(xml, results), i|
        next if ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

        csv << [xml, results[0], results[1], results[2], results[3], results[4], results[5], results[6]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    # Check results
    all_results.each_with_index do |(xml, results), i|
      next if ['HVAC3a.xml', 'HVAC3e.xml'].include? xml

      _check_dse_test_results(xml, results)
    end
  end

  def test_resnet_hot_water
    all_results = _test_resnet_hot_water('RESNET_Test_4.6_Hot_Water',
                                         'RESNET_Tests/4.6_Hot_Water')

    # Check results
    all_results.each_with_index do |(xml, result), i|
      rated_dhw, rated_recirc = result
      test_num = i + 1

      if [2, 3].include? test_num
        base_val = all_results['L100AD-HW-01.xml'][0..1].inject(:+)
      elsif [4, 5, 6, 7].include? test_num
        base_val = all_results['L100AD-HW-02.xml'][0..1].inject(:+)
      elsif [9, 10].include? test_num
        base_val = all_results['L100AM-HW-01.xml'][0..1].inject(:+)
      elsif [11, 12, 13, 14].include? test_num
        base_val = all_results['L100AM-HW-02.xml'][0..1].inject(:+)
      end
      if test_num >= 8
        mn_val = all_results[xml.gsub('AM', 'AD')][0..1].inject(:+)
      end

      _check_hot_water(test_num, rated_dhw + rated_recirc, base_val, mn_val)
    end
  end

  def test_resnet_hot_water_301_2019_pre_addendum_a
    # Tests w/o 301-2019 Addendum A
    all_results = _test_resnet_hot_water('RESNET_Test_Other_Hot_Water_301_2019_PreAddendumA',
                                         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA')

    # Check results
    all_results.each_with_index do |(xml, result), i|
      rated_dhw, rated_recirc = result
      test_num = i + 1

      if [2, 3].include? test_num
        base_val = all_results['L100AD-HW-01.xml'][0..1].inject(:+)
      elsif [4, 5, 6, 7].include? test_num
        base_val = all_results['L100AD-HW-02.xml'][0..1].inject(:+)
      elsif [9, 10].include? test_num
        base_val = all_results['L100AM-HW-01.xml'][0..1].inject(:+)
      elsif [11, 12, 13, 14].include? test_num
        base_val = all_results['L100AM-HW-02.xml'][0..1].inject(:+)
      end
      if test_num >= 8
        mn_val = all_results[xml.gsub('AM', 'AD')][0..1].inject(:+)
      end

      _check_hot_water_301_2019_pre_addendum_a(test_num, rated_dhw + rated_recirc, base_val, mn_val)
    end
  end

  def test_resnet_hot_water_301_2014_pre_addendum_a
    # Tests w/o 301-2014 Addendum A
    all_results = _test_resnet_hot_water('RESNET_Test_Other_Hot_Water_301_2014_PreAddendumA',
                                         'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA')

    # Check results
    all_results.each_with_index do |(xml, result), i|
      rated_dhw, rated_recirc = result
      test_num = i + 1

      if [2, 3].include? test_num
        base_val = all_results['L100AD-HW-01.xml'][0..1].inject(:+)
      elsif [5, 6].include? test_num
        base_val = all_results['L100AM-HW-01.xml'][0..1].inject(:+)
      end
      if test_num >= 4
        mn_val = all_results[xml.gsub('AM', 'AD')][0..1].inject(:+)
      end

      _check_hot_water_301_2014_pre_addendum_a(test_num, rated_dhw + rated_recirc, base_val, mn_val)
    end
  end

  def test_running_with_cli
    # Test that these tests can be run from the OpenStudio CLI (and not just system ruby)
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" #{File.absolute_path(__FILE__)} --name=foo"
    success = system(command)
    assert(success)
  end

  private

  def _test_resnet_hot_water(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    base_vals = {}
    mn_vals = {}
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      _test_schema_validation(xml)
      out_xml = File.join(@test_files_dir, File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIRatedHome, xml, out_xml)
      sql_path, csv_path, sim_time = _run_simulation(out_xml, test_name)

      all_results[File.basename(xml)] = _get_hot_water(csv_path)
      assert_operator(all_results[File.basename(xml)][0], :>, 0)

      File.delete(out_xml)
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case', 'DHW Energy (therms)', 'GPD']
      all_results.each_with_index do |(xml, result), i|
        rated_dhw, rated_recirc, rated_gpd = result
        csv << [xml, (rated_dhw * 10.0).round(2), (rated_recirc * 293.08).round(2), rated_gpd.round(2)]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    return all_results
  end

  def _test_resnet_hers_reference_home_auto_generation(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      out_xml = File.join(@test_files_dir, test_name, File.basename(xml), File.basename(xml))
      _run_ruleset(Constants.CalcTypeERIReferenceHome, xml, out_xml)
      test_num = File.basename(xml)[0, 2].to_i
      all_results[File.basename(xml)] = _get_reference_home_components(out_xml, test_num)

      # Re-simulate reference HPXML file
      _override_mech_vent_fan_power(out_xml)
      hpxmls, csvs, runtime = _run_workflow(out_xml, test_name)
      worksheet_results = _get_csv_results(csvs[:eri_worksheet])
      all_results[File.basename(xml)]['e-Ratio'] = worksheet_results['Total Loads TnML'] / worksheet_results['Total Loads TRL']
    end
    assert(all_results.size > 0)

    # Write results to csv
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Component', 'Test 1 Results', 'Test 2 Results', 'Test 3 Results', 'Test 4 Results']
      all_results['01-L100.xml'].keys.each do |component|
        csv << [component,
                all_results['01-L100.xml'][component],
                all_results['02-L100.xml'][component],
                all_results['03-L304.xml'][component],
                all_results['04-L324.xml'][component]]
      end
    end
    puts "Wrote results to #{test_results_csv}."

    return all_results
  end

  def _test_resnet_hers_method(test_name, dir_name)
    test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
    File.delete(test_results_csv) if File.exist? test_results_csv

    # Run simulations
    all_results = {}
    xmldir = File.join(File.dirname(__FILE__), dir_name)
    Dir["#{xmldir}/*.xml"].sort.each do |xml|
      test_num = File.basename(xml).gsub('L100A-', '').gsub('.xml', '').to_i
      hpxmls, csvs, runtime = _run_workflow(xml, test_name)
      all_results[xml] = _get_csv_results(csvs[:eri_results])
    end
    assert(all_results.size > 0)

    # Write results to csv
    keys = all_results.values[0].keys
    CSV.open(test_results_csv, 'w') do |csv|
      csv << ['Test Case'] + keys
      all_results.each_with_index do |(xml, results), i|
        csv_line = [File.basename(xml)]
        keys.each do |key|
          csv_line << results[key]
        end
        csv << csv_line
      end
    end
    puts "Wrote results to #{test_results_csv}."

    return all_results
  end

  def _run_ruleset(design, xml, out_xml)
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures_dir = File.join(File.dirname(__FILE__), '../..')

    measures = {}

    # Add 301 measure to workflow
    measure_subdir = 'rulesets/301EnergyRatingIndexRuleset'
    args = {}
    args['calc_type'] = design
    args['hpxml_input_path'] = File.absolute_path(xml)
    args['hpxml_output_path'] = out_xml
    update_args_hash(measures, measure_subdir, args)

    # Apply measures
    FileUtils.mkdir_p(File.dirname(out_xml))
    success = apply_measures(measures_dir, measures, runner, model)
    show_output(runner.result) unless success
    assert(success)
    assert(File.exist?(out_xml))

    hpxml = XMLHelper.parse_file(out_xml)
    XMLHelper.delete_element(XMLHelper.get_element(hpxml, '/HPXML/SoftwareInfo/extension/ERICalculation'), 'Design')
    XMLHelper.write_file(hpxml, out_xml)
  end

  def _run_workflow(xml, test_name, expect_error: false, expect_error_msgs: nil, hourly_output: false)
    # Check input HPXML is valid
    xml = File.absolute_path(xml)

    # Run sample files with hourly output turned on to test hourly results against annual results
    hourly = ''
    if hourly_output
      hourly = ' --hourly ALL'
    end

    rundir = File.join(@test_files_dir, test_name, File.basename(xml))

    # Run energy_rating_index workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" \"#{File.join(File.dirname(__FILE__), '../energy_rating_index.rb')}\" -x #{xml}#{hourly} -o #{rundir}"
    start_time = Time.now
    system(command)
    runtime = (Time.now - start_time).round(2)

    using_iaf = false
    File.open(xml, 'r').each do |line|
      next unless line.strip.downcase.start_with? '<version>'

      if line.include?('latest') || line.include?('2014ADE')
        using_iaf = true
      end
      break
    end

    hpxmls = {}
    hpxmls[:ref] = File.join(rundir, 'results', 'ERIReferenceHome.xml')
    hpxmls[:rated] = File.join(rundir, 'results', 'ERIRatedHome.xml')
    csvs = {}
    csvs[:eri_results] = File.join(rundir, 'results', 'ERI_Results.csv')
    csvs[:eri_worksheet] = File.join(rundir, 'results', 'ERI_Worksheet.csv')
    csvs[:rated_results] = File.join(rundir, 'results', 'ERIRatedHome.csv')
    csvs[:ref_results] = File.join(rundir, 'results', 'ERIReferenceHome.csv')
    if using_iaf
      csvs[:iad_results] = File.join(rundir, 'results', 'ERIIndexAdjustmentDesign.csv')
      csvs[:iadref_results] = File.join(rundir, 'results', 'ERIIndexAdjustmentReferenceHome.csv')
    end
    if expect_error
      if expect_error_msgs.nil?
        flunk "No error message defined for #{File.basename(xml)}."
      else
        found_error_msg = false
        ['ERIRatedHome', 'ERIReferenceHome', 'ERIIndexAdjustmentDesign', 'ERIIndexAdjustmentReferenceHome'].each do |design|
          next unless File.exist? File.join(rundir, design, 'run.log')

          run_log = File.readlines(File.join(rundir, design, 'run.log')).map(&:strip)
          expect_error_msgs.each do |error_msg|
            run_log.each do |run_line|
              next unless run_line.include? error_msg

              found_error_msg = true
              break
            end
          end
        end
        assert(found_error_msg)
      end
    else
      # Check all output files exist
      hpxmls.keys.each do |k|
        assert(File.exist?(hpxmls[k]))
      end
      csvs.keys.each do |k|
        assert(File.exist?(csvs[k]))
      end

      # Check HPXMLs are valid
      _test_schema_validation(xml)
      hpxmls.keys.each do |k|
        _test_schema_validation(hpxmls[k])
      end
    end

    # Clean up
    ['ERIRatedHome', 'ERIReferenceHome', 'ERIIndexAdjustmentDesign', 'ERIIndexAdjustmentReferenceHome'].each do |design|
      in_epw = File.join(rundir, design, 'in.epw')
      File.delete(in_epw) if File.exist? in_epw
    end

    return hpxmls, csvs, runtime
  end

  def _run_simulation(xml, test_name, request_dse_outputs = false)
    puts "Running #{xml}..."

    xml = File.absolute_path(xml)

    rundir = File.join(@test_files_dir, test_name, File.basename(xml))
    _rm_path(rundir)
    FileUtils.mkdir_p(rundir)

    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures_dir = File.join(File.dirname(__FILE__), '../..')

    measures = {}

    # Add HPXML translator measure to workflow
    measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
    args = {}
    if File.exist? File.absolute_path(File.join(File.dirname(xml), 'weather'))
      args['weather_dir'] = File.absolute_path(File.join(File.dirname(xml), 'weather'))
    else
      args['weather_dir'] = 'weather'
    end
    args['output_dir'] = File.absolute_path(rundir)
    args['hpxml_path'] = xml
    update_args_hash(measures, measure_subdir, args)

    # Add reporting measure to workflow
    measure_subdir = 'hpxml-measures/SimulationOutputReport'
    args = {}
    args['timeseries_frequency'] = 'none'
    args['include_timeseries_fuel_consumptions'] = false
    args['include_timeseries_end_use_consumptions'] = false
    args['include_timeseries_hot_water_uses'] = false
    args['include_timeseries_total_loads'] = false
    args['include_timeseries_component_loads'] = false
    args['include_timeseries_zone_temperatures'] = false
    args['include_timeseries_airflows'] = false
    args['include_timeseries_weather'] = false
    update_args_hash(measures, measure_subdir, args)

    # Apply measure
    success = apply_measures(measures_dir, measures, runner, model, true, 'OpenStudio::Measure::ModelMeasure')

    # Report warnings/errors
    File.open(File.join(rundir, 'run.log'), 'w') do |f|
      runner.result.stepWarnings.each do |s|
        f << "Warning: #{s}\n"
      end
      runner.result.stepErrors.each do |s|
        f << "Error: #{s}\n"
      end
    end
    assert(success)

    if request_dse_outputs
      # TODO: Remove this code someday when we no longer need to adjust ASHRAE 152 space temperatures
      #       based on EnergyPlus hourly outputs for DSE tests.
      #       When this happens, we can just call _run_simulation.rb instead.

      # Thermal zone temperatures
      output_var = OpenStudio::Model::OutputVariable.new('Zone Mean Air Temperature', model)
      output_var.setReportingFrequency('hourly')
      output_var.setKeyValue('*')

      # Fan runtime fraction
      output_var = OpenStudio::Model::OutputVariable.new('Fan Runtime Fraction', model)
      output_var.setReportingFrequency('hourly')
      output_var.setKeyValue('*')

      # Heating season?
      output_meter = OpenStudio::Model::OutputMeter.new(model)
      output_meter.setName('Heating:EnergyTransfer')
      output_meter.setReportingFrequency('hourly')

      # Cooling season?
      output_meter = OpenStudio::Model::OutputMeter.new(model)
      output_meter.setName('Cooling:EnergyTransfer')
      output_meter.setReportingFrequency('hourly')
    end

    # Translate model to IDF
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    forward_translator.setExcludeLCCObjects(true)
    model_idf = forward_translator.translateModel(model)

    # Apply reporting measure output requests
    apply_energyplus_output_requests(measures_dir, measures, runner, model, model_idf)

    # Write IDF
    File.open(File.join(rundir, 'in.idf'), 'w') { |f| f << model_idf.to_s }

    # Run EnergyPlus
    ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
    command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
    start_time = Time.now
    system(command, err: File::NULL)
    sim_time = (Time.now - start_time).round(1)
    puts "Completed #{File.basename(xml)} simulation in #{sim_time}s."

    sql_path = File.join(rundir, 'eplusout.sql')
    assert(File.exist?(sql_path))

    # Apply reporting measures
    runner.setLastEnergyPlusSqlFilePath(sql_path)
    success = apply_measures(measures_dir, measures, runner, model, true, 'OpenStudio::Measure::ReportingMeasure')
    File.open(File.join(rundir, 'run.log'), 'a') do |f|
      runner.result.stepWarnings.each do |s|
        f << "Warning: #{s}\n"
      end
      runner.result.stepErrors.each do |s|
        f << "Error: #{s}\n"
      end
    end
    assert(success)

    csv_path = File.join(rundir, 'results_annual.csv')
    assert(File.exist?(csv_path))

    # Clean up
    in_epw = File.join(rundir, 'in.epw')
    File.delete(in_epw) if File.exist? in_epw

    return sql_path, csv_path, sim_time
  end

  def _test_reul(all_results, files_include, result_name)
    base_results = all_results['base.xml']
    return if base_results.nil?

    base_reul = base_results[result_name]
    all_results.each do |compare_xml, compare_results|
      next unless compare_xml.include? files_include

      if compare_results[result_name].to_s.include? ','
        compare_reul = compare_results[result_name].split(',').map(&:to_f).inject(0, :+) # sum values
      else
        compare_reul = compare_results[result_name]
      end

      assert_in_delta(base_reul, compare_reul, 0.15)
    end
  end

  def _get_simulation_load_results(csv_path)
    results = _get_csv_results(csv_path)
    htg_load = results['Load: Heating (MBtu)'].round(2)
    clg_load = results['Load: Cooling (MBtu)'].round(2)

    assert_operator(htg_load, :>, 0)
    assert_operator(clg_load, :>, 0)

    return htg_load, clg_load
  end

  def _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
    results = _get_csv_results(csv_path)
    if not is_heat
      hvac = UnitConversions.convert(results['Electricity: Cooling (MBtu)'], 'MBtu', 'kwh').round(2)
      hvac_fan = UnitConversions.convert(results['Electricity: Cooling Fans/Pumps (MBtu)'], 'MBtu', 'kwh').round(2)
    else
      if is_electric_heat
        hvac = UnitConversions.convert(results['Electricity: Heating (MBtu)'], 'MBtu', 'kwh').round(2)
      else
        hvac = UnitConversions.convert(results['Natural Gas: Heating (MBtu)'], 'MBtu', 'therm').round(2)
      end
      hvac_fan = UnitConversions.convert(results['Electricity: Heating Fans/Pumps (MBtu)'], 'MBtu', 'kwh').round(2)
    end

    assert_operator(hvac, :>, 0)
    assert_operator(hvac_fan, :>, 0)

    return hvac.round(2), hvac_fan.round(2)
  end

  def _calc_dse(xml, sql_path)
    xml = File.basename(xml)

    if ['HVAC3a.xml', 'HVAC3e.xml'].include? xml
      return
    end

    if ['HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? xml
      is_heating = true
    elsif ['HVAC3f.xml', 'HVAC3g.xml', 'HVAC3h.xml'].include? xml
      is_cooling = true
    else
      fail "Unexpected DSE test file: #{xml}"
    end

    # Read hourly outputs
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)
    if is_heating
      zone_name = HPXML::LocationBasementUnconditioned.upcase
      mode = 'Heating'
    elsif is_cooling
      zone_name = HPXML::LocationAtticVented.upcase
      mode = 'Cooling'
    end
    query = "SELECT (VariableValue*9.0/5.0)+32.0 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Zone Mean Air Temperature' AND KeyValue='#{zone_name}' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    temperatures = sqlFile.execAndReturnVectorOfDouble(query).get
    query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='#{mode}:EnergyTransfer' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    loads = sqlFile.execAndReturnVectorOfDouble(query).get
    query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Fan Runtime Fraction' AND ReportingFrequency='Hourly') ORDER BY TimeIndex"
    rtfs = sqlFile.execAndReturnVectorOfDouble(query).get
    sqlFile.close

    # Calculate seasonal average duct zone temperature
    sum_seasonal_temps_x_rtfs = 0.0
    sum_rtfs = 0.0
    for i in 1..8760
      next unless loads[i - 1] > 0

      sum_seasonal_temps_x_rtfs += (temperatures[i - 1] * rtfs[i - 1])
      sum_rtfs += rtfs[i - 1]
    end
    seasonal_temp = sum_seasonal_temps_x_rtfs / sum_rtfs

    # Calculate DSE
    air_dens = 0.075
    air_cp = 0.24

    if is_heating
      dse_Qs = { 'HVAC3b.xml' => 0.0, 'HVAC3c.xml' => 0.0, 'HVAC3d.xml' => 125.0 }[xml]
      dse_Qr = dse_Qs
      capacity = { 'HVAC3b.xml' => 56000.0, 'HVAC3c.xml' => 49000.0, 'HVAC3d.xml' => 61000.0 }[xml]
      cfm = 30.0 * capacity / 1000.0
      dse_Tamb_s = seasonal_temp
      dse_Tamb_r = dse_Tamb_s
      dse_As = 308.0
      dse_Ar = 77.0
      t_setpoint = 68.0
      dse_Fregain_s = 0.1
      dse_Fregain_r = dse_Fregain_s
      supply_r = { 'HVAC3b.xml' => 1.5, 'HVAC3c.xml' => 7.0, 'HVAC3d.xml' => 7.0 }[xml]
      return_r = supply_r

      de = HVACSizing.calc_delivery_effectiveness_heating(dse_Qs, dse_Qr, cfm, capacity, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Fregain_s, dse_Fregain_r, supply_r, return_r, air_dens, air_cp)

      f_load_s = 0.999
      f_equip_s = 1.0
      f_cycloss = 0.02
    elsif is_cooling
      dse_Qs = { 'HVAC3f.xml' => 0.0, 'HVAC3g.xml' => 0.0, 'HVAC3h.xml' => 125.0 }[xml]
      dse_Qr = dse_Qs
      capacity = { 'HVAC3f.xml' => 49900.0, 'HVAC3g.xml' => 42200.0, 'HVAC3h.xml' => 55000.0 }[xml]
      load_total = capacity
      cfm = 30.0 * capacity / 1000.0
      dse_Tamb_s = seasonal_temp
      dse_Tamb_r = dse_Tamb_s
      dse_As = 308.0
      dse_Ar = 77.0
      t_setpoint = 78.0
      dse_Fregain_s = 0.1
      dse_Fregain_r = dse_Fregain_s
      supply_r = { 'HVAC3f.xml' => 1.5, 'HVAC3g.xml' => 7.0, 'HVAC3h.xml' => 7.0 }[xml]
      return_r = supply_r
      lat = 55.0
      dse_h_r = 30.9
      h_in = 25.0

      de = HVACSizing.calc_delivery_effectiveness_cooling(dse_Qs, dse_Qr, lat, cfm, capacity, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Fregain_s, dse_Fregain_r, load_total, dse_h_r, supply_r, return_r, air_dens, air_cp, h_in)[0]

      f_load_s = 0.999
      f_equip_s = 0.965315315
      f_cycloss = 0.02
    end

    dse = de * f_equip_s * f_load_s * (1.0 - f_cycloss)

    # Calculate new test criteria based on this DSE
    percent_avg = ((1.0 - 1.0 / dse).abs * 100.0).round(1)
    percent_min = percent_avg - 5.0
    percent_max = percent_avg + 5.0

    return dse.round(3), seasonal_temp.round(1), percent_min.round(1), percent_max.round(1)
  end

  def _test_schema_validation(xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources'))
    hpxml_doc = XMLHelper.parse_file(xml)
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      puts "#{xml}: #{errors}"
    end
    assert_equal(0, errors.size)
  end

  def _check_ashrae_140_results(htg_loads, clg_loads)
    # Annual Heating Loads
    assert_operator(htg_loads['L100AC'], :<=, 79.48)
    assert_operator(htg_loads['L100AC'], :>=, 45.28)
    assert_operator(htg_loads['L110AC'], :<=, 103.99)
    assert_operator(htg_loads['L110AC'], :>=, 71.51)
    assert_operator(htg_loads['L120AC'], :<=, 64.30)
    assert_operator(htg_loads['L120AC'], :>=, 33.76)
    assert_operator(htg_loads['L130AC'], :<=, 53.98)
    assert_operator(htg_loads['L130AC'], :>=, 37.75)
    assert_operator(htg_loads['L140AC'], :<=, 56.48)
    assert_operator(htg_loads['L140AC'], :>=, 43.24)
    assert_operator(htg_loads['L150AC'], :<=, 71.33)
    assert_operator(htg_loads['L150AC'], :>=, 35.50)
    assert_operator(htg_loads['L155AC'], :<=, 74.18)
    assert_operator(htg_loads['L155AC'], :>=, 39.17)
    assert_operator(htg_loads['L160AC'], :<=, 81.00)
    assert_operator(htg_loads['L160AC'], :>=, 45.63)
    assert_operator(htg_loads['L170AC'], :<=, 92.40)
    assert_operator(htg_loads['L170AC'], :>=, 54.16)
    assert_operator(htg_loads['L200AC'], :<=, 185.87)
    assert_operator(htg_loads['L200AC'], :>=, 106.41)
    assert_operator(htg_loads['L202AC'], :<=, 190.05)
    assert_operator(htg_loads['L202AC'], :>=, 111.32)
    assert_operator(htg_loads['L302XC'], :<=, 90.52)
    assert_operator(htg_loads['L302XC'], :>=, 14.52)
    assert_operator(htg_loads['L304XC'], :<=, 75.32)
    assert_operator(htg_loads['L304XC'], :>=, 18.84)
    assert_operator(htg_loads['L322XC'], :<=, 118.20)
    assert_operator(htg_loads['L322XC'], :>=, 16.79)
    assert_operator(htg_loads['L324XC'], :<=, 80.04)
    assert_operator(htg_loads['L324XC'], :>=, 30.50)

    # Annual Heating Load Deltas
    assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :<=, 28.12)
    assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :>=, 18.66)
    assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :<=, -7.67)
    assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :>=, -18.57)
    # assert_operator(htg_loads['L130AC']-htg_loads['L100AC'], :<=, -5.68) # FIXME: Uncomment when E+ window simple model bugfix is available
    assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :>=, -27.50)
    assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :<=, 1.86)
    assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :>=, -24.42)
    assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :<=, -3.02)
    assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :>=, -12.53)
    assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :<=, 6.88)
    assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :>=, -1.54)
    assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :<=, 5.10)
    assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :>=, -3.72)
    assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :<=, 17.64)
    assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :>=, 7.12)
    assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :<=, 107.66)
    assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :>=, 56.39)
    assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :<=, 11.10)
    assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :>=, -0.51)
    assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :<=, 14.50)
    assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :>=, -31.96)
    assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :<=, 17.75)
    assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :>=, -4.60)
    assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :<=, 39.29)
    assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :>=, -31.30)
    assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :<=, 38.27)
    assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :>=, -14.25)

    # Annual Cooling Loads
    assert_operator(clg_loads['L100AL'], :<=, 64.88)
    assert_operator(clg_loads['L100AL'], :>=, 39.53)
    assert_operator(clg_loads['L110AL'], :<=, 68.50)
    assert_operator(clg_loads['L110AL'], :>=, 43.86)
    assert_operator(clg_loads['L120AL'], :<=, 60.14)
    assert_operator(clg_loads['L120AL'], :>=, 38.08)
    assert_operator(clg_loads['L130AL'], :<=, 45.26)
    assert_operator(clg_loads['L130AL'], :>=, 29.19)
    assert_operator(clg_loads['L140AL'], :<=, 30.54)
    assert_operator(clg_loads['L140AL'], :>=, 19.44)
    assert_operator(clg_loads['L150AL'], :<=, 82.33)
    assert_operator(clg_loads['L150AL'], :>=, 48.53)
    assert_operator(clg_loads['L155AL'], :<=, 63.06)
    assert_operator(clg_loads['L155AL'], :>=, 33.19)
    assert_operator(clg_loads['L160AL'], :<=, 72.99)
    assert_operator(clg_loads['L160AL'], :>=, 49.62)
    assert_operator(clg_loads['L170AL'], :<=, 53.31)
    assert_operator(clg_loads['L170AL'], :>=, 32.00)
    assert_operator(clg_loads['L200AL'], :<=, 83.43)
    assert_operator(clg_loads['L200AL'], :>=, 52.49)
    assert_operator(clg_loads['L202AL'], :<=, 75.96)
    assert_operator(clg_loads['L202AL'], :>=, 44.99)

    # Annual Cooling Load Deltas
    assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :<=, 7.84)
    assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :>=, -0.98)
    assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :<=, 0.68)
    assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :>=, -8.67)
    assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :<=, -9.53)
    assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :>=, -24.40)
    assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :<=, -19.76)
    assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :>=, -38.68)
    assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :<=, 20.55)
    assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :>=, 8.72)
    assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :<=, -9.64)
    assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :>=, -22.29)
    assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :<=, 12.58)
    assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :>=, 3.88)
    assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :<=, -4.83)
    assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :>=, -15.74)
    assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :<=, 21.39)
    assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :>=, 6.63)
    assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :<=, 14.86)
    assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :>=, 2.03)
  end

  def _get_reference_home_components(hpxml, test_num)
    results = {}
    hpxml = HPXML.new(hpxml_path: hpxml)

    # Above-grade walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml)
    results['Above-grade walls (Uo)'] = wall_u
    results['Above-grade wall solar absorptance (α)'] = wall_solar_abs
    results['Above-grade wall infrared emittance (ε)'] = wall_emiss

    # Basement walls
    bsmt_wall_u = _get_basement_walls(hpxml)
    if test_num == 4
      results['Basement walls (Uo)'] = bsmt_wall_u
    else
      results['Basement walls (Uo)'] = 'n/a'
    end

    # Above-grade floors
    floors_u = _get_above_grade_floors(hpxml)
    if test_num <= 2
      results['Above-grade floors (Uo)'] = floors_u
    else
      results['Above-grade floors (Uo)'] = 'n/a'
    end

    # Slab insulation
    slab_r, carpet_r, exp_mas_floor_area = _get_hpxml_slabs(hpxml)
    if test_num >= 3
      results['Slab insulation R-Value'] = slab_r
    else
      results['Slab insulation R-Value'] = 'n/a'
    end

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml)
    results['Ceilings (Uo)'] = ceil_u

    # Roofs
    roof_solar_abs, roof_emiss, roof_area = _get_roofs(hpxml)
    results['Roof solar absorptance (α)'] = roof_solar_abs
    results['Roof infrared emittance (ε)'] = roof_emiss

    # Attic vent area
    attic_vent_area = _get_attic_vent_area(hpxml)
    results['Attic vent area (ft2)'] = attic_vent_area

    # Crawlspace vent area
    crawl_vent_area = _get_crawl_vent_area(hpxml)
    if test_num == 2
      results['Crawlspace vent area (ft2)'] = crawl_vent_area
    else
      results['Crawlspace vent area (ft2)'] = 'n/a'
    end

    # Slabs
    if test_num >= 3
      results['Exposed masonry floor area (ft2)'] = exp_mas_floor_area
      results['Carpet & pad R-Value'] = carpet_r
    else
      results['Exposed masonry floor area (ft2)'] = 'n/a'
      results['Carpet & pad R-Value'] = 'n/a'
    end

    # Doors
    door_u, door_area = _get_doors(hpxml)
    results['Door Area (ft2)'] = door_area
    results['Door U-Factor'] = door_u

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
    results['North window area (ft2)'] = win_areas[0].round(2)
    results['South window area (ft2)'] = win_areas[180].round(2)
    results['East window area (ft2)'] = win_areas[90].round(2)
    results['West window area (ft2)'] = win_areas[270].round(2)
    results['Window U-Factor'] = win_u
    results['Window SHGCo (heating)'] = win_shgc_htg
    results['Window SHGCo (cooling)'] = win_shgc_clg

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml)
    results['SLAo (ft2/ft2)'] = sla.round(5)

    # Internal gains
    xml_it_sens, xml_it_lat = _get_internal_gains(hpxml)
    results['Sensible Internal gains (Btu/day)'] = xml_it_sens.round(0)
    results['Latent Internal gains (Btu/day)'] = xml_it_lat.round(0)

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml)
    if (test_num == 1) || (test_num == 4)
      results['Labeled heating system rating and efficiency'] = afue
    else
      results['Labeled heating system rating and efficiency'] = hspf
    end
    results['Labeled cooling system rating and efficiency'] = seer
    results['Air Distribution System Efficiency'] = dse

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml)
    results['Thermostat Type'] = tstat
    results['Heating thermostat settings'] = htg_sp
    results['Cooling thermostat settings'] = clg_sp

    # Mechanical ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml)
    results['Mechanical ventilation (kWh/y)'] = mv_kwh.round(2)

    # Domestic hot water
    ref_pipe_l, ref_loop_l = _get_dhw(hpxml)
    results['DHW pipe length refPipeL'] = ref_pipe_l.round(1)
    results['DHW loop length refLoopL'] = ref_loop_l.round(1)

    return results
  end

  def _get_iad_home_components(hpxml, test_num)
    results = {}
    hpxml = HPXML.new(hpxml_path: hpxml)

    # Geometry
    results['Number of Stories'] = hpxml.building_construction.number_of_conditioned_floors
    results['Number of Bedrooms'] = hpxml.building_construction.number_of_bedrooms
    results['Conditioned Floor Area (ft2)'] = hpxml.building_construction.conditioned_floor_area
    results['Infiltration Volume (ft3)'] = hpxml.air_infiltration_measurements[0].infiltration_volume

    # Above-grade Walls
    wall_u, wall_solar_abs, wall_emiss, wall_area = _get_above_grade_walls(hpxml)
    results['Above-grade walls area (ft2)'] = wall_area
    results['Above-grade walls (Uo)'] = wall_u

    # Roof
    roof_solar_abs, roof_emiss, roof_area = _get_roofs(hpxml)
    results['Roof gross area (ft2)'] = roof_area

    # Ceilings
    ceil_u, ceil_area = _get_ceilings(hpxml)
    results['Ceiling gross projected footprint area (ft2)'] = ceil_area
    results['Ceilings (Uo)'] = ceil_u

    # Crawlspace
    crawl_vent_area = _get_crawl_vent_area(hpxml)
    results['Crawlspace vent area (ft2)'] = crawl_vent_area

    # Doors
    door_u, door_area = _get_doors(hpxml)
    results['Door Area (ft2)'] = door_area
    results['Door R-value'] = 1.0 / door_u

    # Windows
    win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
    results['North window area (ft2)'] = win_areas[0]
    results['South window area (ft2)'] = win_areas[180]
    results['East window area (ft2)'] = win_areas[90]
    results['West window area (ft2)'] = win_areas[270]
    results['Window U-Factor'] = win_u
    results['Window SHGCo (heating)'] = win_shgc_htg
    results['Window SHGCo (cooling)'] = win_shgc_clg

    # Infiltration
    sla, ach50 = _get_infiltration(hpxml)
    results['Infiltration rate (ACH50)'] = ach50

    # Mechanical Ventilation
    mv_kwh, mv_cfm = _get_mech_vent(hpxml)
    results['Mechanical ventilation rate'] = mv_cfm
    results['Mechanical ventilation'] = mv_kwh

    # HVAC
    afue, hspf, seer, dse = _get_hvac(hpxml)
    if (test_num == 1) || (test_num == 4)
      results['Labeled heating system rating and efficiency'] = afue
    else
      results['Labeled heating system rating and efficiency'] = hspf
    end
    results['Labeled cooling system rating and efficiency'] = seer

    # Thermostat
    tstat, htg_sp, htg_setback, clg_sp, clg_setup = _get_tstat(hpxml)
    results['Thermostat Type'] = tstat
    results['Heating thermostat settings'] = htg_sp
    results['Cooling thermostat settings'] = clg_sp

    return results
  end

  def _check_reference_home_components(results, test_num, version)
    # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 - 4

    epsilon = 0.0005 # 0.05%

    # Above-grade walls
    if test_num <= 3
      assert_in_delta(0.082, results['Above-grade walls (Uo)'], 0.001)
    else
      assert_in_delta(0.060, results['Above-grade walls (Uo)'], 0.001)
    end
    assert_equal(0.75, results['Above-grade wall solar absorptance (α)'])
    assert_equal(0.90, results['Above-grade wall infrared emittance (ε)'])

    # Basement walls
    if test_num == 4
      assert_in_delta(0.059, results['Basement walls (Uo)'], 0.001)
    end

    # Above-grade floors
    if test_num <= 2
      assert_in_delta(0.047, results['Above-grade floors (Uo)'], 0.001)
    end

    # Slab insulation
    if test_num >= 3
      assert_equal(0, results['Slab insulation R-Value'])
    end

    # Ceilings
    if (test_num == 1) || (test_num == 4)
      assert_in_delta(0.030, results['Ceilings (Uo)'], 0.001)
    else
      assert_in_delta(0.035, results['Ceilings (Uo)'], 0.001)
    end

    # Roofs
    assert_equal(0.75, results['Roof solar absorptance (α)'])
    assert_equal(0.90, results['Roof infrared emittance (ε)'])

    # Attic vent area
    assert_in_epsilon(5.13, results['Attic vent area (ft2)'], epsilon)

    # Crawlspace vent area
    if test_num == 2
      assert_in_epsilon(10.26, results['Crawlspace vent area (ft2)'], epsilon)
    end

    # Slabs
    if test_num >= 3
      assert_in_epsilon(307.8, results['Exposed masonry floor area (ft2)'], epsilon)
      assert_equal(2.0, results['Carpet & pad R-Value'])
    end

    # Doors
    assert_equal(40, results['Door Area (ft2)'])
    if test_num == 1
      assert_in_delta(0.40, results['Door U-Factor'], 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, results['Door U-Factor'], 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, results['Door U-Factor'], 0.01)
    else
      assert_in_delta(0.35, results['Door U-Factor'], 0.01)
    end

    # Windows
    if test_num <= 3
      assert_in_epsilon(69.26, results['North window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['South window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['East window area (ft2)'], epsilon)
      assert_in_epsilon(69.26, results['West window area (ft2)'], epsilon)
    else
      assert_in_epsilon(102.63, results['North window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['South window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['East window area (ft2)'], epsilon)
      assert_in_epsilon(102.63, results['West window area (ft2)'], epsilon)
    end
    if test_num == 1
      assert_in_delta(0.40, results['Window U-Factor'], 0.01)
    elsif test_num == 2
      assert_in_delta(0.65, results['Window U-Factor'], 0.01)
    elsif test_num == 3
      assert_in_delta(1.20, results['Window U-Factor'], 0.01)
    else
      assert_in_delta(0.35, results['Window U-Factor'], 0.01)
    end
    assert_in_delta(0.34, results['Window SHGCo (heating)'], 0.01)
    assert_in_delta(0.28, results['Window SHGCo (cooling)'], 0.01)

    # Infiltration
    assert_in_delta(0.00036, results['SLAo (ft2/ft2)'], 0.00001)

    # Internal gains
    if version == '2019A'
      if test_num == 1
        assert_in_epsilon(55115, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(13666, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 2
        assert_in_epsilon(52470, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(12568, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 3
        assert_in_epsilon(47839, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(9152, results['Latent Internal gains (Btu/day)'], epsilon)
      else
        assert_in_epsilon(82691, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(17769, results['Latent Internal gains (Btu/day)'], epsilon)
      end
    else
      if test_num == 1
        assert_in_epsilon(55470, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(13807, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 2
        assert_in_epsilon(52794, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(12698, results['Latent Internal gains (Btu/day)'], epsilon)
      elsif test_num == 3
        assert_in_epsilon(48111, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(9259, results['Latent Internal gains (Btu/day)'], epsilon)
      else
        assert_in_epsilon(83103, results['Sensible Internal gains (Btu/day)'], epsilon)
        assert_in_epsilon(17934, results['Latent Internal gains (Btu/day)'], epsilon)
      end
    end

    # HVAC
    if (test_num == 1) || (test_num == 4)
      assert_equal(0.78, results['Labeled heating system rating and efficiency'])
    else
      assert_equal(7.7, results['Labeled heating system rating and efficiency'])
    end
    assert_equal(13.0, results['Labeled cooling system rating and efficiency'])
    assert_equal(0.80, results['Air Distribution System Efficiency'])

    # Thermostat
    assert_equal('manual', results['Thermostat Type'])
    assert_equal(68, results['Heating thermostat settings'])
    assert_equal(78, results['Cooling thermostat settings'])

    # Mechanical ventilation
    mv_epsilon = 0.001 # 0.1%
    mv_kwh_yr = nil
    if test_num == 1
      mv_kwh_yr = 0.0
    elsif test_num == 2
      if version == '2014'
        mv_kwh_yr = 77.9
      else
        mv_kwh_yr = 222.1
      end
    elsif test_num == 3
      if version == '2014'
        mv_kwh_yr = 140.4
      else
        mv_kwh_yr = 287.8
      end
    else
      if version == '2014'
        mv_kwh_yr = 379.1
      else
        mv_kwh_yr = 762.8
      end
    end
    assert_in_epsilon(mv_kwh_yr, results['Mechanical ventilation (kWh/y)'], mv_epsilon)

    # Domestic hot water
    dhw_epsilon = 0.1 # 0.1 ft
    if test_num <= 3
      assert_in_delta(88.5, results['DHW pipe length refPipeL'], dhw_epsilon)
      assert_in_delta(156.9, results['DHW loop length refLoopL'], dhw_epsilon)
    else
      assert_in_delta(98.5, results['DHW pipe length refPipeL'], dhw_epsilon)
      assert_in_delta(176.9, results['DHW loop length refLoopL'], dhw_epsilon)
    end

    # e-Ratio
    assert_in_delta(1, results['e-Ratio'], 0.005)
  end

  def _check_iad_home_components(results, test_num)
    epsilon = 0.0005 # 0.05%

    # Geometry
    assert_equal(2, results['Number of Stories'])
    assert_equal(3, results['Number of Bedrooms'])
    assert_equal(2400, results['Conditioned Floor Area (ft2)'])
    assert_equal(20400, results['Infiltration Volume (ft3)'])

    # Above-grade Walls
    assert_in_delta(2355.52, results['Above-grade walls area (ft2)'], 0.01)
    assert_in_delta(0.085, results['Above-grade walls (Uo)'], 0.001)

    # Roof
    assert_equal(1300, results['Roof gross area (ft2)'])

    # Ceilings
    assert_equal(1200, results['Ceiling gross projected footprint area (ft2)'])
    assert_in_delta(0.054, results['Ceilings (Uo)'], 0.01)

    # Crawlspace
    assert_in_epsilon(8, results['Crawlspace vent area (ft2)'], 0.01)

    # Doors
    assert_equal(40, results['Door Area (ft2)'])
    assert_in_delta(3.04, results['Door R-value'], 0.01)

    # Windows
    assert_in_epsilon(108.00, results['North window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['South window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['East window area (ft2)'], epsilon)
    assert_in_epsilon(108.00, results['West window area (ft2)'], epsilon)
    assert_in_delta(1.039, results['Window U-Factor'], 0.01)
    assert_in_delta(0.57, results['Window SHGCo (heating)'], 0.01)
    assert_in_delta(0.47, results['Window SHGCo (cooling)'], 0.01)

    # Infiltration
    if test_num != 3
      assert_equal(3.0, results['Infiltration rate (ACH50)'])
    else
      assert_equal(5.0, results['Infiltration rate (ACH50)'])
    end

    # Mechanical Ventilation
    if test_num == 1
      assert_in_delta(66.4, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(407, results['Mechanical ventilation'], 1.0)
    elsif test_num == 2
      assert_in_delta(64.2, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(394, results['Mechanical ventilation'], 1.0)
    elsif test_num == 3
      assert_in_delta(53.3, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(327, results['Mechanical ventilation'], 1.0)
    elsif test_num == 4
      assert_in_delta(57.1, results['Mechanical ventilation rate'], 0.2)
      assert_in_delta(350, results['Mechanical ventilation'], 1.0)
    end

    # HVAC
    if (test_num == 1) || (test_num == 4)
      assert_equal(0.78, results['Labeled heating system rating and efficiency'])
    else
      assert_equal(7.7, results['Labeled heating system rating and efficiency'])
    end
    assert_equal(13.0, results['Labeled cooling system rating and efficiency'])

    # Thermostat
    assert_equal('manual', results['Thermostat Type'])
    assert_equal(68, results['Heating thermostat settings'])
    assert_equal(78, results['Cooling thermostat settings'])
  end

  def _get_above_grade_walls(hpxml)
    u_factor = solar_abs = emittance = area = num = 0.0
    hpxml.walls.each do |wall|
      next unless wall.is_exterior_thermal_boundary

      u_factor += 1.0 / wall.insulation_assembly_r_value
      solar_abs += wall.solar_absorptance
      emittance += wall.emittance
      area += wall.area
      num += 1
    end
    return u_factor / num, solar_abs / num, emittance / num, area
  end

  def _get_basement_walls(hpxml)
    u_factor = num = 0.0
    hpxml.foundation_walls.each do |foundation_wall|
      next unless foundation_wall.is_exterior_thermal_boundary

      u_factor += 1.0 / foundation_wall.insulation_assembly_r_value
      num += 1
    end
    return u_factor / num
  end

  def _get_above_grade_floors(hpxml)
    u_factor = num = 0.0
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_floor

      u_factor += 1.0 / frame_floor.insulation_assembly_r_value
      num += 1
    end
    return u_factor / num
  end

  def _get_hpxml_slabs(hpxml)
    r_value = carpet_r_value = exp_area = carpet_num = r_num = 0.0
    hpxml.slabs.each do |slab|
      exp_area += (slab.area * (1.0 - slab.carpet_fraction))
      carpet_r_value += Float(slab.carpet_r_value)
      carpet_num += 1
      r_value += slab.perimeter_insulation_r_value
      r_num += 1
      r_value += slab.under_slab_insulation_r_value
      r_num += 1
    end
    return r_value / r_num, carpet_r_value / carpet_num, exp_area
  end

  def _get_ceilings(hpxml)
    u_factor = area = num = 0.0
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_ceiling

      u_factor += 1.0 / frame_floor.insulation_assembly_r_value
      area += frame_floor.area
      num += 1
    end
    return u_factor / num, area
  end

  def _get_roofs(hpxml)
    solar_abs = emittance = area = num = 0.0
    hpxml.roofs.each do |roof|
      solar_abs += roof.solar_absorptance
      emittance += roof.emittance
      area += roof.area
      num += 1
    end
    return solar_abs / num, emittance / num, area
  end

  def _get_attic_vent_area(hpxml)
    area = sla = 0.0
    hpxml.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      sla = attic.vented_attic_sla
    end
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_ceiling && (frame_floor.exterior_adjacent_to == HPXML::LocationAtticVented)

      area += frame_floor.area
    end
    return sla * area
  end

  def _get_crawl_vent_area(hpxml)
    area = sla = 0.0
    hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      sla = foundation.vented_crawlspace_sla
    end
    hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_floor && (frame_floor.exterior_adjacent_to == HPXML::LocationCrawlspaceVented)

      area += frame_floor.area
    end
    return sla * area
  end

  def _get_doors(hpxml)
    area = u_factor = num = 0.0
    hpxml.doors.each do |door|
      area += door.area
      u_factor += 1.0 / door.r_value
      num += 1
    end
    return u_factor / num, area
  end

  def _get_windows(hpxml)
    areas = { 0 => 0.0, 90 => 0.0, 180 => 0.0, 270 => 0.0 }
    u_factor = shgc_htg = shgc_clg = num = 0.0
    hpxml.windows.each do |window|
      areas[window.azimuth] += window.area
      u_factor += window.ufactor
      shgc = window.shgc
      shading_winter = window.interior_shading_factor_winter
      shading_summer = window.interior_shading_factor_summer
      shgc_htg += (shgc * shading_winter)
      shgc_clg += (shgc * shading_summer)
      num += 1
    end
    return areas, u_factor / num, shgc_htg / num, shgc_clg / num
  end

  def _get_infiltration(hpxml)
    air_infil = hpxml.air_infiltration_measurements[0]
    ach50 = air_infil.air_leakage
    cfa = hpxml.building_construction.conditioned_floor_area
    infil_volume = air_infil.infiltration_volume
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, cfa, infil_volume)
    return sla, ach50
  end

  def _get_internal_gains(hpxml)
    s = ''
    nbeds = hpxml.building_construction.number_of_bedrooms
    cfa = hpxml.building_construction.conditioned_floor_area
    eri_version = hpxml.header.eri_calculation_version
    gfa = hpxml.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationGarage }.map { |s| s.area }.inject(0, :+)

    xml_pl_sens = 0.0
    xml_pl_lat = 0.0

    # Plug loads
    hpxml.plug_loads.each do |plug_load|
      btu = UnitConversions.convert(plug_load.kWh_per_year, 'kWh', 'Btu')
      xml_pl_sens += (plug_load.frac_sensible * btu)
      xml_pl_lat += (plug_load.frac_latent * btu)
      s += "#{xml_pl_sens} #{xml_pl_lat}\n"
    end

    xml_appl_sens = 0.0
    xml_appl_lat = 0.0

    # Appliances: CookingRange
    cooking_range = hpxml.cooking_ranges[0]
    cooking_range.usage_multiplier = 1.0 if cooking_range.usage_multiplier.nil?
    oven = hpxml.ovens[0]
    cr_annual_kwh, cr_annual_therm, cr_frac_sens, cr_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nbeds, cooking_range, oven)
    btu = UnitConversions.convert(cr_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cr_annual_therm, 'therm', 'Btu')
    xml_appl_sens += (cr_frac_sens * btu)
    xml_appl_lat += (cr_frac_lat * btu)

    # Appliances: Refrigerator
    refrigerator = hpxml.refrigerators[0]
    refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
    rf_annual_kwh, rf_frac_sens, rf_frac_lat = HotWaterAndAppliances.calc_refrigerator_energy(refrigerator)
    btu = UnitConversions.convert(rf_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (rf_frac_sens * btu)
    xml_appl_lat += (rf_frac_lat * btu)

    # Appliances: Dishwasher
    dishwasher = hpxml.dishwashers[0]
    dishwasher.usage_multiplier = 1.0 if dishwasher.usage_multiplier.nil?
    dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(eri_version, nbeds, dishwasher)
    btu = UnitConversions.convert(dw_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (dw_frac_sens * btu)
    xml_appl_lat += (dw_frac_lat * btu)

    # Appliances: ClothesWasher
    clothes_washer = hpxml.clothes_washers[0]
    clothes_washer.usage_multiplier = 1.0 if clothes_washer.usage_multiplier.nil?
    cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(eri_version, nbeds, clothes_washer)
    btu = UnitConversions.convert(cw_annual_kwh, 'kWh', 'Btu')
    xml_appl_sens += (cw_frac_sens * btu)
    xml_appl_lat += (cw_frac_lat * btu)

    # Appliances: ClothesDryer
    clothes_dryer = hpxml.clothes_dryers[0]
    clothes_dryer.usage_multiplier = 1.0 if clothes_dryer.usage_multiplier.nil?
    cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(eri_version, nbeds, clothes_dryer, clothes_washer)
    btu = UnitConversions.convert(cd_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cd_annual_therm, 'therm', 'Btu')
    xml_appl_sens += (cd_frac_sens * btu)
    xml_appl_lat += (cd_frac_lat * btu)

    s += "#{xml_appl_sens} #{xml_appl_lat}\n"

    # Water Use
    xml_water_sens, xml_water_lat = HotWaterAndAppliances.get_water_gains_sens_lat(nbeds)
    s += "#{xml_water_sens} #{xml_water_lat}\n"

    # Occupants
    xml_occ_sens = 0.0
    xml_occ_lat = 0.0
    heat_gain, hrs_per_day, frac_sens, frac_lat = Geometry.get_occupancy_default_values()
    btu = hpxml.building_occupancy.number_of_residents * heat_gain * hrs_per_day * 365.0
    xml_occ_sens += (frac_sens * btu)
    xml_occ_lat += (frac_lat * btu)
    s += "#{xml_occ_sens} #{xml_occ_lat}\n"

    # Lighting
    xml_ltg_sens = 0.0
    f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led = nil
    hpxml.lighting_groups.each do |lg|
      if (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationInterior)
        f_int_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationExterior)
        f_ext_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationGarage)
        f_grg_cfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationInterior)
        f_int_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationExterior)
        f_ext_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationGarage)
        f_grg_lfl = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationInterior)
        f_int_led = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationExterior)
        f_ext_led = lg.fraction_of_units_in_location
      elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationGarage)
        f_grg_led = lg.fraction_of_units_in_location
      end
    end
    int_kwh, ext_kwh, grg_kwh = Lighting.calc_energy(eri_version, cfa, gfa, f_int_cfl, f_ext_cfl, f_grg_cfl, f_int_lfl, f_ext_lfl, f_grg_lfl, f_int_led, f_ext_led, f_grg_led)
    xml_ltg_sens += UnitConversions.convert(int_kwh + grg_kwh, 'kWh', 'Btu')
    s += "#{xml_ltg_sens}\n"

    xml_btu_sens = (xml_pl_sens + xml_appl_sens + xml_water_sens + xml_occ_sens + xml_ltg_sens) / 365.0
    xml_btu_lat = (xml_pl_lat + xml_appl_lat + xml_water_lat + xml_occ_lat) / 365.0

    return xml_btu_sens, xml_btu_lat
  end

  def _get_hvac(hpxml)
    afue = hspf = seer = dse = num_afue = num_hspf = num_seer = num_dse = 0.0
    hpxml.heating_systems.each do |heating_system|
      afue += heating_system.heating_efficiency_afue
      num_afue += 1
    end
    hpxml.cooling_systems.each do |cooling_system|
      seer += cooling_system.cooling_efficiency_seer
      num_seer += 1
    end
    hpxml.heat_pumps.each do |heat_pump|
      if not heat_pump.heating_efficiency_hspf.nil?
        hspf += heat_pump.heating_efficiency_hspf
        num_hspf += 1
      end
      if not heat_pump.cooling_efficiency_seer.nil?
        seer += heat_pump.cooling_efficiency_seer
        num_seer += 1
      end
    end
    hpxml.hvac_distributions.each do |hvac_distribution|
      dse += hvac_distribution.annual_heating_dse
      num_dse += 1
      dse += hvac_distribution.annual_cooling_dse
      num_dse += 1
    end
    return afue / num_afue, hspf / num_hspf, seer / num_seer, dse / num_dse
  end

  def _get_tstat(hpxml)
    hvac_control = hpxml.hvac_controls[0]
    tstat = hvac_control.control_type.gsub(' thermostat', '')
    htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr = HVAC.get_default_heating_setpoint(hvac_control.control_type)
    clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr = HVAC.get_default_cooling_setpoint(hvac_control.control_type)
    return tstat, htg_sp, htg_setback_sp, clg_sp, clg_setup_sp
  end

  def _get_mech_vent(hpxml)
    mv_kwh = mv_cfm = 0.0
    hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_whole_building_ventilation

      hours = ventilation_fan.hours_in_operation
      fan_w = ventilation_fan.fan_power
      mv_kwh += fan_w * 8.76 * hours / 24.0
      mv_cfm += ventilation_fan.tested_flow_rate
    end
    return mv_kwh, mv_cfm
  end

  def _get_dhw(hpxml)
    has_uncond_bsmnt = hpxml.has_space_type(HPXML::LocationBasementUnconditioned)
    cfa = hpxml.building_construction.conditioned_floor_area
    ncfl = hpxml.building_construction.number_of_conditioned_floors
    ref_pipe_l = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    ref_loop_l = HotWaterAndAppliances.get_default_recirc_loop_length(ref_pipe_l)
    return ref_pipe_l, ref_loop_l
  end

  def _get_csv_results(csv)
    results = {}
    CSV.foreach(csv) do |row|
      next if row.nil? || (row.size < 2)

      if row[1].include? ',' # Occurs if, e.g., multiple HVAC
        results[row[0]] = row[1]
      else
        results[row[0]] = Float(row[1])
      end
    end

    return results
  end

  def _check_method_results(results, test_num, has_tankless_water_heater, version, test_loc = nil)
    using_iaf = false

    cooling_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'elec', 4 => 'elec', 5 => 'elec' }
    cooling_mepr =  { 1 => 10.00,  2 => 10.00,  3 => 10.00,  4 => 10.00,  5 => 10.00 }
    heating_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'gas',  4 => 'elec', 5 => 'gas' }
    heating_mepr =  { 1 => 6.80,   2 => 6.80,   3 => 0.78,   4 => 9.85,   5 => 0.96  }
    hotwater_fuel = { 1 => 'elec', 2 => 'gas',  3 => 'elec', 4 => 'elec', 5 => 'elec' }
    hotwater_mepr = { 1 => 0.88,   2 => 0.82,   3 => 0.88,   4 => 0.88,   5 => 0.88 }
    if version == '2019A'
      ec_x_la = { 1 => 20.45,  2 => 22.42,  3 => 21.28,  4 => 21.40,  5 => 22.42 }
    else
      ec_x_la = { 1 => 21.27,  2 => 23.33,  3 => 22.05,  4 => 22.35,  5 => 23.33 }
    end
    cfa = { 1 => 1539, 2 => 1539, 3 => 1539, 4 => 1539, 5 => 1539 }
    nbr = { 1 => 3,    2 => 3,    3 => 2,    4 => 4,    5 => 3 }
    nst = { 1 => 1,    2 => 1,    3 => 1,    4 => 1,    5 => 1 }
    using_iaf = true if version != '2014'

    if heating_fuel[test_num] == 'gas'
      heating_a = 1.0943
      heating_b = 0.403
      heating_eec_r = 1.0 / 0.78
      heating_eec_x = 1.0 / heating_mepr[test_num]
    else
      heating_a = 2.2561
      heating_b = 0.0
      heating_eec_r = 3.413 / 7.7
      heating_eec_x = 3.413 / heating_mepr[test_num]
    end

    cooling_a = 3.8090
    cooling_b = 0.0
    cooling_eec_r = 3.413 / 13.0
    cooling_eec_x = 3.413 / cooling_mepr[test_num]

    if hotwater_fuel[test_num] == 'gas'
      hotwater_a = 1.1877
      hotwater_b = 1.013
      hotwater_eec_r = 1.0 / 0.59
    else
      hotwater_a = 0.92
      hotwater_b = 0.0
      hotwater_eec_r = 1.0 / 0.92
    end
    if not has_tankless_water_heater
      hotwater_eec_x = 1.0 / hotwater_mepr[test_num]
    else
      hotwater_eec_x = 1.0 / (hotwater_mepr[test_num] * 0.92)
    end

    heating_dse_r = results['REUL Heating (MBtu)'] / results['EC_r Heating (MBtu)'] * heating_eec_r
    cooling_dse_r = results['REUL Cooling (MBtu)'] / results['EC_r Cooling (MBtu)'] * cooling_eec_r
    hotwater_dse_r = results['REUL Hot Water (MBtu)'] / results['EC_r Hot Water (MBtu)'] * hotwater_eec_r

    heating_nec_x = (heating_a * heating_eec_x - heating_b) * (results['EC_x Heating (MBtu)'] * results['EC_r Heating (MBtu)'] * heating_dse_r) / (heating_eec_x * results['REUL Heating (MBtu)'])
    cooling_nec_x = (cooling_a * cooling_eec_x - cooling_b) * (results['EC_x Cooling (MBtu)'] * results['EC_r Cooling (MBtu)'] * cooling_dse_r) / (cooling_eec_x * results['REUL Cooling (MBtu)'])
    hotwater_nec_x = (hotwater_a * hotwater_eec_x - hotwater_b) * (results['EC_x Hot Water (MBtu)'] * results['EC_r Hot Water (MBtu)'] * hotwater_dse_r) / (hotwater_eec_x * results['REUL Hot Water (MBtu)'])

    heating_nmeul = results['REUL Heating (MBtu)'] * (heating_nec_x / results['EC_r Heating (MBtu)'])
    cooling_nmeul = results['REUL Cooling (MBtu)'] * (cooling_nec_x / results['EC_r Cooling (MBtu)'])
    hotwater_nmeul = results['REUL Hot Water (MBtu)'] * (hotwater_nec_x / results['EC_r Hot Water (MBtu)'])

    if using_iaf
      iaf_cfa = ((2400.0 / cfa[test_num])**(0.304 * results['IAD_Save (%)']))
      iaf_nbr = (1.0 + (0.069 * results['IAD_Save (%)'] * (nbr[test_num] - 3.0)))
      iaf_nst = ((2.0 / nst[test_num])**(0.12 * results['IAD_Save (%)']))
      iaf_rh = iaf_cfa * iaf_nbr * iaf_nst
    end

    tnml = heating_nmeul + cooling_nmeul + hotwater_nmeul + results['EC_x L&A (MBtu)']
    trl = results['REUL Heating (MBtu)'] + results['REUL Cooling (MBtu)'] + results['REUL Hot Water (MBtu)'] + ec_x_la[test_num]

    if using_iaf
      trl_iaf = trl * iaf_rh
      eri = 100 * tnml / trl_iaf
    else
      eri = 100 * tnml / trl
    end

    assert_operator((results['ERI'] - eri).abs / results['ERI'], :<, 0.005)
  end

  def _check_hvac_test_results(xml, results, base_results)
    percent_min = nil
    percent_max = nil

    # Table 4.4.4.1(2): Air Conditioning System Acceptance Criteria
    if xml == 'HVAC1b.xml'
      percent_min = -21.2
      percent_max = -17.4
    end

    # Table 4.4.4.2(2): Gas Heating System Acceptance Criteria
    if xml == 'HVAC2b.xml'
      percent_min = -13.3
      percent_max = -11.6
    end

    # Table 4.4.4.2(4): Electric Heating System Acceptance Criteria
    if xml == 'HVAC2d.xml'
      percent_min = -29.0
      percent_max = -16.7
    elsif xml == 'HVAC2e.xml'
      percent_min = 41.8
      percent_max = 80.8
    end

    if xml == 'HVAC2b.xml'
      curr_val = results[0] / 10.0 + results[1] / 293.0
      base_val = base_results[0] / 10.0 + base_results[1] / 293.0
    else
      curr_val = results[0] + results[1]
      base_val = base_results[0] + base_results[1]
    end

    percent_change = (curr_val - base_val) / base_val * 100.0

    # FIXME: Test checks currently disabled
    # assert_operator(percent_change, :>=, percent_min)
    # assert_operator(percent_change, :<=, percent_max)
  end

  def _check_dse_test_results(xml, results)
    # Table 4.5.3(2): Heating Energy DSE Comparison Test Acceptance Criteria
    # if xml == 'HVAC3b.xml'
    #  percent_min = 21.4
    #  percent_max = 31.4
    # elsif xml == 'HVAC3c.xml'
    #  percent_min = 2.5
    #  percent_max = 12.5
    # elsif xml == 'HVAC3d.xml'
    #  percent_min = 15.0
    #  percent_max = 25.0
    # end

    # Table 4.5.4(2): Cooling Energy DSE Comparison Test Acceptance Criteria
    # if xml == 'HVAC3f.xml'
    #  percent_min = 26.2
    #  percent_max = 36.2
    # elsif xml == 'HVAC3g.xml'
    #  percent_min = 6.5
    #  percent_max = 16.5
    # elsif xml == 'HVAC3h.xml'
    #  percent_min = 21.1
    #  percent_max = 31.1
    # end

    # Test criteria calculated using EnergyPlus seasonal duct zone temperatures
    # via ASHRAE 152 spreadsheet calculations.
    percent_min = results[4]
    percent_max = results[5]

    percent_change = results[6]

    assert_operator(percent_change, :>, percent_min)
    assert_operator(percent_change, :<, percent_max)
  end

  def _get_hot_water(results_csv)
    rated_dhw = nil
    rated_recirc = nil
    rated_gpd = 0
    CSV.foreach(results_csv) do |row|
      next if row.nil? || row[0].nil?
      if ['Electricity: Hot Water (MBtu)', 'Natural Gas: Hot Water (MBtu)'].include? row[0]
        rated_dhw = Float(row[1])
      elsif row[0] == 'Electricity: Hot Water Recirc Pump (MBtu)'
        rated_recirc = Float(row[1])
      elsif row[0].start_with?('Hot Water:') && row[0].include?('(gal)')
        rated_gpd += (Float(row[1]) / 365.0)
      end
    end
    return rated_dhw, rated_recirc, rated_gpd
  end

  def _check_hot_water(test_num, curr_val, base_val = nil, mn_val = nil)
    # Table 4.6.2(1): Acceptance Criteria for Hot Water Tests
    if test_num == 1
      min_max_abs = [19.34, 19.88]
    elsif test_num == 2
      min_max_abs = [25.76, 26.55]
      min_max_base_delta_percent = [-33.92, -32.59]
    elsif test_num == 3
      min_max_abs = [17.27, 17.65]
      min_max_base_delta_percent = [10.60, 11.49]
    elsif test_num == 4
      min_max_abs = [24.94, 25.71]
      min_max_base_delta_percent = [3.13, 3.22]
    elsif test_num == 5
      min_max_abs = [55.93, 57.58]
      min_max_base_delta_percent = [-118.39, -115.70]
    elsif test_num == 6
      min_max_abs = [22.61, 23.28]
      min_max_base_delta_percent = [12.08, 12.46]
    elsif test_num == 7
      min_max_abs = [20.51, 21.09]
      min_max_base_delta_percent = [20.14, 20.78]
    elsif test_num == 8
      min_max_abs = [10.87, 11.12]
      min_max_mn_delta_percent = [43.21, 44.60]
    elsif test_num == 9
      min_max_abs = [13.47, 13.79]
      min_max_base_delta_percent = [-24.44, -23.47]
      min_max_mn_delta_percent = [47.18, 48.56]
    elsif test_num == 10
      min_max_abs = [8.94, 9.20]
      min_max_base_delta_percent = [16.99, 18.01]
      min_max_mn_delta_percent = [47.28, 48.70]
    elsif test_num == 11
      min_max_abs = [13.15, 13.46]
      min_max_base_delta_percent = [2.30, 2.37]
      min_max_mn_delta_percent = [46.73, 48.12]
    elsif test_num == 12
      min_max_abs = [30.84, 31.55]
      min_max_base_delta_percent = [-130.29, -127.53]
      min_max_mn_delta_percent = [44.35, 45.67]
    elsif test_num == 13
      min_max_abs = [12.19, 12.48]
      min_max_base_delta_percent = [9.30, 9.57]
      min_max_mn_delta_percent = [45.51, 46.85]
    elsif test_num == 14
      min_max_abs = [11.95, 12.23]
      min_max_base_delta_percent = [11.12, 11.39]
      min_max_mn_delta_percent = [41.23, 42.42]
    else
      fail 'Unexpected test.'
    end

    base_delta_percent = nil
    mn_delta_percent = nil
    if (not min_max_base_delta_percent.nil?) && (not base_val.nil?)
      base_delta_percent = (base_val - curr_val) / base_val * 100.0 # %
    end
    if (not min_max_mn_delta_percent.nil?) && (not mn_val.nil?)
      mn_delta_percent = (mn_val - curr_val) / mn_val * 100.0 # %
    end

    assert_operator(curr_val, :>=, min_max_abs[0])
    assert_operator(curr_val, :<=, min_max_abs[1])
    if not base_delta_percent.nil?
      assert_operator(base_delta_percent, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta_percent, :<=, min_max_base_delta_percent[1])
    end
    if not mn_delta_percent.nil?
      assert_operator(mn_delta_percent, :>=, min_max_mn_delta_percent[0])
      assert_operator(mn_delta_percent, :<=, min_max_mn_delta_percent[1])
    end
  end

  def _check_hot_water_301_2019_pre_addendum_a(test_num, curr_val, base_val = nil, mn_val = nil)
    # Table 4.6.2(1): Acceptance Criteria for Hot Water Tests
    if test_num == 1
      min_max_abs = [19.11, 19.73]
    elsif test_num == 2
      min_max_abs = [25.54, 26.36]
      min_max_base_delta_percent = [-34.01, -32.49]
    elsif test_num == 3
      min_max_abs = [17.03, 17.50]
      min_max_base_delta_percent = [10.74, 11.57]
    elsif test_num == 4
      min_max_abs = [24.75, 25.52]
      min_max_base_delta_percent = [3.06, 3.22]
    elsif test_num == 5
      min_max_abs = [55.43, 57.15]
      min_max_base_delta_percent = [-118.52, -115.63]
    elsif test_num == 6
      min_max_abs = [22.39, 23.09]
      min_max_base_delta_percent = [12.17, 12.51]
    elsif test_num == 7
      min_max_abs = [20.29, 20.94]
      min_max_base_delta_percent = [20.15, 20.78]
    elsif test_num == 8
      min_max_abs = [10.59, 11.03]
      min_max_mn_delta_percent = [43.35, 45.00]
    elsif test_num == 9
      min_max_abs = [13.17, 13.68]
      min_max_base_delta_percent = [-24.54, -23.47]
      min_max_mn_delta_percent = [47.26, 48.93]
    elsif test_num == 10
      min_max_abs = [8.81, 9.13]
      min_max_base_delta_percent = [16.65, 18.12]
      min_max_mn_delta_percent = [47.38, 48.74]
    elsif test_num == 11
      min_max_abs = [12.87, 13.36]
      min_max_base_delta_percent = [2.20, 2.38]
      min_max_mn_delta_percent = [46.81, 48.48]
    elsif test_num == 12
      min_max_abs = [30.19, 31.31]
      min_max_base_delta_percent = [-130.88, -127.52]
      min_max_mn_delta_percent = [44.41, 45.99]
    elsif test_num == 13
      min_max_abs = [11.90, 12.38]
      min_max_base_delta_percent = [9.38, 9.74]
      min_max_mn_delta_percent = [45.60, 47.33]
    elsif test_num == 14
      min_max_abs = [11.68, 12.14]
      min_max_base_delta_percent = [11.00, 11.40]
      min_max_mn_delta_percent = [41.32, 42.86]
    else
      fail 'Unexpected test.'
    end

    base_delta_percent = nil
    mn_delta_percent = nil
    if (not min_max_base_delta_percent.nil?) && (not base_val.nil?)
      base_delta_percent = (base_val - curr_val) / base_val * 100.0 # %
    end
    if (not min_max_mn_delta_percent.nil?) && (not mn_val.nil?)
      mn_delta_percent = (mn_val - curr_val) / mn_val * 100.0 # %
    end

    assert_operator(curr_val, :>=, min_max_abs[0])
    assert_operator(curr_val, :<=, min_max_abs[1])
    if not base_delta_percent.nil?
      assert_operator(base_delta_percent, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta_percent, :<=, min_max_base_delta_percent[1])
    end
    if not mn_delta_percent.nil?
      assert_operator(mn_delta_percent, :>=, min_max_mn_delta_percent[0])
      assert_operator(mn_delta_percent, :<=, min_max_mn_delta_percent[1])
    end
  end

  def _check_hot_water_301_2014_pre_addendum_a(test_num, curr_val, base_val = nil, mn_val = nil)
    # Acceptance criteria from Hot Water Performance Tests Excel spreadsheet
    if test_num == 1
      min_max_abs = [18.2, 22.0]
    elsif test_num == 2
      min_max_base_delta_percent = [26.5, 32.2]
    elsif test_num == 3
      min_max_base_delta_percent = [-11.8, -6.8]
    elsif test_num == 4
      min_max_abs = [10.9, 14.4]
      min_max_fl_delta_abs = [5.5, 9.4]
      min_max_fl_delta_percent = [28.9, 45.1]
    elsif test_num == 5
      min_max_base_delta_percent = [19.1, 29.1]
    elsif test_num == 6
      min_max_base_delta_percent = [-19.5, -7.7]
    else
      fail 'Unexpected test.'
    end

    base_delta = nil
    mn_delta = nil
    fl_delta_percent = nil
    if (not min_max_base_delta_percent.nil?) && (not base_val.nil?)
      base_delta = (curr_val - base_val) / base_val * 100.0 # %
    end
    if (not min_max_fl_delta_abs.nil?) && (not mn_val.nil?)
      fl_delta = mn_val - curr_val
    end
    if (not min_max_fl_delta_percent.nil?) && (not mn_val.nil?)
      fl_delta_percent = (mn_val - curr_val) / mn_val * 100.0 # %
    end

    if not min_max_abs.nil?
      assert_operator(curr_val, :>=, min_max_abs[0])
      assert_operator(curr_val, :<=, min_max_abs[1])
    end
    if not base_delta.nil?
      assert_operator(base_delta, :>=, min_max_base_delta_percent[0])
      assert_operator(base_delta, :<=, min_max_base_delta_percent[1])
    end
    if not fl_delta.nil?
      assert_operator(fl_delta, :>=, min_max_fl_delta_abs[0])
      assert_operator(fl_delta, :<=, min_max_fl_delta_abs[1])
    end
    if not fl_delta_percent.nil?
      assert_operator(fl_delta_percent, :>=, min_max_fl_delta_percent[0])
      assert_operator(fl_delta_percent, :<=, min_max_fl_delta_percent[1])
    end
  end

  def _override_mech_vent_fan_power(ref_xml)
    ref_hpxml = HPXML.new(hpxml_path: ref_xml)
    ref_hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_whole_building_ventilation
      if (ventilation_fan.fan_type == HPXML::MechVentTypeSupply) || (ventilation_fan.fan_type == HPXML::MechVentTypeExhaust)
        ventilation_fan.fan_power = 0.35 * ventilation_fan.tested_flow_rate
      elsif ventilation_fan.fan_type == HPXML::MechVentTypeBalanced
        ventilation_fan.fan_power = 0.70 * ventilation_fan.tested_flow_rate
      elsif (ventilation_fan.fan_type == HPXML::MechVentTypeERV) || (ventilation_fan.fan_type == HPXML::MechVentTypeHRV)
        ventilation_fan.fan_power = 1.00 * ventilation_fan.tested_flow_rate
      elsif ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
        ventilation_fan.fan_power = 0.50 * ventilation_fan.tested_flow_rate
      end
    end
    XMLHelper.write_file(ref_hpxml.to_oga, ref_xml)
  end

  def _rm_path(path)
    if Dir.exist?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exist?(path)

      sleep(0.01)
    end
  end
end
