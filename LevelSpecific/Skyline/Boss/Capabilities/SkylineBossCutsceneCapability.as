class USkylineBossCutsceneCapability : UHazeMarkerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		Owner.BlockCapabilities(SkylineBossTags::SkylineBossAttack, this);

		auto ShockWaveComp = USkylineBossShockWaveComponent::Get(Owner);
		if (ShockWaveComp != nullptr)
		{
			ShockWaveComp.DestroyShockWaves();
		}

		auto RocketBarrageComp = USkylineBossRocketBarrageComponent::Get(Owner);
		if (RocketBarrageComp != nullptr)
		{
			RocketBarrageComp.UnspawnRockets();			
		}
	
		for (auto LegComponent : Boss.LegComponents)
			LegComponent.Leg.ShadowDecal.AddComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		Owner.UnblockCapabilities(SkylineBossTags::SkylineBossAttack, this);

		for (auto LegComponent : Boss.LegComponents)
			LegComponent.Leg.ShadowDecal.RemoveComponentVisualsBlocker(this);

/*
		auto ShockWaveComp = USkylineBossShockWaveComponent::Get(Owner);
		if (ShockWaveComp != nullptr)
		{
			ShockWaveComp.EnableActors();
		}

		auto RocketBarrageComp = USkylineBossRocketBarrageComponent::Get(Owner);
		if (RocketBarrageComp != nullptr)
		{
			RocketBarrageComp.EnableActors();
		}
*/
	}
};