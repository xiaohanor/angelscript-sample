UCLASS(Abstract)
class UIslandDroidZiplineBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DroidZipline");

	AIslandDroidZipline Droid;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Droid = Cast<AIslandDroidZipline>(Owner);
	}
}