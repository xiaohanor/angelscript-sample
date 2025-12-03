class UMoonMarketSnailTrailComponent : UDecalTrailComponent
{
	access Internal = protected, UMoonMarketSnailTrailSlipAndFallCapability, UMoonMarketRideSnailCapability;

	access:Internal
	FHazeRuntimeSpline Spline = FHazeRuntimeSpline();


	TArray<float> SplinePointsTimeAdded;

	FVector DecalCompPositionLastFrame;
	float DistSinceLastSplinePoint = 0;

	UPROPERTY(EditAnywhere)
	const float TrailLifetime = 15;
	const float TrailRadius = 20;

	AMoonMarketSnail Snail;
	
	//If you slipped within this radius, this area is safe until you leave the trail again
	UPROPERTY(EditDefaultsOnly)
	const float SafetyRadius = 120;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Snail = Cast<AMoonMarketSnail>(Owner);
		DecalLifetime = TrailLifetime + 5;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		CheckSplineLength();
		CheckPlayersDistToSpline();

		float Delta = WorldLocation.Distance(DecalCompPositionLastFrame);
		DistSinceLastSplinePoint += Delta;
		
		if(DistSinceLastSplinePoint >= TrailRadius * 2)
		{
			DistSinceLastSplinePoint = 0;
			Spline.AddPoint(WorldLocation);
			SplinePointsTimeAdded.Add(Time::GameTimeSeconds);
		}

		DecalCompPositionLastFrame = WorldLocation;
	}

	void CheckPlayersDistToSpline()
	{
		if(Spline.Length <= KINDA_SMALL_NUMBER)
			return;

		for(auto Player : Game::GetPlayers())
		{
			if(Player == Snail.InteractingPlayer)
				continue;

			if(UMoonMarketShapeshiftComponent::Get(Player).IsShapeshiftActive())
				continue;
			
			auto SlipComp = UMoonMarketSnailTrailSlipAndFallComponent::Get(Player);

			FVector ClosestPos = Spline.GetClosestLocationToLocation(Player.ActorLocation);
			float Dist = ClosestPos.Distance(Player.ActorLocation);

			//You are standing on the trail
			if(Dist < TrailRadius)
			{
				//You have slipped too recently
				if(SlipComp.LastSlipLocation.Distance(ClosestPos) <= SafetyRadius)
				{
					//Debug::DrawDebugSphere(ClosestPos, 30, LineColor = FLinearColor::White);
				}
				else //You may slip
				{
					//Debug::DrawDebugSphere(ClosestPos, 30, LineColor = FLinearColor::Green);
					SlipComp.Slip(ClosestPos);
				}
			}
			//Reset slip location
			else if(Dist >= SafetyRadius)
			{
				//Debug::DrawDebugSphere(ClosestPos, 30, LineColor = FLinearColor::Red);
				SlipComp.ResetSlipLocation();
			}
		}
	}
	
	void CheckSplineLength()
	{
		//Spline.DrawDebugSpline();

		for(int i = SplinePointsTimeAdded.Num() - 1; i >= 0; i--)
		{
			if(Time::GameTimeSeconds - SplinePointsTimeAdded[i] < TrailLifetime)
				continue;

			Spline.RemovePoint(i);
			SplinePointsTimeAdded.RemoveAt(i);
		}
	}
};