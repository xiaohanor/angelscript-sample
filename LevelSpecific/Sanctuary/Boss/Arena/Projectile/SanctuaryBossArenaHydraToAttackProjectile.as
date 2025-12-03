	class ASanctuaryBossArenaHydraToAttackProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float ArcHeight = 500.0;
	float FlightTime = 0.0;
	float FlightDuration = 2.0;
	float Scale = 0.0;
	float DamageRadius = 400.0;
	FVector StartLocation;
	FVector TargetLocation;

	FVector CachedCenter;

	FRotator OriginalRotation;
	float IncreasedRoll = 0.0;

	UPROPERTY(Category = Settings)
	UForceFeedbackEffect ForceFeedbackEffect;

	FHazeRuntimeSpline RuntimeSpline;
	AHazePlayerCharacter TargetPlayer;

	float TraversedDistance = 0.0;
	float StartSpeed = 6000.0;
	float TargetSpeed = 6000.0;
	float RightLeftTargetOffset = 500.0;

	FHazeAcceleratedFloat AccSpeed;


	//Hannes variablar

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY()
	FHazeTimeLike HomingTimeLike;
	default HomingTimeLike.UseLinearCurveZeroToOne();
	default HomingTimeLike.Duration = 1.0;

	float HomingMultiplier = 1.0;

	FVector InitialForward;

	FHazeAcceleratedVector AccTargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		OriginalRotation = ActorRotation;
		InitialForward = ActorForwardVector;
		SimpleUpdateSpline();
		AccSpeed.SnapTo(StartSpeed);
		AccTargetLocation.SnapTo(TargetPlayer.ActorLocation);
		HomingTimeLike.BindUpdate(this, n"HomingTimeLikeUpdate");
		//HomingTimeLike.Play();
	}

	UFUNCTION()
	private void HomingTimeLikeUpdate(float CurrentValue)
	{
		HomingMultiplier = CurrentValue;
	}

	void SimpleUpdateSpline()
	{
		TArray<FVector> Points;
		Points.Add(StartLocation);

		TListedActors<ASanctuaryBossArenaManager> OrigoActors;
		FVector Direction = OrigoActors.Single.ActorLocation - TargetPlayer.ActorLocation;
		Direction.Z = 0.0;
		Direction = Direction.GetSafeNormal();

		FVector FarTarget = TargetPlayer.ActorLocation + Direction * 3500.0;
		// FarTarget += CachedCenter;
		FarTarget.Z = TargetPlayer.ActorLocation.Z;
		FVector FarfarTarget = (FarTarget - StartLocation).GetSafeNormal() * 10000;
		FarfarTarget += StartLocation;
		Points.Add(FarTarget);
		Points.Add(FarfarTarget);
		RuntimeSpline.SetPoints(Points);
		// RuntimeSpline.SetCustomEnterTangentPoint(OriginalRotation.ForwardVector);
		// FVector ToPlayer = TargetPlayer.ActorLocation - TargetLocation;
		// RuntimeSpline.SetCustomExitTangentPoint(-ToPlayer.GetSafeNormal());
	}

	// void UpdateSpline()
	// {
	// 	TArray<FVector> Points;
	// 	Points.Add(StartLocation);
	// 	Points.Add(StartLocation + OriginalRotation.ForwardVector * 500.0);

	// 	FVector PlayerDirection = TargetPlayer.ActorLocation - CachedCenter;
	// 	PlayerDirection.Z = 0.0;

	// 	FRotator TowardsCenter = FRotator::MakeFromXZ(-PlayerDirection.GetSafeNormal(), FVector::UpVector);
	// 	FVector RandomOffset;
	// 	// float RandChance = Math::RandRange(0.0, 1.0);
	// 	// float RandomSlice = 1.0 / 4.0;
	// 	// if (RandChance <  RandomSlice)
	// 	// 	RandomOffset = TowardsCenter.RightVector * RightLeftTargetOffset;
	// 	// if (RandChance < 2.0 * RandomSlice)
	// 	// 	RandomOffset = - TowardsCenter.RightVector * RightLeftTargetOffset;

	// 	FVector CloseTarget = TargetPlayer.ActorLocation + TargetPlayer.ActorForwardVector * 500.0;
	// 	Points.Add(CloseTarget + RandomOffset);


	// 	FVector FarTarget = PlayerDirection.GetSafeNormal() * 20000.0;
	// 	FarTarget += CachedCenter;
	// 	FarTarget.Z = TargetPlayer.ActorLocation.Z;
	// 	Points.Add(FarTarget + RandomOffset);
	// 	RuntimeSpline.SetPoints(Points);
	// 	RuntimeSpline.SetCustomEnterTangentPoint(OriginalRotation.ForwardVector);

	// 	FVector ToPlayer = TargetPlayer.ActorLocation - TargetLocation;
	// 	RuntimeSpline.SetCustomExitTangentPoint(-ToPlayer.GetSafeNormal());
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccTargetLocation.AccelerateTo(TargetPlayer.ActorLocation + TargetPlayer.ActorForwardVector * 1000.0, 2.5, DeltaSeconds);
		FVector HomingMovement = (AccTargetLocation.Value - ActorLocation).GetSafeNormal();
		FVector Direction = Math::Lerp(InitialForward, HomingMovement, HomingMultiplier);
		FVector DeltaMove = Direction * AccSpeed.Value * DeltaSeconds;

		//Debug::DrawDebugArrow(ActorLocation, ActorLocation + Direction * 10000.0);
		//Debug::DrawDebugSphere(AccTargetLocation.Value);

		AddActorWorldOffset(DeltaMove);

		SetActorRotation(VelocityTrackerComp.GetCurrentFrameDeltaTranslation().Rotation());

		if (TargetPlayer.ActorForwardVector.DotProduct((ActorLocation - TargetPlayer.ActorLocation).GetSafeNormal()) < 0.0)
			StopHoming();

		// FlightTime += DeltaSeconds;
		// float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		// FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		// Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		// UpdateSpline();

		// IncreasedRoll += 90 * DeltaSeconds;
		// SetActorRotation(OriginalRotation + FRotator::MakeFromEuler(FVector(IncreasedRoll, 0.0, 0.0)));

		CheckDamage();

		if (GameTimeSinceCreation > 10.0)
			DestroyActor();
	}

	private void AcceleratedTargetHoming(float DeltaSeconds)
	{

	}

	private void StopHoming()
	{
		InitialForward = ActorForwardVector;
		HomingMultiplier = 0.0;
	}

	void OldTick(float DeltaSeconds)
	{
		AccSpeed.AccelerateTo(TargetSpeed, 1.0, DeltaSeconds);
		TraversedDistance += AccSpeed.Value * DeltaSeconds;
		if (TraversedDistance >= RuntimeSpline.Length)
		{
			CheckDamage();
			BP_Explode();
			DestroyActor();
			return;
		}

		FVector Location;
		FQuat Rotation;
		RuntimeSpline.GetLocationAndQuatAtDistance(TraversedDistance, Location, Rotation);
		RuntimeSpline.DrawDebugSpline();

		SetActorLocation(Location);
		SetActorRotation(Rotation);
		ActorScale3D = FVector::OneVector; 
	}

	void CheckDamage()
	{
		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
			{
				UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
				HealthComp.DamagePlayer(0.33, nullptr, nullptr);
				Player.PlayForceFeedback(ForceFeedbackEffect, false, false, this, 1.0);
				BP_Explode();
				Timer::SetTimer(this, n"DestroyTimer", 0.5);
			}
		}
	}

	UFUNCTION()
	private void DestroyTimer()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}
};