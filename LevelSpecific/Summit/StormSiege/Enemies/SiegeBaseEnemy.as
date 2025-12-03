class ASiegeBaseEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSiegeActiveRangeCapability");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};