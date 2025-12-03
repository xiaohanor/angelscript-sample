// class USoundDefPassby : USoundDefPassbyObject
// {
// 	TMap<AHazePlayerCharacter, FVector> TrackedPlayerLocations;
// 	FVector LastPassbyObjectLocation;

// 	float CurrentCooldownTimer = 0.0;

// 	UFUNCTION(BlueprintOverride)
// 	void SetupPassbyObject()
// 	{
// 		for(AHazePlayerCharacter Player : Game::GetPlayers())
// 		{
// 			TrackedPlayerLocations.Add(Player, Player.GetActorLocation());
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void QueryPassby(float DeltaSeconds)
// 	{
// 		QueryPassby_Internal(DeltaSeconds);

// 		UpdateTrackedPositions();

// 		if(CurrentCooldownTimer > 0.0)
// 			CurrentCooldownTimer -= DeltaSeconds;
// 	}

// 	void QueryPassby_Internal(float DeltaSeconds)
// 	{
// 		AHazePlayerCharacter PlayerTarget = GetCurrentTarget();

// 		if(PlayerTarget == nullptr)
// 			return;		

// 		FVector PassbyObjectVelo = PassbyAudioComp.GetWorldLocation() - LastPassbyObjectLocation;
// 		FVector RelVelo = GetRelativeVelocity(PlayerTarget, DeltaSeconds);

// 		FVector PassbyTargetVector = RelVelo * ApexTime;
// 		FVector NormalizedTargetVector = PassbyObjectVelo.GetSafeNormal();

// 		FVector NormalizedDir = GetDirectionToTarget(PlayerTarget);

// 		if(RelVelo.IsNearlyZero())
// 			return;

// 		float RelativeSpeed = RelVelo.Size() / DeltaSeconds;
// 		if(RelativeSpeed < MinRelativeVelocity)
// 			return;

// 		const float DotAngle = NormalizedDir.DotProduct(NormalizedTargetVector);
// 		if(DotAngle < MinVelocityAngle)
// 			return;

// 		float DistanceToTarget = PlayerTarget.GetActorLocation().Distance(PassbyAudioComp.GetWorldLocation());	
		
// 		if(MaxTrackingDistance > 0
// 		&& MaxTrackingDistance < DistanceToTarget)
// 			return;

// 		if(DistanceToTarget < PassbyTargetVector.Size()
// 		&& CurrentCooldownTimer <= 0.0)
// 		{
// 			FPassbyResult PassbyResult;

// 			PassbyResult.ObserverAngle = DotAngle;
// 			PassbyResult.ObserverDistance = DistanceToTarget;
// 			PassbyResult.NormalizedObserverDistance = DistanceToTarget / MaxTrackingDistance;
// 			PassbyResult.PassbyAudioComponent = PassbyAudioComp;
// 			PassbyResult.PlayerObserver = PlayerTarget;
// 			PassbyResult.RelativeSpeed = RelativeSpeed;

// 			TriggerPassby(PassbyResult);			
// 			CurrentCooldownTimer = CooldownTime;
// 		}
// 	}

// 	AHazePlayerCharacter GetCurrentTarget()
// 	{
// 		switch(ObserverTarget)
// 		{
// 			case(EHazeDopplerObserverTargetType::BothPlayers):
// 			{
// 				return TEMP_GetClosestPlayer();
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

// 	FVector GetRelativeVelocity(AHazePlayerCharacter PlayerTarget, float DeltaSeconds)
// 	{
// 		FVector LastTrackedPosition;
// 		TrackedPlayerLocations.Find(PlayerTarget, LastTrackedPosition);
		
// 		FVector PlayerTargetVelocity = PlayerTarget.GetActorLocation() - LastTrackedPosition;
// 		FVector PassbyObjectVelocity = PassbyAudioComp.GetWorldLocation() - LastPassbyObjectLocation;
		
// 		return (PassbyObjectVelocity - PlayerTargetVelocity) / DeltaSeconds;		
// 	}

// 	FVector GetDirectionToTarget(AHazePlayerCharacter PlayerTarget)
// 	{
// 		return (PlayerTarget.GetActorLocation() - PassbyAudioComp.GetWorldLocation()).GetSafeNormal();
// 	}

// 	AHazePlayerCharacter TEMP_GetClosestPlayer()
// 	{
// 		float MinDistance = MAX_flt;
// 		AHazePlayerCharacter CurrClosestPlayer = nullptr;

// 		for(AHazePlayerCharacter& Player : Game::GetPlayers())
// 		{
// 			float DistSqrd = Player.GetActorLocation().DistSquared(PassbyAudioComp.GetWorldLocation());
// 			if(DistSqrd < MinDistance)
// 			{
// 				MinDistance = DistSqrd;
// 				CurrClosestPlayer = Player;
// 			}
// 		}

// 		return CurrClosestPlayer;
// 	}

// 	void UpdateTrackedPositions()
// 	{
// 		for(AHazePlayerCharacter& Player : Game::GetPlayers())
// 		{
// 			TrackedPlayerLocations.FindOrAdd(Player) = Player.GetActorLocation();
// 		}

// 		LastPassbyObjectLocation = PassbyAudioComp.GetWorldLocation();
// 	}

// }