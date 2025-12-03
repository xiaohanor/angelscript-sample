class UFloatingIslandAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FloatingIslandAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AFloatingNightQueenIsland NightQueenIsland;

	int CurrentAttack;
	float FireTime;
	float WaitTime;
	TPerPlayer<AAdultDragon> Dragons;
	AHazePlayerCharacter CurrentPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NightQueenIsland = Cast<AFloatingNightQueenIsland>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetDragonsWithinRange();

		if (CurrentPlayer == nullptr)
			return;

		if (Dragons[Game::Mio] == nullptr && Dragons[Game::Mio] == nullptr)
			return;

		if (Time::GameTimeSeconds < WaitTime)
			return;

		//Messy solution for now
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + NightQueenIsland.FireRate;

			if (Dragons[CurrentPlayer] != nullptr)
			{
				NightQueenIsland.SpawnProjectile(CurrentPlayer);
			}
			else
			{
				CurrentPlayer = CurrentPlayer.OtherPlayer;

				if (Dragons[CurrentPlayer] != nullptr)
					NightQueenIsland.SpawnProjectile(CurrentPlayer);
			}

			CurrentAttack++;

			if (CurrentAttack > NightQueenIsland.AttacksPerPlayer)
			{
				CurrentAttack = 0;
				CurrentPlayer = CurrentPlayer == Game::Mio ? Game::Zoe : Game::Mio;
				WaitTime = Time::GameTimeSeconds + NightQueenIsland.WaitDuration;
			}
		}
	}	

	void SetDragonsWithinRange()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Dist = (Player.ActorLocation - NightQueenIsland.ActorLocation).Size();

			if (Dist < NightQueenIsland.AttackRange)
			{
				if (CurrentPlayer == nullptr)
					CurrentPlayer = Player;
				
				// Dragons[Player] = UPlayerAdultDragonComponent::Get(Player).AdultDragon;
			}
			else 
			{
				Dragons[Player] = nullptr;
			}
		}
	}
}