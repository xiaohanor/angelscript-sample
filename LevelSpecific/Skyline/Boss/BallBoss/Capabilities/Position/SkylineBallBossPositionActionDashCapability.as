struct FSkylineBallBossPositionActionDashData
{
	ESkylineBallBossLocationNode DashTarget = ESkylineBallBossLocationNode::Unassigned;
	float Duration = 1.0;

	ASkylineBallBossLocationNode NextLocation = nullptr;
}

class USkylineBallBossPositionActionDashCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);
	default CapabilityTags.Add(SkylineBallBossTags::PositionDash);

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	FSkylineBallBossPositionActionDashData ActivationParams;
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossPositionActionDashData& Params) const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return false;
		if (BossComp.PositionActionQueue.Start(this, Params))
		{
			ASkylineBallBossLocationNode NextLocation = SelectNextLocation(Params.DashTarget);
			if (NextLocation == nullptr)
			{
				BossComp.PositionActionQueue.Finish(this);
				return false;
			}
			Params.NextLocation = NextLocation;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return true;
		if (ActiveDuration > ActivationParams.Duration)
			return true;
		if (!BossComp.PositionActionQueue.IsActive(this))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossPositionActionDashData Params)
	{
		ActivationParams = Params;
		AccLocation.SnapTo(BallBoss.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.PositionActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BallBoss.bIsInTearOffPositioning)
			return;
		if (SkylineBallBossDevToggles::DrawLocationTarget.IsEnabled() && BallBoss.ActorLocation.Distance(ActivationParams.NextLocation.ActorLocation) > KINDA_SMALL_NUMBER)
			Debug::DrawDebugArrow(BallBoss.ActorLocation, ActivationParams.NextLocation.ActorLocation, 20.0, ColorDebug::Ruby, 5.0, 0.0, true);
		AccLocation.AccelerateTo(ActivationParams.NextLocation.ActorLocation, ActivationParams.Duration, DeltaTime);
		BallBoss.SetActorLocation(AccLocation.Value);
	}

	private ASkylineBallBossLocationNode SelectNextLocation(ESkylineBallBossLocationNode Target) const
	{
		TListedActors<ASkylineBallBossLocationNode> Locations;
		if (Locations.Num() == 0)
			return nullptr;
		for (auto Node : Locations)
		{
			if (Node.Placement == Target)
				return Node;
		}
		return nullptr;
	}
}