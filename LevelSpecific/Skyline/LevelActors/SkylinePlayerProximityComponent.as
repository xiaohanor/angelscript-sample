event void FSkylinePlayerProximityPlayerEnterSignature(AHazePlayerCharacter Player);
event void FSkylinePlayerProximityPlayerLeaveSignature(AHazePlayerCharacter Player);

struct FSkylinePlayerProximityData
{
	float Distance = MAX_flt;
}

class USkylinePlayerProximityComponent : USceneComponent
{
	// Whether we check distance and trigger events for Mio.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Proximity")
	bool bCanMioUse = false;

	// Whether we check distance and trigger events for Zoe.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Proximity")
	bool bCanZoeUse = false;

	// Maximum player distance from component we consider to be in proximity.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Proximity")
	float ProximityRange = 2000.0;

	// Called when a player has entered proximity.
	UPROPERTY(Category = "Proximity", Meta = (BPCannotCallEvent))
	FSkylinePlayerProximityPlayerEnterSignature OnPlayerEnter;

	// Called when a player has left proximity.
	UPROPERTY(Category = "Proximity", Meta = (BPCannotCallEvent))
	FSkylinePlayerProximityPlayerLeaveSignature OnPlayerLeave;

	private TPerPlayer<FSkylinePlayerProximityData> PlayerData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bCanMioUse && !bCanZoeUse)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float RangeSqr = Math::Square(ProximityRange);
		
		for (auto Player : Game::Players)
		{
			if (!IsEnabledForPlayer(Player))
				continue;
			
			auto& Data = PlayerData[Player];
			float Distance = (Player.ActorCenterLocation - WorldLocation).SizeSquared();

			if (Distance < RangeSqr && Data.Distance > RangeSqr)
				OnPlayerEnter.Broadcast(Player);
			else if (Distance > RangeSqr && Data.Distance < RangeSqr)
				OnPlayerLeave.Broadcast(Player);

			PlayerData[Player].Distance = Distance;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
			return bCanMioUse;

		return bCanZoeUse;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetClosestPlayer() const
	{
		if (PlayerData[Game::Mio].Distance < PlayerData[Game::Zoe].Distance)
			return Game::Mio;
		
		return Game::Zoe;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetFurthestPlayer() const
	{
		if (PlayerData[Game::Mio].Distance > PlayerData[Game::Zoe].Distance)
			return Game::Mio;
		
		return Game::Zoe;
	}
}