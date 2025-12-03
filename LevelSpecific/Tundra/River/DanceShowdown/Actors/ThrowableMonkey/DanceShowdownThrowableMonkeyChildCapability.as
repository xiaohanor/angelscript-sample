class UDanceShowdownThrowableMonkeyChildCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	ADanceShowdownThrowableMonkey Monkey;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ADanceShowdownThrowableMonkey>(Owner);
	}
};