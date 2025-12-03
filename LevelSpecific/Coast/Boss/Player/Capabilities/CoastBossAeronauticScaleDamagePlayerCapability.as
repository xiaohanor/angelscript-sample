class UCoastBossAeronauticScaleDamagePlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UCoastBossAeronauticComponent AeroComp;
	ACoastBoss Boss;
	ECoastBossPhase LastPhase;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeroComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss == nullptr)
			return false;
		if (Boss.GetPhase() == LastPhase)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Boss == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
			{
				Boss = Refs.Single.Boss;
				LastPhase = Boss.GetPhase();
			}
		}
		if (Boss == nullptr)
			return;

		float Alpha = 1.0;
		if (CoastBossConstants::Player::DamageEndMultiplierDuration > KINDA_SMALL_NUMBER)
			Alpha = Math::Clamp(ActiveDuration / CoastBossConstants::Player::DamageEndMultiplierDuration, 0.0, 1.0);
		AeroComp.DamageMultiplier = Math::EaseIn(1.0, CoastBossConstants::Player::DamageEndMultiplier, Alpha, 3.0);
	}
};