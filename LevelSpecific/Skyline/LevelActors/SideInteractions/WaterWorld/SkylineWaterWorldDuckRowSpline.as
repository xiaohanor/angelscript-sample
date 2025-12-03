class ASkylineWaterWorldDuckRowSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000;

	TMap<ASkylineWaterWorldWhipToy, float> RegisteredDucks;
	ASkylineWaterWorldWhipToy FrontDuck;
	float FrontDuckDist = 0.0;
	const float DistanceBetweenDucks = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevTogglesSkyline::Skyline.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TListedActors<ASkylineWaterWorldWhipToy> AllToys;
		if (AllToys.Num() > RegisteredDucks.Num())
		{
			RegisteredDucks.Empty(); // some might have been disabled
			TArray<ASkylineWaterWorldWhipToy> Duckies = AllToys.GetArray();
			for (int iDuck = 0; iDuck < Duckies.Num(); ++iDuck)
			{
				if (FrontDuck == nullptr)
					FrontDuck = Duckies[iDuck];
				int ReverseDist = Duckies.Num() - iDuck;
				RegisteredDucks.Add(Duckies[iDuck], -DistanceBetweenDucks * ReverseDist);
				if (DevTogglesSkyline::PoolDucksEasyAccess.IsEnabled())
				{
					if (!Duckies[iDuck].bInPool)
						Duckies[iDuck].SetActorLocation(Game::Zoe.ActorLocation + FVector::UpVector * 300 + FVector::RightVector * 300 * iDuck);
				}
			}
		}

		FrontDuckDist -= 120 * DeltaSeconds;
		FrontDuckDist = Math::Wrap(FrontDuckDist, 0.0, Spline.SplineLength);
		if (DevTogglesSkyline::PoolDucksDraw.IsEnabled())
			Spline.DrawDebug();
	}

	bool IsDuckInThisPool(ASkylineWaterWorldWhipToy Toy) const
	{
		if (!Toy.bInPool)
			return false;
		FVector ClosestSplineLoc = Spline.GetClosestSplineWorldLocationToWorldLocation(Toy.ActorLocation);
		return (ClosestSplineLoc.Dist2D(Toy.ActorLocation)) < 3300;
	}

	bool AreAllDucksInThisPool() const
	{
		for (auto KeyVal : RegisteredDucks)
		{
			if (!IsDuckInThisPool(KeyVal.Key))
				return false;
		}
		return true;
	}

	FTransform GetDucksInARowTargetLocation(ASkylineWaterWorldWhipToy Toy)
	{
		if (RegisteredDucks.IsEmpty())
			return FTransform();
		// float FrontDuckSplineDist = Spline.GetClosestSplineDistanceToWorldLocation(FrontDuck.ActorLocation);
		float Distance = Math::Wrap(RegisteredDucks[Toy] + FrontDuckDist, 0.0, this.Spline.SplineLength);
		FTransform TargetTrans = Spline.GetWorldTransformAtSplineDistance(Distance);
		if (DevTogglesSkyline::PoolDucksDraw.IsEnabled())
		{
			if (Toy == FrontDuck)
			{
				Debug::DrawDebugSphere(TargetTrans.Location, 50, 12, ColorDebug::Yellow);
			}
			else
			{
				Debug::DrawDebugSphere(TargetTrans.Location, 30);
			}
		}
		return TargetTrans;
	}
};