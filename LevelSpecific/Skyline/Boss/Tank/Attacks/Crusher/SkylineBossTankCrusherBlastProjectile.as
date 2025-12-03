class ASkylineBossTankCrusherBlastProjectile : AHazeActor
{
	UPROPERTY(EditAnywhere)
	float LaunchSpeed = 8000.0;

	UPROPERTY(EditAnywhere)
	float ProjectileLifeSpan = 6.0;
	float ExpireTime = 0.0;

	ASkylineBossTank BossTank;

	float Length = 5000.0;

	float TraveledDistance = 0.0;

	FVector Velocity;

	FHazeAcceleratedFloat AccSpeed;

	FHazeAcceleratedQuat AccQuat;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.25;

	TPerPlayer<bool> bInFrontLastFrame;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExpireTime = Time::GameTimeSeconds + ProjectileLifeSpan;
		AccQuat.SnapTo(ActorQuat);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ExpireTime)
			DestroyActor();

		FVector NewDirection = ActorForwardVector;

//		FVector NewDirection = ActorQuat.ForwardVector.RotateVectorTowardsAroundAxis(BossTank.ActorForwardVector, FVector::UpVector, 20.0 * DeltaSeconds);

		AccSpeed.AccelerateTo(LaunchSpeed, 0.1, DeltaSeconds);

		AccQuat.AccelerateTo(NewDirection.ToOrientationQuat(), 0.5, DeltaSeconds);
//		ActorQuat = AccQuat.Value;
		ActorQuat = NewDirection.ToOrientationQuat();


		TraveledDistance += AccSpeed.Value * DeltaSeconds;

//		ActorLocation = BossTank.CrusherComp.WorldLocation + (ActorQuat.ForwardVector * TraveledDistance);

		AddActorLocalOffset(FVector::ForwardVector * AccSpeed.Value * DeltaSeconds);

		for (auto Player : Game::Players)
		{
			FVector RelativeLocationToBeam = ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			bool bIsBehind = RelativeLocationToBeam.X < 0.0 && RelativeLocationToBeam.Y < Length * 0.5 && RelativeLocationToBeam.Y > -Length * 0.5;

			if (IsContinuouslyGrounded(Player))
			{
				if ((bInFrontLastFrame[Player] && bIsBehind))
					Player.DamagePlayerHealth(Damage);
			}

			bInFrontLastFrame[Player] = RelativeLocationToBeam.X > 0.0 && RelativeLocationToBeam.Y < Length * 0.5 && RelativeLocationToBeam.Y > -Length * 0.5;
		}
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}
};