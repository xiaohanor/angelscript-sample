struct FCoastBossAeronauticInvulnerableActivateParams
{
	bool bRespawned = false;
	bool bIsInvincibleFraming = false;
	bool bDevToggling = false;
	bool bBossDead = false;
}

class UCoastBossAeronauticInvulnerableCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossAeronauticInvulnerableActivateParams ActivateParams;
	UCoastBossAeronauticComponent AeroComp;
	ACoastBossActorReferences References;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
		CoastBossDevToggles::PlayersInvulnerable.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticInvulnerableActivateParams & Params) const
	{
		if (!HasControl())
			return false;
		
		if (CoastBossDevToggles::PlayersInvulnerable.IsEnabled())
		{
			Params.bDevToggling = true;
			return true;
		}

		if (References != nullptr && References.Boss.bDead)
		{
			Params.bBossDead = true;
			return true;
		}

		if (AeroComp.InvincibleFramesCooldown > 0.0)
		{
			Params.bIsInvincibleFraming = true;
			return true;
		}

		if (Player.IsPlayerDead())
		{
			Params.bRespawned = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActivateParams.bDevToggling && CoastBossDevToggles::PlayersInvulnerable.IsEnabled())
			return false;
		if (ActivateParams.bRespawned && ActiveDuration < 3.5)
			return false;
		if (ActivateParams.bIsInvincibleFraming && AeroComp.InvincibleFramesCooldown > 0.0)
			return false;
		if (ActivateParams.bBossDead && References != nullptr && References.Boss.bDead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossAeronauticInvulnerableActivateParams Params)
	{
		ActivateParams = Params;
		AeroComp.bPlayerInvulnerable = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AeroComp.bPlayerInvulnerable = false;
	}
};