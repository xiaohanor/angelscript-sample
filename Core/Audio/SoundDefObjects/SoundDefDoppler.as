// class USoundDefDoppler : USoundDefDopplerObject
// {
// 	UFUNCTION(BlueprintOverride)
// 	void SetupDopplerObject()
// 	{
// 		for(AHazePlayerCharacter& Player : Game::GetPlayers())
// 		{
// 			TrackedPlayerLocations.Add(Player, Player.GetActorLocation());
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void CalculateDopplerValue(float DeltaSeconds)
// 	{
// 		if(!bIsActive)
// 			return;

// 		CalculateDopplerValue_Internal(DeltaSeconds);

// 		UpdateTrackedPositions();
// 	}

// 	void CalculateDopplerValue_Internal(float DeltaSeconds)
// 	{
// 		AHazePlayerCharacter PlayerTarget = GetFrameTarget();

// 		if(PlayerTarget == nullptr)
// 			return;

// 		FVector CurrentTargetLocation;
// 		FVector LastTargetLocation;
// 		GetLocationFromFrameTarget(PlayerTarget, CurrentTargetLocation, LastTargetLocation);		

// 		float DistanceToTarget = DopplerAudioComp.GetWorldLocation().Distance(CurrentTargetLocation);
// 		float DistanceDelta = LastObjectDistanceToTarget - DistanceToTarget;

// 		if(DistanceToTarget > MaxTrackingDistance)
// 			return;	

// 		Normalize distance over our wanted ranges
// 		const float NormalizedDistance = Math::Lerp(1.0, 0.0, Math::GetPercentageBetween(MinTrackingDistance, MaxTrackingDistance, DistanceToTarget));
// 		const float PowDistance = Math::Pow(NormalizedDistance, CurvePower);

// 		Normalize distance over our wanted ranges
// 		const float RelativeSpeed = DistanceDelta / DeltaSeconds;	

// 		const float RelVelo = Math::GetMappedRangeValueClamped(FVector2D(-MaxRelativeSpeed, MaxRelativeSpeed), FVector2D(-1.0, 1.0), RelativeSpeed);

// 		Scale by our distance
// 		CurrentDopplerValue = RelVelo * PowDistance;

// 		Apply Smoothing	
// 		CurrentDopplerValue = Math::Lerp(CurrentDopplerValue, LastDopplerValue, 0.0);

// 		LastDopplerValue = CurrentDopplerValue;
// 		LastObjectDistanceToTarget = DistanceToTarget;
// 	}

// 	float GetNormalizedDistanceToTarget(float RawDistance)
// 	{
// 		const float NormalizedDist = Math::Lerp(1.0, 0.0, Math::GetPercentageBetween(MinTrackingDistance, MaxTrackingDistance, RawDistance));
// 		return Math::Clamp(NormalizedDist, 0.0, 1.0);
// 	}
	
// 	AHazePlayerCharacter GetFrameTarget()
// 	{
// 		switch(ObserverTarget)
// 		{
// 			case(EHazeDopplerObserverTargetType::BothListeners):
// 			{
// 				return DopplerAudioComp.GetClosestPlayer();
// 			}
// 			case(EHazeDopplerObserverTargetType::BothPlayers):
// 			{
// 				return DopplerAudioComp.GetClosestPlayer();
// 			}
// 			case(EHazeDopplerObserverTargetType::Mio):
// 			{
// 				return Game::GetMio();
// 			}
// 			default:
// 			{
// 				return Game::GetZoe();
// 			}
// 		}

// 		return nullptr;
// 	}

// 	void GetLocationFromFrameTarget(AHazePlayerCharacter Player, FVector& OutCurrentTargetLocation, FVector& OutLastTargetLocation)
// 	{
// 		if(ObserverTarget == EHazeDopplerObserverTargetType::BothListeners)
// 		{
// 			OutCurrentTargetLocation = Player.PlayerListener.GetWorldLocation();
// 			TrackedListenerLocations.Find(Player.PlayerListener, OutLastTargetLocation);
// 		}
// 		else
// 		{
// 			OutCurrentTargetLocation = Player.GetActorLocation();
// 			TrackedPlayerLocations.Find(Player, OutLastTargetLocation);
// 		}		
// 	}

// 	FVector GetDirectionToTarget(AHazePlayerCharacter PlayerTarget)
// 	{
// 		return (PlayerTarget.GetActorLocation() - DopplerAudioComp.GetWorldLocation()).GetSafeNormal();
// 	}

// 	void UpdateTrackedPositions()
// 	{
// 		for(AHazePlayerCharacter& Player : Game::GetPlayers())
// 		{
// 			TrackedPlayerLocations.FindOrAdd(Player) = Player.GetActorLocation();

// 			if(ObserverTarget == EHazeDopplerObserverTargetType::BothListeners)
// 			{
// 				TrackedListenerLocations.FindOrAdd(Player.PlayerListener) = Player.PlayerListener.GetWorldLocation();
// 			}
// 		}

// 		LastObjectLocation = DopplerAudioComp.GetWorldLocation();
// 	}
// }