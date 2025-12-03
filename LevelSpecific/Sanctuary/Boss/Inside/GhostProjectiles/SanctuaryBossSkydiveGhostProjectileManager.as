class ASanctuaryBossSkydiveGhostProjectileManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float SpawnInterval = 2.0;
	

	UPROPERTY(EditAnywhere)
	float StartDelay = 3.0;

	UPROPERTY(EditAnywhere)
	bool bShouldFire = true;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossSkydiveGhostProjectile> ProjectileClass;

	TArray<UHazeSplineComponent> SplineComps;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		
		for (auto AttachedActor : AttachedActors)
		{
			UHazeSplineComponent SplineComp;
			SplineComp = UHazeSplineComponent::Get(AttachedActor);

			if (SplineComp != nullptr)
				SplineComps.Add(SplineComp);
		}

		TargetPlayer = Game::Mio;

		if (SpawnInterval > 0.0)
		{
			Timer::SetTimer(this, n"CallSpawnGhostProjectile", SpawnInterval, true, StartDelay);
		}
	}

	UFUNCTION()
	private void CallSpawnGhostProjectile()
	{
		TargetPlayer = TargetPlayer.OtherPlayer;
		SpawnGhostProjectile(TargetPlayer);
	}

	UFUNCTION()
	void SpawnGhostProjectile(AHazePlayerCharacter Player)
	{
		if(!bShouldFire)
			return;
		
		
		UHazeSplineComponent ClosestSpline = nullptr;
		float ClosestDistance = MAX_flt;
		bool bStartLocation = true;

		FVector ClosestLocation = FVector();
		for (auto SplineComp : SplineComps) 
		{
			if (SplineComp.GetWorldLocationAtSplineFraction(0).Distance(Player.ActorLocation) < ClosestDistance)
			{
				ClosestDistance = SplineComp.GetWorldLocationAtSplineFraction(0).Distance(Player.ActorLocation);
				ClosestSpline = SplineComp;
				bStartLocation = true;
			}

			if (SplineComp.GetWorldLocationAtSplineFraction(1).Distance(Player.ActorLocation) < ClosestDistance)
			{
				ClosestDistance = SplineComp.GetWorldLocationAtSplineFraction(1).Distance(Player.ActorLocation);
				ClosestSpline = SplineComp;
				bStartLocation = false;
			}
		}

		if (ClosestSpline != nullptr)
		{
			FVector SpawnLocation = ClosestSpline.GetWorldLocationAtSplineFraction(bStartLocation ? 1.0 : 0.0);
			FRotator SpawnRotation = ClosestSpline.GetWorldRotationAtSplineFraction(bStartLocation ? 1.0 : 0.0).Rotator();

			auto SpawnedProjectile = SpawnActor(ProjectileClass, SpawnLocation, SpawnRotation, bDeferredSpawn = true);
			
			SpawnedProjectile.SplineComp = ClosestSpline;
			SpawnedProjectile.bReversed = bStartLocation;

			FinishSpawningActor(SpawnedProjectile);
		}
		bShouldFire = false;
	}
};