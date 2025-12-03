UCLASS(Abstract)
class APiranha_Tundra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// code needs to know how big the Niagara Spawn Radius is. Keep this mirrored with the value in Niagara.
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float FishSpawnRadius = 280.0;

	UPROPERTY(BlueprintReadOnly)
	USphereComponent ClosestVolume_Mio = nullptr;

	UPROPERTY(BlueprintReadOnly)
	USphereComponent ClosestVolume_Zoe = nullptr;

	// volumes found when construction script runs.
	UPROPERTY(BlueprintReadOnly)
	TArray<USphereComponent> SpawnVolumes;

	// BP will set these since we need to add the niagara comp on the BP layer
	UPROPERTY()
	FVector FishFlockCenter_Mio = FVector::ZeroVector;
	UPROPERTY()
	FVector FishFlockCenter_Zoe = FVector::ZeroVector;

	float Timestamp_UpdateClosestSpawnVolume = -1.0;
	
	UPlayerPoleClimbComponent PoleClimbComp_Zoe = nullptr;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// find attached spawn volumes.
		TArray<UActorComponent> FoundComponents;
		GetAllComponents(USphereComponent, FoundComponents);
		SpawnVolumes.Reset(FoundComponents.Num());
		for(auto IterComp : FoundComponents)
		{
			USphereComponent FoundSpawnVolume = Cast<USphereComponent>(IterComp);
			SpawnVolumes.Add(FoundSpawnVolume);
		}
	}

	// returns true if at least one of the players has found a volume within range.
	UFUNCTION(BlueprintCallable)
	bool UpdateClosestSpawnVolumeForPlayers(const float TimeBetweenUpdatesWhenOutOfRange = 1.0)
	{
		// stagger the updates when players are out-of-range.
		if(ClosestVolume_Mio == nullptr && ClosestVolume_Zoe == nullptr)
		{
			const float TimeSinceUpdate = Time::GetGameTimeSince(Timestamp_UpdateClosestSpawnVolume);
			if(TimeSinceUpdate < TimeBetweenUpdatesWhenOutOfRange)
			{
				return false;
			}
		}

		ClosestVolume_Mio = FindClosestSpawnVolumeWithinRange(Game::Mio);
		ClosestVolume_Zoe = FindClosestSpawnVolumeWithinRange(Game::Zoe);
		Timestamp_UpdateClosestSpawnVolume = Time::GetGameTimeSeconds();

		// prevent all the actors from updating the same frame.
		Timestamp_UpdateClosestSpawnVolume -= Math::RandRange(0.0, TimeBetweenUpdatesWhenOutOfRange);

		if(ClosestVolume_Mio == nullptr && ClosestVolume_Zoe == nullptr)
		{
			// both players are out of range
			return false;
		}

		// atleast 1 player within range.
		return true;
	}

	// finds closest volume within that is within the threshold
	USphereComponent FindClosestSpawnVolumeWithinRange(AHazePlayerCharacter Player) const
	{
		const FVector PlayerPos = Player.GetActorLocation();

		USphereComponent ClosestVolume = nullptr;
		float ClosestDistanceSQ = BIG_NUMBER;
		for(auto IterSpawnVolume : SpawnVolumes)
		{
			const FVector VolPos = IterSpawnVolume.GetWorldLocation();
			const FVector ConstrainedPlayerPos = FVector(PlayerPos.X, PlayerPos.Y, VolPos.Z);
			const FVector Delta = ConstrainedPlayerPos - VolPos;
			const float DistSQ = Delta.SizeSquared();

			if(DistSQ < ClosestDistanceSQ)
			{
				// volume radius + fishSpawnRadius will dictate when the player is within range.
				const float DistThresholdForVolume = Math::Square(IterSpawnVolume.GetScaledSphereRadius() + FishSpawnRadius);
				if(DistSQ <= DistThresholdForVolume)
				{
					ClosestVolume = IterSpawnVolume;
					ClosestDistanceSQ = DistSQ;
				}
			}
		}

		return ClosestVolume;
	}

	// BP will set these.
	UFUNCTION(BlueprintEvent)
	void GetPiranhaPlayerPositions(FVector&out MioPosition, FVector&out ZoePositions) 
	{
		// MioPosition = FishFlockCenter_Mio;
		// ZoePositions = FishFlockCenter_Zoe;
	}

	/* this helper is done here on angelscript layer because of debug reasons */
	UFUNCTION(BlueprintPure)
	float CalculateVerticalPiranhaProximityFraction(
		AHazePlayerCharacter Player,
		float ReduceHeightBy = 290.0,
		float PowRamp = 2.0
	) 
	{
		const auto PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);

		// Calculate the current PoleClimb height ourselves because its not calculated 
		// at all on remote and they don't want to network it neither 
		const FVector PlayerPos = Player.GetActorLocation();
		const FVector PiranhaPos = Player.IsMio() ? FishFlockCenter_Mio : FishFlockCenter_Zoe;
		const FVector Delta = PlayerPos - PiranhaPos;
		const FVector PoleDirection = PoleClimbComp.Owner.GetActorUpVector();
		float VerticalDistance = Delta.DotProduct(PoleDirection);
		VerticalDistance += 50.0;		// the root, bottom of the pole, has this height
		VerticalDistance = Math::Max(VerticalDistance, 0.0);

		float Frac = PoleClimbComp.CalculateClimbingFraction(VerticalDistance, ReduceHeightBy);
		Frac = Math::Pow(Frac, PowRamp);
		Frac = 1.0 - Frac;

		// auto DebugColor = Player.IsMio() ? FLinearColor::Yellow : FLinearColor::LucBlue;
		// PrintToScreen("VerticalDistance: " + VerticalDistance, 0.0, DebugColor);
		// PrintToScreen("Frac: " + Frac, 0.0, DebugColor);
		// Debug::DrawDebugLine(
		// 	PlayerPos,
		// 	PlayerPos + PoleDirection*1000.0,
		// 	FLinearColor::Yellow,
		// 	10.0,
		// 	0.0
		// );

		return Frac;
	}

};
