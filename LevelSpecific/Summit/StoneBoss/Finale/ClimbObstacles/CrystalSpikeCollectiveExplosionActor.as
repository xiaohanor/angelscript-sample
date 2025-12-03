class ACrystalSpikeCollectiveExplosionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ACrystalSpikeRupture> RuptureArray;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	bool bWasActivated; 

	float GrabRadius = 700.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<ACrystalSpikeRupture> AllRuptureArray = TListedActors<ACrystalSpikeRupture>().GetArray();

		for (ACrystalSpikeRupture Rupture : AllRuptureArray)
		{
			if (Rupture.GetDistanceTo(this) < GrabRadius)
				RuptureArray.AddUnique(Rupture);
		}
	}

	UFUNCTION()
	void DestroyRuptureCollective()
	{
		if (bWasActivated)
			return;

		bWasActivated = true;

		for (ACrystalSpikeRupture Rupture : RuptureArray)
		{
			if (Rupture.bWasDestroyed)
				continue;

			Rupture.WeakpointDestroyRupture();
		}

		UCrystalSpikeCollectiveExplosionActorEventHandler::Trigger_OnClusterDestroyed(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (ACrystalSpikeRupture Rupture : RuptureArray)
		{
			Debug::DrawDebugLine(ActorLocation, Rupture.ActorLocation, FLinearColor::Green, 5.0);
		}

		Debug::DrawDebugSphere(ActorLocation, GrabRadius, 12, FLinearColor::LucBlue, 5.0);
	}
#endif
};