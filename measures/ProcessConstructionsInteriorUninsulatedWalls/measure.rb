#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsInteriorUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  class PartitionWallMass
    def initialize(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat, partitionWallMassPCMType)
      @partitionWallMassThickness = partitionWallMassThickness
      @partitionWallMassConductivity = partitionWallMassConductivity
      @partitionWallMassDensity = partitionWallMassDensity
      @partitionWallMassSpecHeat = partitionWallMassSpecHeat
      @partitionWallMassPCMType = partitionWallMassPCMType
    end

    def PartitionWallMassThickness
      return @partitionWallMassThickness
    end

    def PartitionWallMassConductivity
      return @partitionWallMassConductivity
    end

    def PartitionWallMassDensity
      return @partitionWallMassDensity
    end

    def PartitionWallMassSpecificHeat
      return @partitionWallMassSpecHeat
    end

    def PartitionWallMassPCMType
      return @partitionWallMassPCMType
    end

  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsInteriorUninsulatedWalls"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    material_handles = OpenStudio::StringVector.new
    material_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    material_args = model.getStandardOpaqueMaterials
    material_args_hash = {}
    material_args.each do |material_arg|
      material_args_hash[material_arg.name.to_s] = material_arg
    end

    #looping through sorted hash of model objects
    material_args_hash.sort.map do |key,value|
      material_handles << value.handle.to_s
      material_display_names << key
    end

    # #make a choice argument for partition wall mass
    # selected_partitionwallmass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedpartitionwallmass", material_handles, material_display_names, false)
    # selected_partitionwallmass.setDisplayName("Partition wall mass. For manually entering partition wall mass properties, leave blank.")
    # args << selected_partitionwallmass

    #make a double argument for partition wall mass thickness
    userdefined_partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassth", false)
    userdefined_partitionwallmassth.setDisplayName("Partition wall mass thickness [in].")
    userdefined_partitionwallmassth.setDefaultValue(0.5)
    args << userdefined_partitionwallmassth

    #make a double argument for partition wall mass conductivity
    userdefined_partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasscond", false)
    userdefined_partitionwallmasscond.setDisplayName("Partition wall mass conductivity [Btu-in/h-ft^2-R].")
    userdefined_partitionwallmasscond.setDefaultValue(1.1112)
    args << userdefined_partitionwallmasscond

    #make a double argument for partition wall mass density
    userdefined_partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassdens", false)
    userdefined_partitionwallmassdens.setDisplayName("Partition wall mass density [lb/ft^3].")
    userdefined_partitionwallmassdens.setDefaultValue(50.0)
    args << userdefined_partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    userdefined_partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasssh", false)
    userdefined_partitionwallmasssh.setDisplayName("Partition wall mass specific heat [Btu/lb-R].")
    userdefined_partitionwallmasssh.setDefaultValue(0.2)
    args << userdefined_partitionwallmasssh

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    partitionWallMassPCMType = nil

    # Partition Wall Mass
    selected_partitionwallmass = runner.getOptionalWorkspaceObjectChoiceValue("selectedpartitionwallmass",user_arguments,model)
    if selected_partitionwallmass.empty?
      userdefined_partitionwallmassth = runner.getDoubleArgumentValue("userdefinedpartitionwallmassth",user_arguments)
      userdefined_partitionwallmasscond = runner.getDoubleArgumentValue("userdefinedpartitionwallmasscond",user_arguments)
      userdefined_partitionwallmassdens = runner.getDoubleArgumentValue("userdefinedpartitionwallmassdens",user_arguments)
      userdefined_partitionwallmasssh = runner.getDoubleArgumentValue("userdefinedpartitionwallmasssh",user_arguments)
    end

    # Constants
    constants = Constants.new
    mat_wood = get_mat_wood

    # Partition Wall Mass
    if userdefined_partitionwallmassth.nil?
      partitionWallMassThickness = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      partitionWallMassConductivity = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      partitionWallMassDensity = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      partitionWallMassSpecificHeat = OpenStudio::convert(selected_partitionwallmass.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
    else
      partitionWallMassThickness = userdefined_partitionwallmassth
      partitionWallMassConductivity = userdefined_partitionwallmasscond
      partitionWallMassDensity = userdefined_partitionwallmassdens
      partitionWallMassSpecificHeat = userdefined_partitionwallmasssh
    end

    # Create the material class instances
    partition_wall_mass = PartitionWallMass.new(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecificHeat, partitionWallMassPCMType)

    # PartitionWallMass
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    pwm.setThickness(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(get_mat_partition_wall_mass(partition_wall_mass).Cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).TAbs)
    pwm.setSolarAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).SAbs)
    pwm.setVisibleAbsorptance(get_mat_partition_wall_mass(partition_wall_mass).VAbs)

    # ConcPCMPartWall
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMPartWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_part_pcm_conc(get_mat_part_pcm(partition_wall_mass), partition_wall_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

    # StudandAirWall
    saw = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    saw.setName("StudandAirWall")
    saw.setRoughness("Rough")
    saw.setThickness(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).thick,"ft","m").get)
    saw.setConductivity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).k,"Btu/hr*ft*R","W/m*K").get)
    saw.setDensity(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).rho,"lb/ft^3","kg/m^3").get)
    saw.setSpecificHeat(OpenStudio::convert(get_stud_and_air_wall(model, mat_wood).Cp,"Btu/lb*R","J/kg*K").get)

    # Plywood-1_2in
    ply1_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply1_2.setName("Plywood-1_2in")
    ply1_2.setRoughness("Rough")
    ply1_2.setThickness(OpenStudio::convert(get_mat_plywood1_2in(get_mat_wood).thick,"ft","m").get)
    ply1_2.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply1_2.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply1_2.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # FinUninsFinWall
    layercount = 0
    fufw = OpenStudio::Model::Construction.new(model)
    fufw.setName("FinUninsFinWall")
    fufw.insertLayer(layercount,pwm)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,saw)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      fufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    fufw.insertLayer(layercount,pwm)

    # RevFinUninsFinWall
    layercount = 0
    rfufw = OpenStudio::Model::Construction.new(model)
    rfufw.setName("RevFinUninsFinWall")
    fufw.layers.reverse_each do |layer|
      rfufw.insertLayer(layercount,layer)
      layercount += 1
    end

    # UnfinUninsFinWall
    layercount = 0
    uufw = OpenStudio::Model::Construction.new(model)
    uufw.setName("UnfinUninsFinWall")
    uufw.insertLayer(layercount,saw)
    layercount += 1
    if partition_wall_mass.PartitionWallMassPCMType == constants.PCMtypeConcentrated
      uufw.insertLayer(layercount,pcm)
      layercount += 1
    end
    uufw.insertLayer(layercount,pwm)

    # RevUnfinUninsFinWall
    layercount = 0
    ruufw = OpenStudio::Model::Construction.new(model)
    ruufw.setName("RevUnfinUninsFinWall")
    uufw.layers.reverse_each do |layer|
      ruufw.insertLayer(layercount,layer)
      layercount += 1
    end

    # UnfinUninsUnfinWall
    layercount = 0
    uuuw = OpenStudio::Model::Construction.new(model)
    uuuw.setName("UnfinUninsUnfinWall")
    uuuw.insertLayer(layercount,saw)
    layercount += 1
    uuuw.insertLayer(layercount,ply1_2)

    # RevUnfinUninsUnfinWall
    layercount = 0
    ruuuw = OpenStudio::Model::Construction.new(model)
    ruuuw.setName("RevUnfinUninsUnfinWall")
    uuuw.layers.reverse_each do |layer|
      ruuuw.insertLayer(layercount,layer)
      layercount += 1
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorUninsulatedWalls.new.registerWithApplication