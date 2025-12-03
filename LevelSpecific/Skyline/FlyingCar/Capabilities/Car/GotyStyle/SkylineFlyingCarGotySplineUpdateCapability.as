
class USkylineFlyingCarGotySplineUpdateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarSplineUpdate);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASkylineFlyingCar Car;
	USkylineFlyingCarGotySettings Settings;

	float TimeToNextSearch = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Car.bSelectNewHighwayIsblockedUntilCurrentIsReached)
			return false;

		if (Car.IsSplineHopping())
			return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Car.bSelectNewHighwayIsblockedUntilCurrentIsReached)
			return true;

		if (Car.IsSplineHopping())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TimeToNextSearch = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			TimeToNextSearch -= DeltaTime;

			if (ShouldSearchForSpline())
			{
				ASkylineFlyingHighway NewHighWay = FindBestHighway();
				if(NewHighWay != nullptr && NewHighWay != Car.ActiveHighway)
				{
					CrumbSetHighWay(NewHighWay);
				}
			}
		}	
	}

	bool ShouldSearchForSpline()
	{
		if (Car.IsSplineHopping())
			return false;

		if (Car.IsInSplineTunnel())
			return false;

		FSkylineFlyingCarSplineParams SplineData;
		if (!Car.GetSplineDataAtPosition(Car.ActorLocation, SplineData))
			return true;

		if (SplineData.bHasReachedEndOfSpline)
			return true;

		if(TimeToNextSearch <= 0)
		{
			TimeToNextSearch = 0.25;
			return true;
		}

		return false;
	}

	ASkylineFlyingHighway FindBestHighway() const
	{
		FSkylineFlyingHighwayQuery BestQuery;
		ASkylineFlyingHighway BestHighway = nullptr;

		TListedActors<ASkylineFlyingHighway> Highways;
		for(auto Highway : Highways)
		{
			FSkylineFlyingHighwayQuery Query(Car);
			if (!Highway.Evaluate(Query))
				continue;

			// Look for a better one
			if (Query > BestQuery)
			{
				BestQuery = Query;
				BestHighway = Highway;
			}
		}

		return BestHighway;
	}

	ASkylineFlyingHighway FindClosestHighway() const
	{
		ASkylineFlyingHighway ClosestHighway = nullptr;
		float ClosestDistance = BIG_NUMBER;
		bool bHasFoundInside = false;

		TListedActors<ASkylineFlyingHighway> AllHighways;
		for(auto Highway : AllHighways)
		{
			if (!Highway.IsEnabled())
				continue;

			FSplinePosition SplinePosition = Highway.HighwaySpline.GetClosestSplinePositionToWorldLocation(Car.ActorLocation);

			FVector ClosestLocation = SplinePosition.WorldLocation;
			float Distance = ClosestLocation.DistSquared(Car.ActorLocation);	

			FVector DirToPosition = (ClosestLocation - Car.ActorLocation).GetSafeNormal();
			SplinePosition.Move(Car.ActorVelocity.DotProduct(DirToPosition));
			DirToPosition = (ClosestLocation - Car.ActorLocation).GetSafeNormal();
			float AheadAmount = Car.ActorForwardVector.DotProductNormalized(DirToPosition);

			float HighwayRadius = Highway.GetRadius();

			bool bIsInside = Distance <= Math::Square(HighwayRadius + 10);
			bool bCanGrab = Distance <= Math::Square(HighwayRadius + Settings.SplineGrabDistance) && AheadAmount >= 0.5;

			if(bIsInside && !bHasFoundInside)
			{
				ClosestDistance = Distance;
				bHasFoundInside = true;
				ClosestHighway = Highway;
				continue;
			}

			if(bHasFoundInside && !bIsInside)
			{
				continue;
			}

			if(!bCanGrab)
			{
				continue;
			}

			Distance *= 1.0 - AheadAmount;
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestHighway = Highway;
				continue;
			}
		}

		return ClosestHighway;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHighWay(ASkylineFlyingHighway NewHighWay)
	{
		Car.SetActiveHighway(NewHighWay);
	}
}