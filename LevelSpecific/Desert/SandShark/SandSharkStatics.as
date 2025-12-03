namespace SandShark
{
	UFUNCTION(BlueprintPure)
	ASandShark GetAnySandShark()
	{
		return TListedActors<ASandShark>().Single;
	}

	ASandShark GetClosestSharkToLocation(FVector WorldLocation)
	{
		float ClosestDistance = MAX_flt;
		ASandShark ClosestShark = nullptr;
		for (auto Shark : TListedActors<ASandShark>().Array)
		{
			float SquaredDist = WorldLocation.DistSquared(Shark.ActorLocation);
			if (SquaredDist <= ClosestDistance)
			{
				ClosestShark = Shark;
				ClosestDistance = SquaredDist;
			}
		}
		return ClosestShark;
	}

	TArray<USandSharkPlayerComponent> GetPlayerComponents()
	{
		TArray<USandSharkPlayerComponent> PlayerComponents;

		for(auto Player : Game::Players)
		{
			auto PlayerComp = USandSharkPlayerComponent::Get(Player);
			PlayerComponents.Add(PlayerComp);
		}

		return PlayerComponents;
	}

	TArray<AHazePlayerCharacter> GetPlayersOnSand()
	{
		TArray<AHazePlayerCharacter> PlayersOnSand;

		for(auto Player : Game::Players)
		{
			auto PlayerComp = USandSharkPlayerComponent::Get(Player);
			if(!PlayerComp.bHasTouchedSand)
				continue;

			if (Player.IsPlayerDead())
				continue;

			if (Player.IsPlayerRespawning())
				continue;
			
			PlayersOnSand.Add(Player);
		}

		return PlayersOnSand;
	}

	bool IsAnyPlayerOnSand()
	{
		return !GetPlayersOnSand().IsEmpty();
	}

	AHazePlayerCharacter GetClosestPlayerOnSand(FVector Location)
	{
		TArray<AHazePlayerCharacter> PlayersOnSand = GetPlayersOnSand();
		if(PlayersOnSand.IsEmpty())
			return nullptr;

		if(PlayersOnSand.Num() == 1)
			return PlayersOnSand[0];

		if(PlayersOnSand[0].ActorLocation.DistSquared(Location) < PlayersOnSand[1].ActorLocation.DistSquared(Location))
		{
			return PlayersOnSand[0];
		}
		else
		{
			return PlayersOnSand[1];
		}
	}
}