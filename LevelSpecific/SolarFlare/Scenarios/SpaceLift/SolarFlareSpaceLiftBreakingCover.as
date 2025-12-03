class ASolarFlareSpaceLiftBreakingCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LargeVersion;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SmallVersion;

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFlareCoverOverlapComponent CoverComp;
	default CoverComp.BoxExtent = FVector(120.0, 150.0, 200.0);

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;
	default SplineMoveComp.bStartActive = false;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	int HitCount;

	bool bCanBreak;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");	
	}

	UFUNCTION()
	void ActivateMovement()
	{
		SplineMoveComp.ActivateSplineMovement();
	}

	UFUNCTION()
	void ActivateBreakingCover()
	{
		bCanBreak = true;
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (!bCanBreak)
			return;

		HitCount++;

		if (HitCount > 0 && HitCount < 2)
		{
			LargeVersion.SetHiddenInGame(true);
			LargeVersion.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			CoverComp.BoxExtent = FVector(120.0, 150.0, 100.0);
		}
		else if (HitCount >= 2)
		{
			SmallVersion.SetHiddenInGame(true);
			SmallVersion.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			CoverComp.AddDisabler(this);
		}
	}
}