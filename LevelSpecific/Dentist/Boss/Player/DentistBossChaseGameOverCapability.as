
class UDentistBossChaseGameOverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GameOver");
	default CapabilityTags.Add(n"DentistChaseGameOver");
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
		
		TListedActors<ADentistChaseBoss> DentistChasers;
		if (DentistChasers.Num() == 0)
			return false;

		if (!DentistChasers.Single.bActive)
			return false;

		if (ShouldTriggerGameOver())
		{
			return true;
		}

		// auto game over if both players are too far behind
		ADentistChaseBoss ChaseBoss = DentistChasers.Single;
		FVector ChaseSocketLocation = ChaseBoss.SkelMesh.GetSocketLocation(ChaseBoss.SocketForLocation);
		bool bAnyPlayerIsAhead = false;
		// ColorDebug::DrawTintedTransform(ChaseSocketLocation, ChaseBoss.ActorRotation, ColorDebug::Red, 5000, 1.0);
		for (AHazePlayerCharacter Playering : Game::Players)
		{
			FVector Diff = Playering.ActorLocation - ChaseSocketLocation;
			if (ChaseBoss.ActorForwardVector.DotProduct(Diff) > 0.0)
				bAnyPlayerIsAhead = true;
		}
		if (!bAnyPlayerIsAhead)
			return true;

		return false;
	}

	bool ShouldTriggerGameOver() const
	{

		if (!HealthSettings.bGameOverWhenBothPlayersDead)
			return false;

		if (!HealthComp.bIsDead)
			return false;
		// if (HealthComp.bIsRespawning) // ignore if we're in respawn
		// 	return false;
		if (Player.bIsControlledByCutscene)
			return false;

		if (!OtherPlayerHealthComp.bIsDead)
			return false;
		// if (OtherPlayerHealthComp.bIsRespawning) // ignore if we're in respawn
		// 	return false;
		if (Player.OtherPlayer.bIsControlledByCutscene)
			return false;

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
		PlayerHealth::TriggerGameOver();
	}
};