struct FSkylineBossFootStompAttackActivateParams
{
	ASkylineBossLeg LastPlacedLeg;
	FVector FootLocation;
	FRotator FootRotation;
	int NumOfProjectiles;
};

class USkylineBossFootStompAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootStompAttack);

	ASkylineBossLeg LastPlacedLeg;
	USkylineBossFootStompComponent FootStompComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FootStompComponent = Boss.FootStompComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossFootStompAttackActivateParams& Params) const
	{
		if(FootStompComponent.PlacedLeg == nullptr)
			return false;
		
		if (LastPlacedLeg == FootStompComponent.PlacedLeg)
			return false;

		Params.LastPlacedLeg = FootStompComponent.PlacedLeg;
		FootStompComponent.PlacedLeg.GetFootLocationAndRotation(Params.FootLocation, Params.FootRotation);
		Params.NumOfProjectiles = FootStompComponent.NumOfProjectiles;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossFootStompAttackActivateParams Params)
	{
		LastPlacedLeg = Params.LastPlacedLeg;
		TArray<AHazeActor> SpawnedProjectiles;

		for (int i = 0; i < Params.NumOfProjectiles; i++)
		{
			FVector RotatedOffset = (Params.FootRotation.ForwardVector).RotateAngleAxis(i * (360.0 / Params.NumOfProjectiles), Params.FootRotation.UpVector);

		//	Debug::DrawDebugLine(Transform.Location, Transform.Location + RotatedOffset * 5000.0, FLinearColor::Blue, 50.0, 1.0);

			auto Projectile = Cast<AHazeActor>(
				SpawnActor(
					FootStompComponent.ProjectileClass,
					Params.FootLocation,
					RotatedOffset.ToOrientationRotator(),
					bDeferredSpawn = true
				)
			);

			FinishSpawningActor(Projectile);

//			Projectile.Velocity = RotatedOffset * 5000.0;

			SpawnedProjectiles.Add(Projectile);
		}

/*
		for (auto SpawnedProjectile : SpawnedProjectiles)
		{
			for (auto ActorToIgnore : SpawnedProjectiles)
				SpawnedProjectile.ActorsToIgnore.Add(ActorToIgnore);

			SpawnedProjectile.ActorsToIgnore.Add(Owner);
			SpawnedProjectile.ActorsToIgnore.Add(FootStompComponent.PlacedLeg);

			FinishSpawningActor(SpawnedProjectile);
		}
*/
	}
}