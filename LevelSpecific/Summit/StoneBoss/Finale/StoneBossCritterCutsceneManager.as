class AStoneBossCritterCutsceneManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditAnywhere)
	TArray<AActor> CutsceneActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor Actor : CutsceneActors)
		{
			Actor.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void ActivateCrittersForCutscene()
	{
		for (AActor Actor : CutsceneActors)
		{
			Actor.RemoveActorDisable(this);
			AAISummitStoneBeastCritter Critter = Cast<AAISummitStoneBeastCritter>(Actor);
			if (Critter != nullptr)
				Critter.BlockCapabilities(CapabilityTags::Movement, this);
		}
	}

	UFUNCTION()
	void UnblockCrittersMovement()
	{
		for (AActor Actor : CutsceneActors)
		{
			Actor.RemoveActorDisable(this);
			AAISummitStoneBeastCritter Critter = Cast<AAISummitStoneBeastCritter>(Actor);
			if (Critter != nullptr && Critter.IsCapabilityTagBlocked(CapabilityTags::Movement))
				Critter.UnblockCapabilities(CapabilityTags::Movement, this);
		}
	}
};