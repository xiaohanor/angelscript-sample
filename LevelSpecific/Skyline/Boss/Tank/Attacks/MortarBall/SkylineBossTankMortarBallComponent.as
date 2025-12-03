class USkylineBossTankMortarBallComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankMortarBall> MortarBallClass;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector MuzzleLocation;

	UPROPERTY(EditAnywhere)
	float MinRange = 8000.0;

	/**
	 * Spawn counter must be per player, since we use the players control side.
	 * Otherwise the counters may become desynced if we spawn one on our control
	 * while a crumb is being sent from the other side to us.
	 */
	private TPerPlayer<int> SpawnedMortarBalls;

	TArray<ASkylineBossTankMortarBallFire> MortarBallFires;
	int MaxMortarBallFires = 40;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	FVector GetLaunchLocation() const
	{
		return WorldTransform.TransformPositionNoScale(MuzzleLocation);
	}

	/**
	 * Called from crumbed activation of USkylineBossTankMortarBallAttackCapability
	 */
	void Fire(AHazePlayerCharacter TargetPlayer, float LaunchHeight, FVector TargetLocation)
	{
		// Launch location and velocity is all local, we should still hit at the same time since the height and gravity is synced
		const FVector LaunchLocation = GetLaunchLocation();
		const FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchLocation, TargetLocation, MortarBall::Gravity, LaunchHeight);

		int& PlayerSpawnedMortarBalls = SpawnedMortarBalls[TargetPlayer];
		PlayerSpawnedMortarBalls++;

		auto MortarBall = SpawnActor(MortarBallClass, LaunchLocation, bDeferredSpawn = true);
		MortarBall.MakeNetworked(this, TargetPlayer, PlayerSpawnedMortarBalls);

		// Control projectile on the target bikes side, so that they get the least amount of latency
		MortarBall.SetActorControlSide(TargetPlayer);

//		LaunchVelocity += Owner.ActorVelocity;
//		LaunchVelocity += ForwardVector * 10000.0;
		MortarBall.TargetBike = GravityBikeFree::GetGravityBike(TargetPlayer);
		MortarBall.TargetDecal.WorldLocation = TargetLocation;
		MortarBall.ActorVelocity = LaunchVelocity;
		MortarBall.MoveComp.AddMovementIgnoresActor(this, Owner);

		MortarBall.LaunchTrajectory.LaunchLocation = LaunchLocation;
		MortarBall.LaunchTrajectory.LaunchVelocity = LaunchVelocity;
		MortarBall.LaunchTrajectory.Gravity = FVector::UpVector * MortarBall::Gravity;
		MortarBall.LaunchTrajectory.LandLocation = TargetLocation;

		auto BossTank = Cast<ASkylineBossTank>(Owner); 
		if (BossTank != nullptr)
			MortarBall.OnMortarImpact.AddUFunction(BossTank, n"HandleMortarBallImpact");

		FinishSpawningActor(MortarBall);
	}

	void ClearFire()
	{
		for (int i = MortarBallFires.Num() - 1; i >= 0; i--)
		{
			MortarBallFires[i].RemoveInstant();
			MortarBallFires.RemoveAt(i);
		}
	}

	void RemoveOldestFire()
	{
		auto MortarBallFire = MortarBallFires[0];
		MortarBallFires.RemoveAt(0);
		MortarBallFire.Remove();
	}
};