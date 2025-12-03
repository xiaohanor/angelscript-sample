class USkylineBossTankAutoCannonComponent : USceneComponent
{
	TArray<AHazeActor> Targets;

	UPROPERTY()
	TSubclassOf<ASkylineBossTankAutoCannonProjectile> ProjectileClass;

	UPROPERTY()
	AHazeActor CurrentTarget;
	bool bHasTarget = false;
	bool bTargetInFocus = false;

	UPROPERTY(EditAnywhere)
	float DetectionDistance = 100000.0;
	float DetectionDistanceSquared = 0.0;

	UPROPERTY(EditAnywhere)
	float MinDistance = 6000.0;

	UPROPERTY(EditAnywhere)
	float DetectionAngle = 110.0;
	FRotator InitialRelativeRotation;

	UPROPERTY(EditAnywhere)
	bool bTraceTargetVisibility = true;

	UPROPERTY(EditAnywhere)
	bool bUseTargetMovementPrediction = false;

	UPROPERTY(EditAnywhere)
	float TargetMovementPredictionMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float TrackingSpeed = 60.0;

	UPROPERTY(EditAnywhere)
	float FocusAngle = 10.0;

	UPROPERTY(EditAnywhere)
	float SpreadAngle = 4.0;

	UPROPERTY(EditAnywhere)
	float FireInterval = 0.15;
	float FireTime = 0.0;

	UPROPERTY(EditAnywhere)
	int MagSize = 20;
	int ShotsFired = 0;

	UPROPERTY(EditAnywhere)
	float ReloadTime = 2.0;

	UPROPERTY(EditAnywhere)
	TArray<FVector> MuzzleLocations;
	int MuzzleIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DetectionDistanceSquared = DetectionDistance * DetectionDistance;
		InitialRelativeRotation = RelativeRotation;
	}

	void UpdateTargeting(float DeltaSeconds)
	{
		CurrentTarget = nullptr;
		FVector TargetDirection = Owner.ActorTransform.TransformVectorNoScale(InitialRelativeRotation.ForwardVector);

		float ClosestDistanceSquared = DetectionDistanceSquared;
		for (auto Target : Targets)
		{
			FVector ToTarget = Target.ActorLocation - WorldLocation;
			if (ToTarget.SizeSquared() < ClosestDistanceSquared && ToTarget.GetAngleDegreesTo(Owner.ActorTransform.TransformVectorNoScale(InitialRelativeRotation.ForwardVector)) < DetectionAngle)
			{
				if (bTraceTargetVisibility)
				{
					auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
					Trace.IgnoreActor(Owner);
					Trace.IgnoreActor(Target);
					Trace.IgnoreActor(Target.AttachParentActor);
					auto HitResult = Trace.QueryTraceSingle(WorldLocation, Target.ActorLocation);

					if (HitResult.bBlockingHit)
						continue;
				}

				ClosestDistanceSquared = ToTarget.SizeSquared();
				TargetDirection = ToTarget.SafeNormal;
				CurrentTarget = Target;
			}
		}

		if (CurrentTarget != nullptr)
		{
			if (!bHasTarget)
			{
				bHasTarget = true;
			}

			if (TargetDirection.GetAngleDegreesTo(ForwardVector) <= FocusAngle)
			{
				if (!bTargetInFocus)
				{
					bTargetInFocus = true;
				}
			}
			else
			{
				if (bTargetInFocus)
				{
					bTargetInFocus = false;
				}				
			}
		}
		else
		{
			if (bHasTarget)
			{
				bHasTarget = false;
			}

			if (bTargetInFocus)
			{
				bTargetInFocus = false;
			}
		}

		FQuat Rotation = FQuat::Slerp(ComponentQuat, FQuat::MakeFromXZ(TargetDirection, Owner.ActorTransform.TransformVectorNoScale(InitialRelativeRotation.UpVector)), TrackingSpeed * DeltaSeconds);
		SetWorldRotation(Rotation);

//		PrintToScreen("AutoCannon - Target: " + bHasTarget + " Focus: " + bTargetInFocus, 0.0,  FLinearColor::Green);

		if (bHasTarget)
		{
//			Debug::DrawDebugLine(WorldLocation, CurrentTarget.ActorCenterLocation, FLinearColor::Red, 10.0, 0.0);
		}
	}

	bool CanFire()
	{
		if (!bHasTarget)
			return false;

//		if (!bTargetInFocus)
//			return false;

		if (Time::GameTimeSeconds < FireTime)
			return false;

		if (GetTargetLocation().Distance(WorldLocation) < MinDistance)
			return false;

		return true;
	}

	UFUNCTION()
	void Fire()
	{
		FVector LaunchDirection = Math::VRandCone(WorldRotation.ForwardVector, Math::DegreesToRadians(SpreadAngle));

		if (bUseTargetMovementPrediction)
		{			
			FVector ToTarget = CurrentTarget.ActorLocation - WorldLocation;
			float ProjectileSpeed = ProjectileClass.GetDefaultObject().Speed;
			float TimeToImpact = ToTarget.Size() / ProjectileSpeed;

			auto TargetBike = Cast<AGravityBikeFree>(CurrentTarget);
			if (TargetBike == nullptr)
				TargetBike = GravityBikeFree::GetGravityBike(Cast<AHazePlayerCharacter>(CurrentTarget));

			FVector PredictedLocation = CurrentTarget.ActorLocation + TargetBike.ActorVelocity.VectorPlaneProject(UpVector) * TimeToImpact * TargetMovementPredictionMultiplier;

			auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			auto HitResult = Trace.QueryTraceSingle(PredictedLocation, PredictedLocation - FVector::UpVector * 3000.0);
			if (HitResult.bBlockingHit)
				PredictedLocation = HitResult.Location;

			FVector ToPredictedLocation = PredictedLocation - WorldLocation;
			LaunchDirection = Math::VRandCone(ToPredictedLocation.SafeNormal, Math::DegreesToRadians(SpreadAngle));

//			Debug::DrawDebugLine(WorldLocation, WorldLocation + ToPredictedLocation, FLinearColor::Red, 40.0, 0.1);
		}

		CrumbFire(LaunchDirection);

		ShotsFired++;

		if (MagSize > 0 && ShotsFired >= MagSize)
		{
			ShotsFired = 0;
			FireTime += ReloadTime;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbFire(FVector LaunchDirection)
	{
		ASkylineBossTankAutoCannonProjectile Projectile = SpawnActor(ProjectileClass, bDeferredSpawn = true);
		Projectile.Instigator = Owner;
		FinishSpawningActor(Projectile);

		Projectile.ActorLocation = GetSpawnLocation();
		Projectile.ActorQuat = LaunchDirection.ToOrientationQuat();

		FireTime = Time::GameTimeSeconds + FireInterval;

		// Increment what muzzle we use
		if(!MuzzleLocations.IsEmpty())
			MuzzleIndex = (MuzzleIndex + 1) % MuzzleLocations.Num();

		FSkylineBossTankAutoCannonProjectileOnFireEventData EventData;
		EventData.Location = Projectile.ActorLocation;
		EventData.Direction = Projectile.ActorForwardVector;
		EventData.FiredAmount = ShotsFired;
		EventData.MagazinSize = MagSize;
		EventData.ReloadTime = ReloadTime;
		EventData.Turret = this;

		USkylineBossTankAutoCannonProjectileEventHandler::Trigger_OnFire(Projectile, EventData);

		//Audio on tank/ship
		USkylineBossTankAutoCannonProjectileEventHandler::Trigger_OnFire(Cast<AHazeActor>(Owner), EventData);		
	}

	FVector GetSpawnLocation() const
	{
		if(MuzzleLocations.IsEmpty())
			return WorldLocation;

		return WorldTransform.TransformPosition(MuzzleLocations[MuzzleIndex]);
	}

	UFUNCTION()
	void AddTarget(AHazeActor TargetActor)
	{
		Targets.Add(TargetActor);
	}

	UFUNCTION(BlueprintPure)
	bool HasTarget()
	{
		return bHasTarget;
	}

	UFUNCTION(BlueprintPure)
	FVector GetTargetLocation()
	{
		if (!IsValid(CurrentTarget))
			return FVector::ZeroVector;

		return CurrentTarget.ActorLocation;
	}	
};

#if EDITOR
class USkylineBossTankAutoCannonComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossTankAutoCannonComponent;

	FLinearColor Color = FLinearColor::Green;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto AutoCannonComp = Cast<USkylineBossTankAutoCannonComponent>(Component);
	
		DrawArc(AutoCannonComp.WorldLocation, AutoCannonComp.DetectionAngle, AutoCannonComp.DetectionDistance, AutoCannonComp.ForwardVector, Color, 5.0, AutoCannonComp.UpVector, 16, 0.0, true);
		DrawArc(AutoCannonComp.WorldLocation, AutoCannonComp.DetectionAngle, AutoCannonComp.DetectionDistance, AutoCannonComp.ForwardVector, Color, 5.0, AutoCannonComp.RightVector, 16, 0.0, true);
	
		for(const FVector& MuzzleRelativeLocation : AutoCannonComp.MuzzleLocations)
		{
			const FVector MuzzleLocation = AutoCannonComp.WorldTransform.TransformPosition(MuzzleRelativeLocation);
			DrawArrow(MuzzleLocation, MuzzleLocation + AutoCannonComp.ForwardVector * 100, FLinearColor::Yellow);
		}
	}
};
#endif