class AMoonMarketLanternPlayerRespawnVolume : APlayerTrigger
{
	ARespawnPoint CurrentRespawn;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint GraveyardRespawn;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint GraveyardRespawnCompleted;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketCat GraveyardCat;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint MainIslandRespawn;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint MainIslandRespawnCompleted;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	bool bQuestCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
		CurrentRespawn = MainIslandRespawn;

		GraveyardRespawnCompleted.AddActorDisable(this);

		GraveyardCat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if(Player.GetDistanceTo(GraveyardRespawn) < Player.GetDistanceTo(MainIslandRespawn))
		{
			CurrentRespawn = GraveyardRespawn;
		}
		else
		{
			CurrentRespawn = MainIslandRespawn;
		}

		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride, EInstigatePriority::High);
		UPlayerHealthSettings::SetBlockRespawnWhenNoRespawnPointsEnabled(Player, true, this);

		TListedActors<ARespawnPoint> AllRespawnPoints;
		
		if(Player.IsZoe())
		{
			for (ARespawnPoint RespawnPoint : AllRespawnPoints)
			{
				RespawnPoint.bCanZoeUse = false;
			}
		}
		else
		{
			for (ARespawnPoint RespawnPoint : AllRespawnPoints)
			{
				RespawnPoint.bCanMioUse = false;
			}
		}
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		if(Player.GetDistanceTo(GraveyardRespawn) < Player.GetDistanceTo(MainIslandRespawn))
		{
			CurrentRespawn = GraveyardRespawn;
		}
		else
		{
			CurrentRespawn = MainIslandRespawn;
		}

		Player.ClearRespawnPointOverride(this);
		UPlayerHealthSettings::ClearBlockRespawnWhenNoRespawnPointsEnabled(Player, this);

		TListedActors<ARespawnPoint> AllRespawnPoints;
		if(Player.IsZoe())
		{
			for (ARespawnPoint RespawnPoint : AllRespawnPoints)
			{
				RespawnPoint.bCanZoeUse = true;
			}
		}
		else
		{
			for (ARespawnPoint RespawnPoint : AllRespawnPoints)
			{
				RespawnPoint.bCanMioUse = true;
			}
		}
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		bQuestCompleted = true;
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		bQuestCompleted = true;
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		bool bLanternHeld = false;

		for(auto Lantern : TListedActors<AMoonMarketRevealingLantern>().Array)
		{
			if(Lantern.InteractingPlayer == Player)
				bLanternHeld = true;
		}

		if(!bLanternHeld)
		{
			OutLocation.RespawnPoint = MainIslandRespawn;

			OutLocation.RespawnRelativeTo = MainIslandRespawn.RootComponent;
			OutLocation.RespawnTransform = MainIslandRespawn.GetRelativePositionForPlayer(Player);
				
			if (bQuestCompleted)
				OutLocation.RespawnTransform.Rotation = FRotator::MakeFromXZ(-OutLocation.RespawnTransform.Rotation.ForwardVector, FVector::UpVector).Quaternion(); 

			return true;
		}

 		if(Player.OtherPlayer.IsPlayerDead() || !IsPlayerInside(Player.OtherPlayer))
		{
			OutLocation.RespawnPoint = CurrentRespawn;
			OutLocation.RespawnRelativeTo = CurrentRespawn.RootComponent;
			OutLocation.RespawnTransform = CurrentRespawn.GetRelativePositionForPlayer(Player);

			if (bQuestCompleted)
				OutLocation.RespawnTransform.Rotation = FRotator::MakeFromXZ(-OutLocation.RespawnTransform.Rotation.ForwardVector, FVector::UpVector).Quaternion(); 

			return true;
		}

		if(!Player.OtherPlayer.IsOnWalkableGround())
			return false;

		OutLocation.RespawnTransform = Player.OtherPlayer.ActorTransform;
		return true;
	}
};