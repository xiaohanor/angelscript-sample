event void FOilRigDropShipEvent();

class AOilRigDropShip : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ActorHiddenInGame = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShipRoot;

	UPROPERTY(DefaultComponent, Attach = ShipRoot)
	USceneComponent HoverRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UArrowComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	UControllableDropShipShotResponseComponent ShotResponseComp;

	UPROPERTY()
	FOilRigDropShipEvent OnReachedEndOfSpline;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AOilRigDropShipProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	bool bHover = true;

	UPROPERTY(EditAnywhere)
	FOilRigDropShipHoverValues HoverValues;
	float HoverTimeOffset = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float MaxSplineSpeed = 4000.0;
	float SplineSpeed = 4000.0;

	UPROPERTY(EditAnywhere)
	float AccelerationSpeed = -1.0;

	UPROPERTY(EditAnywhere)
	bool bFollowSplineRotation = true;

	UPROPERTY(EditAnywhere)
	bool bFollowOnlyYaw = false;

	UPROPERTY(EditAnywhere)
	bool bDecelerateTowardsEndOfSpline = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bDecelerateTowardsEndOfSpline", EditConditionHides))
	float DecelerationStartFraction = 0.75;

	UPROPERTY(EditAnywhere)
	bool bDestroyOnSplineEnd = false;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;
	bool bTriggeredByPlayer = false;

	UPROPERTY(EditAnywhere)
	float TriggerDelay = 0.0;

	float SplineDist = 0.0;

	bool bFollowingSpline = false;

	bool bShootingAutomatically = false;
	FTimerHandle ShootAutomaticallyTimerHandle;

	int CurrentHits = 0;
	int HitsRequired = 5;

	bool bDestroyed = false;

	bool bSwingFlightPhysicsActive = false;
	float SwingFlightPhysicsStartTimeStamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (FollowSpline != nullptr)
			SplineComp = FollowSpline.Spline;

		SplineSpeed = MaxSplineSpeed;

		ShotResponseComp.OnHit.AddUFunction(this, n"GetHit");

		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");

		if (bHover)
			HoverTimeOffset = Math::RandRange(0.0, 2.0);
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggeredByPlayer)
			return;

		bTriggeredByPlayer = true;

		if (TriggerDelay != 0.0)
			Timer::SetTimer(this, n"StartFollowingSpline", TriggerDelay);
		else
			StartFollowingSpline();
	}

	UFUNCTION()
	private void GetHit()
	{
		CurrentHits++;
		if (CurrentHits >= HitsRequired)
			Destroy();
	}

	UFUNCTION()
	void Destroy()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;

		BP_Destroy();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}

	UFUNCTION()
	void ShootProjectile(FVector TargetLoc, bool bPlayImpactEffect)
	{
		AOilRigDropShipProjectile Projectile = SpawnActor(ProjectileClass, MuzzleComp.WorldLocation, MuzzleComp.WorldRotation);
		Projectile.Launch(TargetLoc, bPlayImpactEffect);

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(this, FWeaponHandlingLaunchParams(Projectile.ActorLocation, Projectile.ActorVelocity, 1, 1));
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		SplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		bFollowingSpline = true;
		SetActorHiddenInGame(false);

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void UpdateFollowSpline(ASplineActor NewSpline, bool bStartFollowing)
	{
		SplineComp = NewSpline.Spline;

		if (bStartFollowing)
			StartFollowingSpline();
	}

	UFUNCTION()
	void UpdateSplineSpeed(float Speed)
	{
		SplineSpeed = Speed;
	}

	UFUNCTION()
	void StartShootingAutomatically()
	{
		ShootAutomaticallyTimerHandle = Timer::SetTimer(this, n"ShootAutomatically", 1.0, true, Math::RandRange(0.0, 1.0));
	}

	UFUNCTION()
	void ShootAutomatically()
	{
		ShootProjectile(ActorLocation + ActorForwardVector * 7000.0, false);
	}

	UFUNCTION()
	void StopShootingAutomatically()
	{
		bShootingAutomatically = false;
		ShootAutomaticallyTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFollowingSpline)
		{
			bool bDecelerating = false;
			if (bDecelerateTowardsEndOfSpline)
			{
				float SplineAlpa = SplineDist/SplineComp.SplineLength;
				if (SplineAlpa >= DecelerationStartFraction)
				{
					bDecelerating = true;
					float CurrentDecelerationFraction = Math::GetMappedRangeValueClamped(FVector2D(DecelerationStartFraction, 1.0), FVector2D(0.0, 1.0), SplineAlpa);
					float SplineSpeedModifier = Math::Lerp(1.0, 0.1, CurrentDecelerationFraction);
					SplineSpeed = MaxSplineSpeed * SplineSpeedModifier;
				}
			}
			if (AccelerationSpeed > 0.0 && !bDecelerating)
				SplineSpeed = Math::Clamp(SplineSpeed + AccelerationSpeed * DeltaTime, 0.0, MaxSplineSpeed);

			SplineDist += SplineSpeed * DeltaTime;

			FVector Loc = Math::VInterpTo(ActorLocation, SplineComp.GetWorldLocationAtSplineDistance(SplineDist), DeltaTime, 10.0);
			SetActorLocation(Loc);

			if (bFollowSplineRotation)
			{
				FRotator TargetRot = SplineComp.GetWorldRotationAtSplineDistance(SplineDist).Rotator();
				if (bFollowOnlyYaw)
				{
					TargetRot.Pitch = 0.0;
					TargetRot.Roll = 0.0;
				}
				FRotator Rot = Math::RInterpTo(ActorRotation, TargetRot, DeltaTime, 5.0);
				SetActorRotation(Rot);
			}

			if (SplineDist >= SplineComp.SplineLength)
			{
				if (SplineComp.IsClosedLoop())
				{
					SplineDist = 0.0;
				}
				else
				{
					bFollowingSpline = false;
					OnReachedEndOfSpline.Broadcast();
					if (bDestroyOnSplineEnd)
						Destroy();
				}
			}
		}

		if (bHover)
		{
			float Time = Time::GameTimeSeconds + HoverTimeOffset;
			float Roll = Math::DegreesToRadians(Math::Sin(Time * HoverValues.HoverRollSpeed) * HoverValues.HoverRollRange);
			float Pitch = Math::DegreesToRadians(Math::Cos(Time * HoverValues.HoverPitchSpeed) * HoverValues.HoverPitchRange);
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

			HoverRoot.SetRelativeRotation(Rotation);

			float XOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.X) * HoverValues.HoverOffsetRange.X;
			float YOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Y) * HoverValues.HoverOffsetRange.Y;
			float ZOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Z) * HoverValues.HoverOffsetRange.Z;

			FVector Offset = (FVector(XOffset, YOffset, ZOffset));

			HoverRoot.SetRelativeLocation(Offset);
		}

		if (bSwingFlightPhysicsActive)
		{
			float Time = SwingFlightPhysicsStartTimeStamp;
			float Roll = Math::DegreesToRadians(Math::Sin(Time * 1.5) * 4.0);
			float Pitch = 0.0;
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

			ShipRoot.SetRelativeRotation(Rotation);

			float XOffset = 0.0;
			float YOffset = -Math::Sin(Time * 2.0) * 80.0;
			float ZOffset = Math::Sin(Time * 1.2) * 100.0;

			FVector Offset = (FVector(XOffset, YOffset, ZOffset));

			ShipRoot.SetRelativeLocation(Offset);

			SwingFlightPhysicsStartTimeStamp += DeltaTime;
		}
	}

	UFUNCTION()
	void TriggerSwingFlightPhysics()
	{
		SwingFlightPhysicsStartTimeStamp = 0.0;
		bSwingFlightPhysicsActive = true;
	}

	UFUNCTION()
	void StopHovering()
	{
		bHover = false;
	}

	UFUNCTION()
	void SnapHoverRootToDefault()
	{
		HoverRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	}

	UFUNCTION()
	void SetTickEnabled()
	{
		SetActorTickEnabled(true);
	}
}

struct FOilRigDropShipHoverValues
{
	UPROPERTY()
	float HoverRollRange = 1.0;
	UPROPERTY()
	float HoverRollSpeed = 3.5;
	UPROPERTY()
	float HoverPitchRange = 2.0;
	UPROPERTY()
	float HoverPitchSpeed = 1.0;
	UPROPERTY()
	FVector HoverOffsetRange = FVector(50.0, 200.0, 50.0);
	UPROPERTY()
	FVector HoverOffsetSpeed = FVector(1.5, 1.0, 1.25);
}