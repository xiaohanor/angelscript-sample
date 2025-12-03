struct FCentipedeSwingBiteActivationParams
{
	UCentipedeSwingPointComponent SwingPoint = nullptr;
}

class UCentipedeSwingBiteCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeSwingBite);

	// Tick after CentipedeSwingBiteActivationCapability
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroupOrder = 100;

	default TickGroup = EHazeTickGroup::ActionMovement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerCentipedeSwingComponent SwingComponent;
	UCentipedeBiteComponent BiteComponent;

	UPlayerMovementComponent MovementComponent;
	USimpleMovementData MoveData;

	float LastActiveDuration = 0.0;
	const float StartMeshLerpDuration = 0.05;

	bool bBiteEffectEventFired;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		SwingComponent = UPlayerCentipedeSwingComponent::Get(Owner);
		BiteComponent = UCentipedeBiteComponent::Get(Owner);

		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeSwingBiteActivationParams& ActivationParams) const
	{
		UCentipedeSwingPointComponent PendingSwingPoint;
		if (!SwingComponent.ConsumePendingSwingPoint(PendingSwingPoint))
			return false;

		ActivationParams.SwingPoint = PendingSwingPoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto ActiveSwingPoint = SwingComponent.GetActiveSwingPoint();
		if (ActiveSwingPoint == nullptr)
			return true;

		// if (!ActiveSwingPoint.NetworkLockComponent.IsAcquired(Player))
		// 	return true;

		// Check for trigger release instead of network lock
		if (SwingComponent.GetActiveSwingPoint().bCanPlayerLetGo)
		{
			if (!BiteComponent.GetBiteActioning(this) && ActiveDuration > SwingComponent.Settings.MinimumBiteDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeSwingBiteActivationParams ActivationParams)
	{
		SwingComponent.ActivateSwingPoint(ActivationParams.SwingPoint);
		SwingComponent.bSwingBiting = true;

		bBiteEffectEventFired = false;

		if (HasControl())
			NetSetImmediateSwingBiting(true);

		const FVector PlayerToSwing = (ActivationParams.SwingPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();

		Player.SmoothTeleportActor(ActivationParams.SwingPoint.WorldLocation, Player.ActorRotation, this, StartMeshLerpDuration);
		CentipedeComponent.Centipede.bJustTeleported = true;

		CentipedeComponent.ApplyDisableBodyCollisionWithPlayer(this);

		// Stahp replicating body, the swing speed looks assy otherwise.
		// Also since body is stretched we don't need to worry about both sides being diferentes.
		CentipedeComponent.Centipede.ApplyBodyReplicationBlock(this);

		Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
		Player.BlockCapabilities(CentipedeTags::CentipedeSwing, this);

		SwingComponent.OnSwingStart.Broadcast(Player, ECentipedePlayerSwingRole::Biter, ActivationParams.SwingPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Teleporting during begin- or end play causes too much traffic, apparently 🙄
		if (Player.HasActorBegunPlay() && SwingComponent.GetActiveSwingPoint() != nullptr)
		{
			// Teleport actual player location to where mesh used to be and snap back mesh
			FTransform OffsetTransform = MakeOffsetTransform();
			Player.TeleportActor(OffsetTransform.Location, OffsetTransform.Rotator(), this, false);
			CentipedeComponent.Centipede.bJustTeleported = true;
		}

		Player.MeshOffsetComponent.ResetOffsetWithLerp(SwingComponent, 0.0);

		if (HasControl())
			NetSetImmediateSwingBiting(false);

		CentipedeComponent.ClearDisableBodyCollisionWithPlayer(this);
		CentipedeComponent.Centipede.ClearBodyReplicationBlock(this);

		Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
		Player.UnblockCapabilities(CentipedeTags::CentipedeSwing, this);

		FSanctuaryCentipedeSwingpointEventData Data;
		Data.Player = Player;
		Data.DistanceToOtherPlayer = Player.ActorLocation.Distance(Player.OtherPlayer.ActorLocation);
		Data.SwingPointComponent = SwingComponent.GetBitingSwingPoint();
		UCentipedeEventHandler::Trigger_OnSwingPointReleased(Player, Data);
		UCentipedeEventHandler::Trigger_OnSwingPointReleased(CentipedeComponent.Centipede, Data);

		SwingComponent.bSwingBiting = false;
		SwingComponent.DeactivateSwingPoint();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleActivationEffectEvent();

		const float EventDelayTimer = 8.0;
		if (ActiveDuration > EventDelayTimer && LastActiveDuration <= EventDelayTimer)
		{
			FSanctuaryCentipedeBiteEventData Data;
			Data.Player = Player;
			UCentipedeEventHandler::Trigger_OnSwingPointIdling(CentipedeComponent.Centipede, Data);
			UCentipedeEventHandler::Trigger_OnSwingPointIdling(Player, Data);
		}

		LastActiveDuration = ActiveDuration;
		// This will be true if remote got interrupted by forced jump
		if (SwingComponent.GetActiveSwingPoint() == nullptr)
			return;

		// Swing points can move, so let's move with them
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector TargetLocation = SwingComponent.GetActiveSwingPoint().WorldLocation;
				FVector MoveDelta = TargetLocation - Player.ActorLocation;
				MoveData.AddDelta(MoveDelta);
			}
			else
			{
				FVector TargetLocation = SwingComponent.GetActiveSwingPoint().WorldLocation;
				FVector MoveDelta = TargetLocation - Player.ActorLocation;
				FVector SyncedLocation = Player.ActorLocation + MoveDelta;

				MoveData.ApplyManualSyncedLocationAndRotation(SyncedLocation, MoveDelta, Player.ActorRotation);
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Offset player mesh
		FTransform AttachTransform = MakeOffsetTransform();
		float LerpDuration = GetMeshOffsetLerpDuration();
		if (LerpDuration == 0)
		{
			Player.MeshOffsetComponent.SnapToTransform(SwingComponent, AttachTransform);
		}
		else
		{
			Player.MeshOffsetComponent.LerpToTransform(SwingComponent, AttachTransform, LerpDuration);
		}
	}

	// Offset mesh backwards (towards player) to nail down the mandibles
	FTransform MakeOffsetTransform()
	{
		FVector UpVector = SwingComponent.GetActiveSwingPoint().GetSwingPlaneVector();
		FVector Forward;

		// Offset player rotations if both are biting same point
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent.GetBitingSwingPoint() == SwingComponent.GetActiveSwingPoint())
		{
			float Multiplier = Player.IsMio() ? 1 : -1;
			Forward = Forward.RotateAngleAxis(30 * Multiplier, UpVector);
		}
		else
		{
			Forward = (Player.ActorLocation - Player.OtherPlayer.ActorLocation).GetSafeNormal();
		}

		FQuat Rotation = FQuat::MakeFromXZ(Forward, UpVector);
		FVector Location = Player.ActorLocation - Forward * Centipede::PlayerMeshMandibleOffset;

		return FTransform(Rotation, Location);
	}

	float GetMeshOffsetLerpDuration() const
	{
		// Instant lerp if swing point is moving
		if (!Player.ActorVelocity.IsZero())
			return 0.0;

 		// Snap faster as we start
		float Alpha = Math::Saturate(ActiveDuration / 0.5);
		return Math::Lerp(StartMeshLerpDuration, 0.2, Alpha);
	}

	void HandleActivationEffectEvent()
	{
		if (bBiteEffectEventFired)
			return;

		// Mesh lerp time + mandible closing time
		if (ActiveDuration < StartMeshLerpDuration)
			return;

		FSanctuaryCentipedeSwingpointEventData Data;
		Data.Player = Player;
		Data.DistanceToOtherPlayer = Player.ActorLocation.Distance(Player.OtherPlayer.ActorLocation);
		Data.SwingPointComponent = SwingComponent.GetBitingSwingPoint();
		UCentipedeEventHandler::Trigger_OnSwingPointAttached(Player, Data);
		UCentipedeEventHandler::Trigger_OnSwingPointAttached(CentipedeComponent.Centipede, Data);

		bBiteEffectEventFired = true;
	}

	UFUNCTION(NetFunction)
	void NetSetImmediateSwingBiting(bool bValue)
	{
		if (SwingComponent != nullptr)
		{
			SwingComponent.bImmediateNetworkSwingBiting = bValue;
			// SwingComponent.bWasBitingSwingPoint = !bValue;
		}
	}
}