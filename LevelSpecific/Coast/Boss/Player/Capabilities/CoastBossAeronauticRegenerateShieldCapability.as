struct FCoastBossAeronauticRegenerateShieldDeactivatedParams
{
	bool bRegenerateShield = false;
}

class UCoastBossAeronauticRegenerateShieldCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroupOrder = 99; // Before shield capability

	UCoastBossAeronauticComponent AeroComp;

	ACoastBossActorReferences References;
	UPlayerHealthComponent PlayerHealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
		CoastBossDevToggles::PlayersInvulnerable.MakeVisible();
		PlayerHealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AeroComp.bHasShield)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCoastBossAeronauticRegenerateShieldDeactivatedParams& Params) const
	{
		if(AeroComp.bHasShield)
			return true;

		if(ActiveDuration > CoastBossConstants::Player::ShieldRegenerationDuration)
		{
			Params.bRegenerateShield = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCoastBossAeronauticRegenerateShieldDeactivatedParams Params)
	{
		if(Params.bRegenerateShield)
		{
			AeroComp.bHasShield = true;
			PlayerHealthComp.HealPlayer(1.0);
			AeroComp.InvincibleFramesCooldown = CoastBossConstants::Player::InvincibleFramesShieldRegenerationDuration;
		}
	}
}