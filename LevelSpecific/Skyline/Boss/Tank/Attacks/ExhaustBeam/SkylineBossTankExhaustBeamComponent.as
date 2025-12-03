class USkylineBossTankExhaustBeamComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankExhaustBeam> ExhaustBeamClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankExhaustBeamProjectile> ExhaustBeamProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankExhaustBeamSpline> ExhaustBeamSplineClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> DangerWidgetClass;
	TPerPlayer<UHazeUserWidget> DangerWidget;

	ASkylineBossTankExhaustBeam ExhaustBeam;

	ASkylineBossTankExhaustBeamSpline ExhaustBeamSpline;

	float ActivationTime = 3.0;
	float DectivationTime = 0.5;
	bool bActivated = false;

	bool bCanSpawnProjectile = true;
	float PointCooldown = 0.0;
	float PointSpacing = 200.0; // 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void ActivateExhaust()
	{
		bActivated = true;
		
		if (ExhaustBeamClass != nullptr)
		{
			ExhaustBeam = SpawnActor(ExhaustBeamClass);
			ExhaustBeam.AttachToComponent(this);
			ExhaustBeam.Activate(ActivationTime);
		}
	}

	void DeactivateExhaust()
	{
		bActivated = false;

		if (IsValid(ExhaustBeam))
			ExhaustBeam.Deactivate(DectivationTime);
	}

	void ActivateExhaustSpline()
	{
		bActivated = true;
		
		if (ExhaustBeamClass != nullptr)
		{
			ExhaustBeamSpline = SpawnActor(ExhaustBeamSplineClass);
		}

		for (auto Player : Game::Players)
		{
			DangerWidget[Player] = Player.AddWidget(DangerWidgetClass);
			DangerWidget[Player].AttachWidgetToComponent(this);
		}
	}

	void DeactivateExhaustSpline()
	{
		bActivated = false;

		if (IsValid(ExhaustBeamSpline))
			ExhaustBeamSpline.DestroyActor();

		for (auto Player : Game::Players)
			Player.RemoveWidget(DangerWidget[Player]);
	}

	UFUNCTION()
	void ReadyToSpawn()
	{
		bCanSpawnProjectile = true;
	}

	void SpawnExhaustProjectile()
	{
		if (!bCanSpawnProjectile)
			return;

		auto ExhaustBeamProjectile = SpawnActor(ExhaustBeamProjectileClass, WorldLocation, WorldRotation, bDeferredSpawn = true);
		ExhaustBeamProjectile.OnMovedDistance.AddUFunction(this, n"ReadyToSpawn");
		FinishSpawningActor(ExhaustBeamProjectile);
	}

	void AddExhaustBeamPoint()
	{
		if (Time::GameTimeSeconds < PointCooldown)
			return;

		if (IsValid(ExhaustBeamSpline))
		{
			ExhaustBeamSpline.AddBeamSplinePoint(WorldLocation, ForwardVector * ExhaustBeamSpline.Speed);
			PointCooldown = Time::GameTimeSeconds + (PointSpacing / ExhaustBeamSpline.Speed);
		}
	}
}