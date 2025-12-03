class UBasicAIEntranceComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	bool bHasStartedEntry;
	bool bHasCompletedEntry;

	TInstigated<float> CollisionDurationAtEndOfEntrance;

	UAnimSequence EntranceAnim;

	UFUNCTION()
	private void OnReset()
	{
		bHasStartedEntry = false;
		bHasCompletedEntry = false;
	}
}