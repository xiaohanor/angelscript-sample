
class UPlayerGameOverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GameOver");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"PlayerHealth";

	UPlayerHealthSettings HealthSettings;

	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;

	UPlayerHealthComponent OtherPlayerHealthComp;
	UPlayerRespawnComponent OtherPlayerRespawnComp;

	bool bEffectStarted = false;
	bool bFinished = false;
	bool bStartedFadeOut = false;

	float EffectTimeRemaining = 0.0;
	float BlackAndWhiteStrength = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);

		OtherPlayerHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		OtherPlayerRespawnComp = UPlayerRespawnComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DevTogglesPlayerHealth::PreventGameOver.IsEnabled())
			return false;

		if (Network::IsGameNetworked())
		{
			// GameOver is controlled by the host player
			if (!Network::HasWorldControl())
				return false;
			if (!Player.HasControl())
				return false;
		}
		else
		{
			// In local we just have Mio control gameover
			if (Player.IsZoe())
				return false;
		}

		// If we're already game over always activate this
		if (HealthComp.bIsGameOver)
			return true;

		// We might want to go automatically game over if both players are dead simultaneously
		if (ShouldTriggerGameOver())
		{
			return true;
		}

		return false;
	}

	bool ShouldTriggerGameOver() const
	{
		if (!HealthSettings.bGameOverWhenBothPlayersDead)
			return false;

		if (!HealthComp.bIsDead)
			return false;
		if (HealthComp.bIsRespawning)
			return false;
		if (Player.bIsControlledByCutscene)
			return false;

		if (!OtherPlayerHealthComp.bIsDead)
			return false;
		if (OtherPlayerHealthComp.bIsRespawning)
			return false;
		if (Player.OtherPlayer.bIsControlledByCutscene)
			return false;

		return true;
	}

	bool CanRespawn(AHazePlayerCharacter CheckPlayer) const
	{
		if (CheckPlayer.IsCapabilityTagBlocked(n"Respawn"))
			return false;

		FRespawnLocation Location;
		if (RespawnComp.PrepareRespawnLocation(Location))
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HealthComp.bIsGameOver)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.bIsGameOver = true;
		OtherPlayerHealthComp.bIsGameOver = true;

		bEffectStarted = false;
		bFinished = false;
		bStartedFadeOut = false;

		EffectTimeRemaining = 0.0;
		BlackAndWhiteStrength = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bEffectStarted)
			StartEffect();
		if (!bFinished)
			FinishGameOver();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float GameDeltaTime)
	{
		// Use the camera delta time since we want the game over effect to last the same duration even if 
		// the game is currently in slow motion
		float CameraDeltaTime = Time::GetCameraDeltaSeconds();

		if (!bEffectStarted)
		{
			bool bCanStartEffect = true;

			// We can't start the game over effect until both players have finished dying
			if (HealthComp.bIsDead && !HealthComp.bHasFinishedDying)
				bCanStartEffect = false;
			if (OtherPlayerHealthComp.bIsDead && !OtherPlayerHealthComp.bHasFinishedDying)
				bCanStartEffect = false;

			if (bCanStartEffect)
			{
				StartEffect();
			}
		}
		else if (!bFinished)
		{
			EffectTimeRemaining -= CameraDeltaTime;
			if (EffectTimeRemaining <= 0.0)
			{
				FinishGameOver();
				return;
			}

			// Gradually turn the screen black and white
			BlackAndWhiteStrength = Math::FInterpConstantTo(BlackAndWhiteStrength, 1.0, CameraDeltaTime, 1.0);
			for (auto EffectPlayer : Game::Players)
			{
				auto PostProcess = UPostProcessingComponent::Get(EffectPlayer);
				PostProcess.BlackAndWhiteStrength.Apply(BlackAndWhiteStrength, this);
			}

			// Fade out the screen to indicate game over
			if (EffectTimeRemaining <= 1.0 && !bStartedFadeOut)
			{
				for (auto EffectPlayer : Game::Players)
				{
					EffectPlayer.FadeOut(
						this,
						FadeDuration = -1.0,
						FadeOutTime = EffectTimeRemaining,
					);
				}

				bStartedFadeOut = true;
			}
		}
	}

	void StartEffect()
	{
		bEffectStarted = true;
		EffectTimeRemaining = 2.5;
	}

	void FinishGameOver()
	{
		bFinished = true;

		if (HealthComp.CustomGameOverOverride.IsBound())
		{
			for (auto EffectPlayer : Game::Players)
			{
				auto PostProcess = UPostProcessingComponent::Get(EffectPlayer);
				PostProcess.BlackAndWhiteStrength.Clear(this);
				
				EffectPlayer.ClearFade(this);
				PlayerHealth::ForceRespawnPlayerInstantly(EffectPlayer);
			}

			HealthComp.bIsGameOver = false;
			OtherPlayerHealthComp.bIsGameOver = false;
			HealthComp.CustomGameOverOverride.Broadcast();
		}
		else
		{
			Save::RestartFromLatestSave();
		}
	}
};