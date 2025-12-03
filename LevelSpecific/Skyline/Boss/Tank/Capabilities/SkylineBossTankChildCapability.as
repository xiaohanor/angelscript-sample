UCLASS(Abstract)
class USkylineBossTankChildCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTank);

	ASkylineBossTank BossTank;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossTank = Cast<ASkylineBossTank>(Owner);
	}
}