struct FPaddleRaftCollisionActivationParams
{
	FVector HitImpactLocation;
	bool bWasBigHit;
}

class UPaddleRaftCollisionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	UHazeMovementComponent MoveComp;
	APaddleRaft PaddleRaft;

	UPaddleRaftSettings RaftSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PaddleRaft = Cast<APaddleRaft>(Owner);
		MoveComp = UHazeMovementComponent::Get(PaddleRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPaddleRaftCollisionActivationParams& Params) const
	{
		if (!MoveComp.HasImpactedWall())
			return false;

		if (DeactiveDuration < 0.5)
			return false;

		Params.HitImpactLocation = MoveComp.AllWallImpacts[0].ImpactPoint;

		if (PaddleRaft.QueuedStaggerData.IsSet())
		{
			Params.bWasBigHit = true;
			Params.HitImpactLocation = PaddleRaft.QueuedStaggerData.Value.ImpactPoint;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPaddleRaftCollisionActivationParams Params)
	{
		auto Raft = Cast<APaddleRaft>(Owner);
		FPaddleRaftCollisionEventParams EventParams;
		EventParams.ImpactLocation = Params.HitImpactLocation;
		UPaddleRaftEventHandler::Trigger_OnRaftCollisionRaw(Raft, EventParams);

		float Scale = 0.1;

		if (Params.bWasBigHit)
		{
			EventParams.ImpactLocation = Params.HitImpactLocation;
			UPaddleRaftEventHandler::Trigger_OnRaftCollision(Raft, EventParams);
			Scale = 1.0;
		}
		
		for (auto Player : Game::Players)
		{
			auto RaftComp = UPaddleRaftPlayerComponent::Get(Player);
			Player.PlayForceFeedback(RaftComp.CollisionFF, false, true, this, Scale);
			Player.PlayCameraShake(RaftComp.CollisionCameraShake, this, Scale);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PaddleRaft.QueuedStaggerData.Reset();
	}
}