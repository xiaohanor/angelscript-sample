class UMetalFortRegrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MetalFortRegrowCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormSiegeMetalFortification Fort;
	float RegrowthTime;

	bool bActivatedRegrowthPreEffect;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fort = Cast<AStormSiegeMetalFortification>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Fort.OwningGem == nullptr)
			return false;

		if (!Fort.bCanRegrow)
			return false;

		if (Fort.bPermaDestroyed)
			return false;

		if (!Fort.bMelted)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Fort.OwningGem == nullptr)
			return true;
		
		if (Fort.bPermaDestroyed)
			return true;

		if (Time::GameTimeSeconds > RegrowthTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RegrowthTime = Time::GameTimeSeconds + Fort.Settings.RegrowthDuration;
		bActivatedRegrowthPreEffect = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Fort.RegrowFort();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > RegrowthTime - 1.0 && !bActivatedRegrowthPreEffect)
		{
			bActivatedRegrowthPreEffect = true;
			FStormSiegeMetalPreGrowthParams Params;
			Params.AttachComp = Fort.MeshRoot;
			UStormSiegeMetalFortificationEffectHandler::Trigger_OnMetalPreGrowthEffect(Fort, Params);
		}
	}
}