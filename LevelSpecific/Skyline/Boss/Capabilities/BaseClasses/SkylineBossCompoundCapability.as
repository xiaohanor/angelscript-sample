UCLASS(Abstract)
class USkylineBossCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default CapabilityTags.Add(SkylineBossTags::SkylineBoss);

	// Must tick in movement to run before animation!
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll();
	}
};