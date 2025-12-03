class UTundraBossSetupChildCapability : UHazeChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	ATundraBossSetup Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ATundraBossSetup>(Owner);
	}
};