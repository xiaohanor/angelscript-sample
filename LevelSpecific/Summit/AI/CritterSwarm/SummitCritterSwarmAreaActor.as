class ASummitCritterSwarmAreaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = n"NoCollision";
	default SphereComp.SphereRadius = 70000.0;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = SphereComp)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(20.0));
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USummitCritterSwarmAreaRegistry AreaRegistry = Game::GetSingleton(USummitCritterSwarmAreaRegistry);
		AreaRegistry.Areas.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		USummitCritterSwarmAreaRegistry AreaRegistry = Game::GetSingleton(USummitCritterSwarmAreaRegistry);
		AreaRegistry.Areas.Remove(this);
	}

	bool IsWithin(FVector Location, float Fraction = 1.0) const
	{
		return (Location.IsWithinDist(SphereComp.WorldLocation, SphereComp.SphereRadius * Fraction * SphereComp.WorldScale.Max));
	}

	FVector ProjectToArea(FVector Location) const
	{
		FVector Dir = (Location - SphereComp.WorldLocation).GetSafeNormal();
		return SphereComp.WorldLocation + Dir * SphereComp.SphereRadius * SphereComp.WorldScale.Max;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
	 	// bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSolidSphere(SphereComp.WorldLocation, SphereComp.SphereRadius * SphereComp.WorldScale.Max, FLinearColor::Blue * 0.3, 0.0, 12);
#endif
	}
}

class USummitCritterSwarmAreaRegistry : UObject
{
	TArray<ASummitCritterSwarmAreaActor> Areas;

	ASummitCritterSwarmAreaActor GetBestArea(AHazeActor Actor, FHazeActorSpawnParameters SpawnParameters)
	{
		// Use area closest to spawn location/scenepoint/end of spline
		FVector ProbeLoc = Actor.ActorLocation;
		if (SpawnParameters.Spawner != nullptr)
		{
			if (SpawnParameters.Scenepoint != nullptr)
				ProbeLoc = SpawnParameters.Scenepoint.WorldLocation;
			else if (SpawnParameters.Spline != nullptr)
				ProbeLoc = SpawnParameters.Spline.GetWorldLocationAtSplineFraction(1.0);
			else 
				ProbeLoc = SpawnParameters.Location;
		}

		float BestDistSqr = BIG_NUMBER;
		ASummitCritterSwarmAreaActor BestArea = nullptr;
		float BestOutsideDistSqr = BIG_NUMBER;
		ASummitCritterSwarmAreaActor BestOutsideArea = nullptr;
		for (ASummitCritterSwarmAreaActor Area : Areas)
		{
			FVector AreaCenter = Area.SphereComp.WorldLocation;
			if (!AreaCenter.IsWithinDist(ProbeLoc, Area.SphereComp.SphereRadius * 2.0 * Area.SphereComp.WorldScale.Max))
				continue; // Ignore far away areas altogether

			float DistSqr = AreaCenter.DistSquared(ProbeLoc);
			if (Area.IsWithin(ProbeLoc))
			{
				if (DistSqr < BestDistSqr)
				{
					BestDistSqr = DistSqr;
					BestArea = Area;
				}
			}
			else if (DistSqr < BestOutsideDistSqr)
			{
				BestOutsideDistSqr = DistSqr;
				BestOutsideArea = Area;
			}
		}
		if (BestArea == nullptr)
			BestArea = BestOutsideArea;
		return BestArea;
	}
}
