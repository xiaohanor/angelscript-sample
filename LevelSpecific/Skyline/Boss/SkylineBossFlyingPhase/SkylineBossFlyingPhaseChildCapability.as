UCLASS(Abstract)
class USkylineBossFlyingPhaseChildCapability : UHazeChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBoss);

	ASkylineBossFlyingPhaseActor Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBossFlyingPhaseActor>(Owner);
	}
}