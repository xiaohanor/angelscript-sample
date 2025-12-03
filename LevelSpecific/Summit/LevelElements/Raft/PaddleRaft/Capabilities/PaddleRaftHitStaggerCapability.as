struct FPaddleRaftHitStaggerActivationParams
{
	FSummitRaftHitStaggerData StaggerData;
}

class UPaddleRaftHitStaggerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	UPaddleRaftPlayerComponent RaftComp;
	USummitRaftPlayerStaggerComponent StaggerComp;
	APaddleRaft PaddleRaft;

	UPaddleRaftSettings RaftSettings;

	FSummitRaftHitStaggerData StaggerData;

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("StaggerData;HitSide", StaggerData.HitSide);
		TemporalLog.Value("StaggerData;bOverriddenPreviousData", StaggerData.bOverriddenPreviousData);
		TemporalLog.Value("StaggerData;bSmallHit", StaggerData.bSmallHit);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UPaddleRaftPlayerComponent::Get(Player);
		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPaddleRaftHitStaggerActivationParams& Params) const
	{
		if (PaddleRaft == nullptr)
			return false;

		if (StaggerComp.StaggerData.IsSet())
		{
			Params.StaggerData = StaggerComp.StaggerData.Value;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > RaftSettings.StaggerMinDuration)
		{
			if (IsActioning(ActionNames::PrimaryLevelAbility) || IsActioning(ActionNames::SecondaryLevelAbility))
				return true;
		}

		if (ActiveDuration > RaftSettings.StaggerMaxDuration)
			return true;

		if (StaggerComp.StaggerData.IsSet() && StaggerComp.StaggerData.Value.bOverriddenPreviousData)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPaddleRaftHitStaggerActivationParams Params)
	{
		StaggerData = Params.StaggerData;
		StaggerComp.ClearOverrideFlag();

		if (!StaggerData.bSmallHit)
		{
			//only take damage once
			if ((Network::IsGameNetworked() && Network::HasWorldControl() && Player.HasControl()) || (!Network::IsGameNetworked() && Player.IsMio()))
			{
				PaddleRaft.CrumbTakeDamage();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (StaggerComp.StaggerData.IsSet())
		{
			if (!StaggerComp.StaggerData.Value.bOverriddenPreviousData)
				StaggerComp.ResetStaggerData();
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (PaddleRaft == nullptr)
		{
			PaddleRaft = RaftComp.PaddleRaft;
			RaftSettings = UPaddleRaftSettings::GetSettings(PaddleRaft);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"PaddleRaftHitReaction", this);
	}
};