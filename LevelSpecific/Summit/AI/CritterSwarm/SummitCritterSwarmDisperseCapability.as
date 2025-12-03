class USummitCritterSwarmDisperseCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UBasicAIHealthComponent HealthComp;
	USummitCritterSwarmSettings Settings;
	USummitCritterSwarmComponent SwarmComp;
	float DisperseCritterTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		for (USummitSwarmingCritterComponent Mesh : SwarmComp.UnspawnedCritters)
		{
			Mesh.RemoveComponentVisualsBlocker(this);
			SwarmComp.Critters.Add(Mesh);
		}
		SwarmComp.UnspawnedCritters.Empty(SwarmComp.Critters.Num());
		if (Owner.IsActorDisabledBy(this))
			Owner.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Use this capability when we die if there are any critters left 
		// and we weren't killed by acid recently 
		if (!HealthComp.IsDead())
			return false;
		if (SwarmComp.Critters.Num() == 0)
			return false;
		if ((HealthComp.LastDamageType == EDamageType::Acid) && (Time::GetGameTimeSince(HealthComp.LastDamageTime) < Settings.AcidDamageCooldown + 0.5))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SwarmComp.Critters.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Critters will disperse and be unspawned one at a time.
		USummitCritterSwarmSettings::SetFlockingOwnerAccelerationFactor(Owner, Settings.FlockingOwnerAccelerationFactor * 0.1, this);
		USummitCritterSwarmSettings::SetFlockingRepulsionFactor(Owner, Settings.FlockingRepulsionFactor * 2.0, this);
		DisperseCritterTime = Time::GameTimeSeconds;
		HealthComp.TriggerStartDying();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
		if (HealthComp.IsDead())
		{
			HealthComp.OnDie.Broadcast(Owner);
			Owner.AddActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Disperse by increasing repulsion range
		USummitCritterSwarmSettings::SetFlockingRepulseRange(Owner, Settings.FlockingRepulseRange + 2000 * DeltaTime, this);

		if (Time::GameTimeSeconds < DisperseCritterTime)
			return;

		DisperseCritterTime += Settings.SpawnerDeathDisperseInterval;

		// Unspawn random dispersed critter
		int iCritter = Math::RandRange(0, SwarmComp.Critters.Num() - 1);
		SwarmComp.Critters[iCritter].AddComponentVisualsBlocker(this);
		USummitCritterSwarmEventHandler::Trigger_OnDisperseCritterDeath(Owner, FCritterSwarmDisperseCritterEventParams(SwarmComp.Critters[iCritter]));

		SwarmComp.UnspawnedCritters.Add(SwarmComp.Critters[iCritter]);
		SwarmComp.Critters.RemoveAt(iCritter);
	}
}
