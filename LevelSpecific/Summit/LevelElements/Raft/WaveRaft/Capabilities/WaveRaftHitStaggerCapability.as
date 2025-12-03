struct FWaveRaftHitStaggerActivationParams
{
	FSummitRaftHitStaggerData StaggerData;
}

class UWaveRaftHitStaggerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	default CapabilityTags.Add(n"WaveRaftHitStagger");

	UWaveRaftPlayerComponent RaftComp;
	USummitRaftPlayerStaggerComponent StaggerComp;
	AWaveRaft WaveRaft;

	UWaveRaftSettings RaftSettings;

	FSummitRaftHitStaggerData StaggerData;

	FVector ReflectedVelocityDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UWaveRaftPlayerComponent::Get(Player);
		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWaveRaftHitStaggerActivationParams& Params) const
	{
		if (WaveRaft == nullptr)
			return false;

		if (!StaggerComp.StaggerData.IsSet())
			return false;

		if (StaggerComp.StaggerData.Value.bSmallHit)
			return false;

		Params.StaggerData = StaggerComp.StaggerData.Value;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > RaftSettings.StaggerMinDuration)
		{
			return true;
		}

		if (StaggerComp.StaggerData.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWaveRaftHitStaggerActivationParams Params)
	{
		StaggerData = Params.StaggerData;
		StaggerComp.ClearOverrideFlag();
		Player.BlockCapabilities(SummitRaftTags::BlockedWhileInHitStagger, this);

		ReflectedVelocityDirection = StaggerData.ReflectedVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (WaveRaft == nullptr)
			return;

		if (StaggerComp.StaggerData.IsSet())
		{
			if (!StaggerComp.StaggerData.Value.bOverriddenPreviousData)
				StaggerComp.ResetStaggerData();
		}
		Player.UnblockCapabilities(SummitRaftTags::BlockedWhileInHitStagger, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WaveRaft == nullptr)
		{
			WaveRaft = RaftComp.WaveRaft;
			RaftSettings = UWaveRaftSettings::GetSettings(WaveRaft);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"PaddleRaftHitReaction", this);
	}
};