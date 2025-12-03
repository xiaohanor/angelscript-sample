class UBrothersBenchBenchCameraPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UBrothersBenchPlayerComponent PlayerComp;
	ABrothersBench BrothersBench;

	float PostProcessWeight = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UBrothersBenchPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.BrothersBench == nullptr)
			return false;

		if(!PlayerComp.BrothersBench.PlayerData[Player].IsSitting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.BrothersBench == nullptr)
			return true;

		// Can't deactivate while blending
		if(PlayerComp.BrothersBench.BlendState == EBrothersBenchBlendState::ProjectionBlending)
			return false;

		if(!PlayerComp.BrothersBench.PlayerData[Player].IsSitting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BrothersBench = PlayerComp.BrothersBench;

		Player.ActivateCameraCustomBlend(
			BrothersBench.BenchCamera,
			BrothersBenchBenchBlend,
			BrothersBench.BlendTime,
			this,
			EHazeCameraPriority::VeryHigh
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(BrothersBench.PlayerData[Player].IsSitting())
		{
			BrothersBench.StopSitting(Player);
		}
		
		Player.DeactivateCameraByInstigator(this, 1);

		BrothersBench = nullptr;
	}
};