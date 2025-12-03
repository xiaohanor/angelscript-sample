
class USkylineTorGeckoSafetyProgressionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USkylineTorPhaseComponent PhaseComp;
	float LastPlayerRespawnTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			if (RespawnComp != nullptr)
				RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
		}			
	}

	UFUNCTION()
	private void OnPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		LastPlayerRespawnTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Gecko)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Gecko)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		KillAllGeckos();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && ShouldProgress())
			CrumbProgressToHovering();		
	}

	bool ShouldProgress()
	{
		if (ActiveDuration < 30.0)
			return false;

		if (GetTimeSinceLastPlayerRespawn() < 10.0)
			return false;

		USkylineGeckoTeam GeckoTeam = Cast<USkylineGeckoTeam>(HazeTeam::GetTeam(SkylineGeckoTags::SkylineGeckoTeam));	
		if (GeckoTeam == nullptr)
			return false; // There will be a gecko team until level is streamed out

		// If we've not managed to start any attacks for a while we assume there's a bugged out gecko
		if (Time::GetGameTimeSince(GeckoTeam.LastAttackTime) > 10.0)
			return true;

		return false;		
	}

	float GetTimeSinceLastPlayerRespawn()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDeadOrRespawning())
				return 0.0;
		}
		return Time::GetGameTimeSince(LastPlayerRespawnTime);
	}

	UFUNCTION(CrumbFunction)
	void CrumbProgressToHovering()
	{
		KillAllGeckos();	
		PhaseComp.SetPhase(ESkylineTorPhase::Hovering, ESkylineTorSubPhase::None);
	}

	void KillAllGeckos()
	{
		UHazeActorSpawnerComponent GeckoSpawner = nullptr; 
		USkylineGeckoTeam GeckoTeam = Cast<USkylineGeckoTeam>(HazeTeam::GetTeam(SkylineGeckoTags::SkylineGeckoTeam));	
		if (GeckoTeam != nullptr)
		{
			for (AHazeActor Gecko : GeckoTeam.GetMembers())
			{
				if (Gecko == nullptr)
					continue;
				
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Gecko);
				if (HealthComp != nullptr)
					HealthComp.TakeDamage(1.0, EDamageType::Explosion, Game::Mio);
				UDisableComponent DisableComp = UDisableComponent::Get(Gecko);
				if (DisableComp != nullptr)
					DisableComp.SetEnableAutoDisable(true);
				if (GeckoSpawner == nullptr)
				{
					UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Gecko);
					if (RespawnComp != nullptr)
					{
						UHazeActorSpawnPattern SpawnPattern = Cast<UHazeActorSpawnPattern>(RespawnComp.SpawnParameters.Spawner);
						if ((SpawnPattern != nullptr) && (SpawnPattern.Owner != nullptr))
							GeckoSpawner = UHazeActorSpawnerComponent::Get(SpawnPattern.Owner);
					}
				}
			}

			// Make sure we don't spawn any further geckos after this
			GeckoSpawner.DeactivateSpawner(this, EInstigatePriority::High);
		}
	}
}
