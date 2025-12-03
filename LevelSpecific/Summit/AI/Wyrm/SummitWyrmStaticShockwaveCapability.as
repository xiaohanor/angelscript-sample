class USummitWyrmStaticShockwaveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitWyrmStaticShockwaveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAISummitWyrm Wyrm;
	UStormSiegeDetectPlayerComponent DetectComp;
	//TArray<AStormSiegeRockSpikes> RockSpikes;

	float NextAttackTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//GetAllActorsOfClass(RockSpikes);
		DetectComp = UStormSiegeDetectPlayerComponent::Get(Owner);
		Wyrm = Cast<AAISummitWyrm>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DetectComp.HasAvailablePlayers())
			return false;
		
		if (Time::GameTimeSeconds < NextAttackTime)
			return false;
		
		if (!Wyrm.bSiegeActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Find and release spikes - alternate intervals of 2 (every even, then every odd index)
		NextAttackTime = Time::GameTimeSeconds + Wyrm.ShockwaveWaitTime;
		
		TListedActors<AStormSiegeRockSpikes> RockSpikes;
		for (AStormSiegeRockSpikes Spike : RockSpikes)
		{
			Spike.ActivateFallingSpikes();
		}

		FWyrmShockwaveParams Params;
		Params.Location = Owner.ActorLocation;
		USummitWyrmEffectHandler::Trigger_ActivateShockWave(Owner, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}