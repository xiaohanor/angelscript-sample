class USkylineBossLowAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);

	USkylineBossFootStompComponent FootStompComponent;

	float FireRate = 0.15;
	float FireTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FootStompComponent = Boss.FootStompComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 30.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireTime = Time::GameTimeSeconds;

		Boss.BP_LowState();

		Owner.BlockCapabilities(SkylineBossTags::SkylineBossForceField, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(SkylineBossTags::SkylineBossForceField, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			Fire();
			FireTime = Time::GameTimeSeconds + FireRate; 
		}

		if(HasControl())
		{
			FVector LookAtDirection = Boss.HeadPivot.ForwardVector;
			if (Boss.GetDistanceTo(Boss.LookAtTarget.Get()) > 500.0)
				LookAtDirection = (Boss.LookAtTarget.Get().ActorLocation - Boss.HeadPivot.WorldLocation).GetSafeNormal();

			FVector Torque = Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.ForwardVector.CrossProduct(LookAtDirection) * Boss.Settings.LookAtSpeed)
						+ Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.UpVector.CrossProduct(FVector::UpVector) * Boss.Settings.LookAtSpeed * 0.2)
						- Boss.AngularVelocity * Boss.Settings.LookAtDrag;

			Boss.AngularVelocity += Torque * DeltaTime;

			FRotator Rotation = (Boss.HeadPivot.ComponentQuat * FQuat(Boss.AngularVelocity.SafeNormal, Boss.AngularVelocity.Size() * DeltaTime)).Rotator();
			Rotation.Pitch = Math::Max(-30.0, Rotation.Pitch);
			Rotation.Roll = 0.0;

			Boss.HeadPivot.SetWorldRotation(Rotation);
		}
		else
		{
			ApplyCrumbSyncedHeadPivotRotation();
		}
	}

	void Fire()
	{
	//	FTransform Transform = Boss.LowPivot.WorldTransform;
		FTransform Transform = Boss.Mesh.WorldTransform;

	//	int NumOfProjectiles = FootStompComponent.NumOfProjectiles;
		int NumOfProjectiles = 1;

		TArray<ASkylineBossProjectile> SpawnedProjectiles;

		for (int i = 0; i < NumOfProjectiles; i++)
		{
		//	FVector RotatedOffset = (Transform.Rotation.ForwardVector).RotateAngleAxis(i * (360.0 / NumOfProjectiles), Transform.Rotation.UpVector);
			FVector RotatedOffset = Transform.Rotation.ForwardVector;

		//	Debug::DrawDebugLine(Transform.Location, Transform.Location + RotatedOffset * 5000.0, FLinearColor::Blue, 50.0, 1.0);

			auto Projectile = Cast<ASkylineBossProjectile>(
				SpawnActor(
					FootStompComponent.ProjectileClass,
					Transform.Location,
					RotatedOffset.ToOrientationRotator(),
					bDeferredSpawn = true
				)
			);

			Projectile.Velocity = RotatedOffset * 5000.0;

			SpawnedProjectiles.Add(Projectile);
		}

		for (auto SpawnedProjectile : SpawnedProjectiles)
		{
			for (auto ActorToIgnore : SpawnedProjectiles)
				SpawnedProjectile.ActorsToIgnore.Add(ActorToIgnore);

			SpawnedProjectile.ActorsToIgnore.Add(Owner);
			SpawnedProjectile.ActorsToIgnore.Add(FootStompComponent.PlacedLeg);
			FinishSpawningActor(SpawnedProjectile);
		}		
	}
}