class ASanctuaryBossSlideGhostProjectileManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	
	UPROPERTY(EditAnywhere)
	bool bShouldFire = true;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossSlideGhostProjectile> ProjectileClass;

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

		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		
	
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
	
		if(bShouldFire)
		{
			bShouldFire = false;
			SpawnGhostProjectile(Player);
		}
		
	}



	UFUNCTION()
	void SpawnGhostProjectile(AHazePlayerCharacter Player)
	{
		
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
	}
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldFire)
		{
			
		}

	}
};