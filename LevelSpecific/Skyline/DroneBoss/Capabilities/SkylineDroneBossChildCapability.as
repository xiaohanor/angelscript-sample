UCLASS(Abstract)
class USkylineDroneBossChildCapability : UHazeChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBoss);

	ASkylineDroneBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineDroneBoss>(Owner);
	}

	USkylineDroneBossSettings GetSettings() const property
	{
		return Cast<USkylineDroneBossSettings>(
			Boss.GetSettings(USkylineDroneBossSettings)
		);
	}
}