class USummitCritterSwarmAcidResponseCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UBasicAIHealthComponent HealthComp;
	USummitCritterSwarmSettings Settings;
	float LastAcidHitTime = -BIG_NUMBER;
	float AcidDamageCooldown;
	UHazeCapsuleCollisionComponent CapsuleComp;
	USummitCritterSwarmComponent SwarmComp;
	float DefaultCapsuleRadius;
	float CurrentDamageFraction = 0.0;
	float MeltCritterTime;
	float MeltCritterInterval;
	int NumCrittersToMelt;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		UAcidResponseComponent AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		CapsuleComp = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		DefaultCapsuleRadius = CapsuleComp.CapsuleRadius;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		LastAcidHitTime = -BIG_NUMBER;
		CapsuleComp.CapsuleRadius = DefaultCapsuleRadius;
		CapsuleComp.CapsuleHalfHeight = CapsuleComp.CapsuleRadius;
		CurrentDamageFraction = 0.0;
		for (USummitSwarmingCritterComponent Mesh : SwarmComp.UnspawnedCritters)
		{
			Mesh.RemoveComponentVisualsBlocker(this);
			SwarmComp.Critters.Add(Mesh);
		}
		SwarmComp.UnspawnedCritters.Empty(SwarmComp.Critters.Num());
		if (Owner.IsActorDisabledBy(this))
			Owner.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (Time::GameTimeSeconds < AcidDamageCooldown)
			return;

		LastAcidHitTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.IsDead())
			return false;
		if (Time::GetGameTimeSince(LastAcidHitTime) > 0.5)
			return false;
		if (SwarmComp.Critters.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (NumCrittersToMelt == 0)
			return true;
		if (SwarmComp.Critters.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcidDamageCooldown = Time::GameTimeSeconds + Settings.AcidDamageCooldown;
		HealthComp.TakeDamage(Settings.AcidDamage, EDamageType::Acid, Game::Mio);
		CurrentDamageFraction = Math::Min(1.0, CurrentDamageFraction + Settings.AcidDamage);
		CapsuleComp.CapsuleRadius = DefaultCapsuleRadius * Math::Lerp(1.0, Settings.DamagedMinSizeFraction, CurrentDamageFraction);
		CapsuleComp.CapsuleHalfHeight = CapsuleComp.CapsuleRadius;
		NumCrittersToMelt = Math::Clamp(Math::RoundToInt(Settings.NumCritters * Settings.AcidDamage), 1, SwarmComp.Critters.Num());
		MeltCritterTime = Time::GameTimeSeconds;
		MeltCritterInterval = Settings.AcidDamageCooldown / float(NumCrittersToMelt);
		HealthComp.TriggerStartDying();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HealthComp.IsDead())
		{
			HealthComp.OnDie.Broadcast(Owner);
			Owner.AddActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < MeltCritterTime)
			return;

		NumCrittersToMelt--;
		MeltCritterTime += MeltCritterInterval;

		// Melt random critter for now
		int iMelt = Math::RandRange(0, SwarmComp.Critters.Num() - 1);
		SwarmComp.Critters[iMelt].AddComponentVisualsBlocker(this);
		USummitCritterSwarmEventHandler::Trigger_OnMeltCritter(Owner, FCritterSwarmMeltCritterEventParams(SwarmComp.Critters[iMelt]));

		SwarmComp.UnspawnedCritters.Add(SwarmComp.Critters[iMelt]);
		SwarmComp.Critters.RemoveAt(iMelt);
	}
}
