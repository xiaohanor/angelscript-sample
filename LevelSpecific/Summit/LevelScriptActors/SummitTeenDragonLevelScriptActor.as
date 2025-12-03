class ASummitTeenDragonLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleTopDown(EHazeSelectPlayer PlayerSelect, bool bActivate)
	{
		TArray<AHazePlayerCharacter> PlayersToActivateTopDownOn;

		if(PlayerSelect == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToActivateTopDownOn.Add(Player);
			}
		}
		else if(PlayerSelect == EHazeSelectPlayer::Mio)
			PlayersToActivateTopDownOn.Add(Game::GetMio());
		else if (PlayerSelect == EHazeSelectPlayer::Zoe)
			PlayersToActivateTopDownOn.Add(Game::GetZoe());

		for(auto Player : PlayersToActivateTopDownOn)
		{
			auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
			if(DragonComp != nullptr)
			{
				if(bActivate)
					DragonComp.ActivateTopDownMode();
				else
					DragonComp.DeactivateTopDownMode();
			}
		}
	}

	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleVerticalInput(EHazeSelectPlayer PlayerSelect, bool bActivate, FInstigator Instigator)
	{
		TArray<AHazePlayerCharacter> PlayersToActivateVerticalInputOn;

		if(PlayerSelect == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToActivateVerticalInputOn.Add(Player);
			}
		}
		else if(PlayerSelect == EHazeSelectPlayer::Mio)
			PlayersToActivateVerticalInputOn.Add(Game::GetMio());
		else if (PlayerSelect == EHazeSelectPlayer::Zoe)
			PlayersToActivateVerticalInputOn.Add(Game::GetZoe());

		for(auto Player : PlayersToActivateVerticalInputOn)
		{
			auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
			if(DragonComp == nullptr)
				continue;

			if(bActivate)
				DragonComp.VerticalInputInstigators.AddUnique(Instigator);
			else
				DragonComp.VerticalInputInstigators.RemoveSingleSwap(Instigator);			
		}
	}

	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleAutoGlideRolling(EHazeSelectPlayer PlayerSelect, bool bActivate, ASplineActor GlideStrafeSpline)
	{
		if(!HasControl())
			return;

		TArray<AHazePlayerCharacter> PlayersToToggleChaseOn;

		if(PlayerSelect == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToToggleChaseOn.Add(Player);
			}
		}
		else if(PlayerSelect == EHazeSelectPlayer::Mio)
			PlayersToToggleChaseOn.Add(Game::GetMio());
		else if (PlayerSelect == EHazeSelectPlayer::Zoe)
			PlayersToToggleChaseOn.Add(Game::GetZoe());

		for(auto Player : PlayersToToggleChaseOn)
		{
			auto ChaseComp = UTeenDragonChaseComponent::Get(Player);
			if(bActivate)
			{
				devCheck(GlideStrafeSpline != nullptr, "Trying to activate auto glide rolling without a spline for it");
				ChaseComp.CrumbActivateChase(GlideStrafeSpline);
			}
			else
			{
				ChaseComp.CrumbDeactivateChase();
			}
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Rolling Lift")
	void ExitRollingLift()
	{
		for(auto Player : Game::Players)
		{
			auto RollingLiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
			if(RollingLiftComp == nullptr)
				continue;

			RollingLiftComp.ExitCurrentRollingLift();
		}
	}

	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleRestrictTailClimbToVertical(bool bActivate = true)
	{
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Game::GetZoe());
		if(ClimbComp != nullptr)
			ClimbComp.bRestrictClimbToVertical = bActivate;
	}

	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleConstrainToScreen(EHazeSelectPlayer PlayerSelect, bool bActivate)
	{
		TArray<AHazePlayerCharacter> PlayersToToggleConstrainOn;

		if(PlayerSelect == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToToggleConstrainOn.Add(Player);
			}
		}
		else if(PlayerSelect == EHazeSelectPlayer::Mio)
			PlayersToToggleConstrainOn.Add(Game::GetMio());
		else if (PlayerSelect == EHazeSelectPlayer::Zoe)
			PlayersToToggleConstrainOn.Add(Game::GetZoe());

		for(auto Player : PlayersToToggleConstrainOn)
		{
			auto ConstrainToScreenComp = UTeenDragonConstrainToScreenComponent::Get(Player);
			if(ConstrainToScreenComp != nullptr)
				ConstrainToScreenComp.bConstrainToScreen = bActivate;
		}
	}

	UFUNCTION(BlueprintCallable, Category = "TeenDragon")
	void ToggleNonOffsetAcidAim(bool bActivate)
	{
		auto DragonComp = UPlayerAcidTeenDragonComponent::Get(Game::Mio);
		DragonComp.bNonOffsetAimCamera = bActivate;
	}

	TPerPlayer<bool> MovementInputBlocked;

	UFUNCTION()
	void BlockMovementInputUntilDeath(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		MovementInputBlocked[Player] = true;
	}

	UFUNCTION()
	void UnblockMovementInput(AHazePlayerCharacter Player)
	{
		if (MovementInputBlocked[Player])
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			MovementInputBlocked[Player] = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (MovementInputBlocked[Player] && Player.IsPlayerDead())
				UnblockMovementInput(Player);
		}
	}

	UFUNCTION(BlueprintPure)
	ATeenDragon GetTeenDragon(AHazePlayerCharacter Player)
	{
		return UPlayerTeenDragonComponent::Get(Player).GetTeenDragon();
	}
}