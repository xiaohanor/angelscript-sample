class UPrisonStealthDetectionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthDetection);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthEnemy Enemy;
	UPrisonStealthStunnedComponent StunnedComp;

	TPerPlayer<bool> HasKilledPlayer;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<APrisonStealthEnemy>(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Enemy);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StunnedComp.IsStunned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StunnedComp.IsStunned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			
			ResetDetectionOfPlayer(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			ControlTickDetection(Player);
		}
	}

	void ControlTickDetection(AHazePlayerCharacter Player)
	{
		check(Player.HasControl());

		if(Enemy.HasDetectedPlayer(Player))
		{
			// Wait for respawn, don't check IsPlayerDead since that hasn't synced yet
			if(!HasKilledPlayer[Player])
			{
				// The player has respawned, set it as not detected
				ResetDetectionOfPlayer(Player);
			}
		}
		else
		{
			if(Enemy.GetDetectionAlpha(Player) > 1.0 - KINDA_SMALL_NUMBER)
			{
				DetectPlayer(Player);
			}
		}
	}

	void DetectPlayer(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			Enemy.SetHasDetectedPlayer(Player, true);

			HasKilledPlayer[Player] = true;

			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnKilledPlayerRespawn");
		}

		PrisonStealth::GetStealthManager().OnPlayerDetected(Enemy, Player);
	}

	void ResetDetectionOfPlayer(AHazePlayerCharacter Player)
	{
		check(Player.HasControl());
		Enemy.SetHasDetectedPlayer(Player, false);
	}

	UFUNCTION()
	private void OnKilledPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		HasKilledPlayer[RespawnedPlayer] = false;

		auto RespawnComp = UPlayerRespawnComponent::Get(RespawnedPlayer);
		RespawnComp.OnPlayerRespawned.Unbind(this, n"OnKilledPlayerRespawn");
	}
};