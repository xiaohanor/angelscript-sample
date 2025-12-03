class ASummitBabyDragonLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION(BlueprintCallable, Category = "Egg Backpacks")
	void ResetEgg(EHazeSelectPlayer PlayerSelect)
	{
		TArray<AHazePlayerCharacter> PlayersToResetEggOn;

		if(PlayerSelect == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToResetEggOn.Add(Player);
			}
		}
		else if(PlayerSelect == EHazeSelectPlayer::Mio)
			PlayersToResetEggOn.Add(Game::GetMio());
		else if(PlayerSelect == EHazeSelectPlayer::Zoe)
			PlayersToResetEggOn.Add(Game::GetZoe());

		for(auto Player : PlayersToResetEggOn)
		{
			auto BackpackComp = USummitEggBackpackComponent::Get(Player);
			if(BackpackComp == nullptr)
				continue;

			if(BackpackComp.bIsHoldingEgg)
				continue;
			
			BackpackComp.bResetRequested = true;
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Egg Chase")
	void ToggleChaseRespawnSystem(EHazeSelectPlayer PlayerSelect, bool bToggleOn)
	{
		for(auto Player : Game::GetPlayersSelectedBy(PlayerSelect))
		{
			if(bToggleOn)
			{
				//Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawned"));
				Player.ResetStickyRespawnPoints();
				//TEMPORAL_LOG(Player, "Egg Chase Respawn").PersistentStatus("On", FLinearColor::Green);
			}
			else
			{
				//Player.ClearRespawnPointOverride(this);
				//TEMPORAL_LOG(Player, "Egg Chase Respawn").PersistentStatus("Off", FLinearColor::Red);
			}
		}
	}

	UFUNCTION()
	private bool OnRespawned(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
 		if(Player.OtherPlayer.IsPlayerDead())
			return false;
		
		auto MoveComp = UPlayerMovementComponent::Get(Player.OtherPlayer);
		if(!MoveComp.IsOnWalkableGround())
			return false;
		
		OutLocation.RespawnRelativeTo = Player.OtherPlayer.RootComponent;
		OutLocation.RespawnWithVelocity = Player.OtherPlayer.ActorVelocity;
		OutLocation.bRecalculateOnRespawnTriggered = true;
		Player.SnapCameraBehindPlayer();

		TEMPORAL_LOG(Player, "Egg Chase Respawn")
			.DirectionalArrow("Relative Location", OutLocation.RespawnRelativeTo.WorldLocation, OutLocation.RespawnTransform.Location, 10, 4000, FLinearColor::LucBlue)
			.DirectionalArrow("Relative Rotation Forward", Player.ActorLocation + FVector::UpVector * 200, OutLocation.RespawnTransform.Rotation.ForwardVector * 500, 10, 4000, FLinearColor::Red)
		;
		return true;
	}
}