struct FSolarFlareSunDeactivationParams
{
	bool bWaveSpawned;
}

class USolarFlareSunFlareCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareSunFlareCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	ASolarFlareSun Sun;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sun = Cast<ASolarFlareSun>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PrintToScreen(f"{Sun.WaitTime=}");
		PrintToScreen(f"{Sun.WaitDuration=}");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Sun.Phase == ESolarFlareSunPhase::BlackHole)
			return false;

		if (!Sun.bSolarFlareSunActive && !Sun.bSolarFlareOneTimeActive)
			return false;
		
		if (Time::GameTimeSeconds < Sun.WaitTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSolarFlareSunDeactivationParams& DeactivationParams) const
	{
		if (Time::GameTimeSeconds < Sun.TelegraphTime && Sun.Phase != ESolarFlareSunPhase::BlackHole && Sun.Phase != ESolarFlareSunPhase::FinalPhase)
			return false;

		DeactivationParams.bWaveSpawned = true;

		//This means we were deactivated before the telegraph time was actually over
		//Can happen when a checkpoint is restarted, resulting in potential nullptrs - hence a return
		if (Sun.Phase == ESolarFlareSunPhase::Implode)
			DeactivationParams.bWaveSpawned = false;
		
		if (Sun.Phase == ESolarFlareSunPhase::FinalPhase)
			DeactivationParams.bWaveSpawned = false;

		if (Sun.Phase == ESolarFlareSunPhase::BlackHole)
			DeactivationParams.bWaveSpawned = false;
		
		if (Game::Mio.IsPlayerDead() && Game::Zoe.IsPlayerDead())
			DeactivationParams.bWaveSpawned = false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Sun.bIsFlaring = true;
		Sun.TelegraphTime = Time::GameTimeSeconds + Sun.TelegraphDuration;
		FOnSolarFlareSunTelegraph Params;
		Params.Location = Sun.ActorLocation;
		Params.TelegraphDuration = Sun.TelegraphDuration;
		USolarFlareSunEffectHandler::Trigger_OnSunTelegraph(Sun, Params);
		Sun.ActivateTelegraph();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSolarFlareSunDeactivationParams DeactivationParams)
	{
		Sun.bIsFlaring = false;
		Sun.WaitTime = Time::GameTimeSeconds + Sun.WaitDuration;

		if (Sun.bSolarFlareOneTimeActive)
			Sun.bSolarFlareOneTimeActive = false;
		
		if (!DeactivationParams.bWaveSpawned)
			return;
		
		Sun.SpawnFireDonut();
		Sun.WaveEmitter.ActivateWaveEmitter();

		FOnSolarFlareSunExplosion Params;
		Params.Location = Sun.ActorLocation;
		Params.WaitDuration = Sun.WaitDuration;
		Params.CurrentPhase = Sun.Phase;
		USolarFlareSunEffectHandler::Trigger_OnSunExplosion(Sun, Params);

		if (Sun.bOneTimeTelegraphUsed)
		{
			Sun.bOneTimeTelegraphUsed = false;
			Sun.TelegraphDuration = Sun.OneTimeOriginalTelegraphDuration;
		}

		Sun.OnSolarFlareActivateWave.Broadcast();
	}
}