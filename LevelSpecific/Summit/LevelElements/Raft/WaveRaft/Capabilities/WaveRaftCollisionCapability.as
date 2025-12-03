struct FWaveRaftCollisionActivationParams
{
	FVector HitImpactLocation;
	bool bWasBigHit;
}

class UWaveRaftCollisionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	UHazeMovementComponent MoveComp;
	AWaveRaft WaveRaft;

	UPaddleRaftSettings RaftSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);
		MoveComp = UHazeMovementComponent::Get(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWaveRaftCollisionActivationParams& Params) const
	{
		if (!MoveComp.HasImpactedWall())
			return false;

		if (DeactiveDuration < 0.5)
			return false;

		Params.HitImpactLocation = MoveComp.AllWallImpacts[0].ImpactPoint;

		if (WaveRaft.StaggerData.IsSet())
		{
			Params.bWasBigHit = true;
			Params.HitImpactLocation = WaveRaft.StaggerData.Value.ImpactPoint;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWaveRaftCollisionActivationParams Params)
	{
		auto Raft = Cast<AWaveRaft>(Owner);
		FWaveRaftCollisionEventParams EventParams;
		EventParams.ImpactLocation = Params.HitImpactLocation;
		UWaveRaftEventHandler::Trigger_OnRaftCollisionRaw(Raft, EventParams);

		float Scale = 0.1;

		if (Params.bWasBigHit)
		{
			EventParams.ImpactLocation = Params.HitImpactLocation;
			UWaveRaftEventHandler::Trigger_OnRaftCollision(Raft, EventParams);
			Scale = 1.0;
		}
		
		for (auto Player : Game::Players)
		{
			auto RaftComp = UWaveRaftPlayerComponent::Get(Player);
			Player.PlayForceFeedback(RaftComp.CollisionFF, false, true, this, Scale);
			Player.PlayCameraShake(RaftComp.CollisionCameraShake, this, Scale);
		}
	}
}