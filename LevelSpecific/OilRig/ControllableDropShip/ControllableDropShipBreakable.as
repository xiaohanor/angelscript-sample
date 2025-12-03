class AControllableDropShipBreakable : ABreakableActor
{
	default BreakableComponent.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UControllableDropShipShotResponseComponent ShotResponseComp;

	UPROPERTY(EditAnywhere)
	bool bShootable = true;

	UPROPERTY(EditAnywhere)
	int HitsRequired = 1;
	int CurrentHits = 0;

	bool bBroken = false;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ConnectedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ShotResponseComp.OnHit.AddUFunction(this, n"Shot");
	}

	UFUNCTION()
	private void Shot()
	{
		if (!bShootable)
			return;

		if (bBroken)
			return;

		CurrentHits++;
		if (CurrentHits >= HitsRequired)
			Break();
	}

	UFUNCTION()
	void Break()
	{
		if (bBroken)
			return;

		bBroken = true;
		SetActorEnableCollision(false);

		BP_Break();

		for (AActor Actor : ConnectedActors)
		{
			Actor.AddActorDisable(this);
		}

		AddActorDisable(this);

		// Add when we get real breakable meshes
		// BreakableComponent.BreakWithDefault();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Break() {}
}