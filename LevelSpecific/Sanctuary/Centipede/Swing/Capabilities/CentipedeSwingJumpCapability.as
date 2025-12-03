struct FCentipedeSwingJumpActivationParams
{
	bool bJumpFollower = false;
	UCentipedeSwingJumpTargetComponent JumpTargetComponent = nullptr;

	FVector SlackTeleport = FVector::ZeroVector;
}

class UCentipedeSwingJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeSwingJump);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerCentipedeSwingComponent SwingComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	const float GravityMultiplier = 1.5;

	FVector SwingJumpPlane;
	bool bInputBlocked = false;

	// Used for networking grace period
	FHazeAcceleratedVector AcceleratedVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		SwingComponent = UPlayerCentipedeSwingComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();

		// Slow acceleration
		AcceleratedVelocity.PrecisionLambertNominator = 4.47228;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeSwingJumpActivationParams& ActivationParams) const
	{
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent == nullptr)
			return false;

		const bool bOtherPlayerStartedLeadJump = OtherPlayerSwingComponent.GetAndConsumeStartedLeadJump();
		const bool bOtherPlayerWasBitingSwingPoint = OtherPlayerSwingComponent.GetAndConsumeWasBitingSwingPoint();
		const bool bOtherPlayerImmediateNetworkBitingSwingPoint = OtherPlayerSwingComponent.IsImmediateNetworkBitingSwingPoint();

		// Player is being forced to jump
		UCentipedeSwingLandTargetComponent LandTargetComponent;
		if (SwingComponent.ConsumeForcedLandTargetJump(LandTargetComponent))
		{
			ActivationParams.JumpTargetComponent = LandTargetComponent;
			return true;
		}

		// Never jump when grounded
		if (MovementComponent.IsOnAnyGround())
			return false;

		// Don't activate if this player is biting a swing point
		if (SwingComponent.GetActiveSwingPoint() != nullptr)
			return false;

		// This player let go, so now follow other jumping guy
		if (bOtherPlayerStartedLeadJump)
		{
			// No need for this check since swing jump already uses immediate net activation
			// if (!OtherPlayerSwingComponent.IsImmediateNetworkBitingSwingPoint())
			// 	return false;

			ActivationParams.bJumpFollower = true;
			ActivationParams.JumpTargetComponent = OtherPlayerSwingComponent.SwingJumpTarget;
			return true;
		}

		if (!bOtherPlayerWasBitingSwingPoint)
			return false;

		if (bOtherPlayerImmediateNetworkBitingSwingPoint)
			return false;

		// Find a jump target
		ActivationParams.JumpTargetComponent = SwingComponent.FindSwingJumpTarget(AcceleratedVelocity.Value);
		ActivationParams.SlackTeleport = Centipede::ConstrainPlayerLocationToBody(Player, Player.ActorLocation, Centipede::MaxAirPlayerDistance);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate if we hit ground whose actor doesn't hold the swing point
		if (MovementComponent.IsOnWalkableGround() && ActiveDuration > 0.1)
		{
			// if (MovementComponent.Velocity.GetSafeNormal().DotProduct(MovementComponent.WorldUp) < 0.0)
			if (MovementComponent.GroundContact.Actor != nullptr)
			{
				auto GroundSwingPointComponent = UCentipedeSwingPointComponent::Get(MovementComponent.GroundContact.Actor);
				if (GroundSwingPointComponent == nullptr)
					return true;

				if (GroundSwingPointComponent != UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer).GetPreviousSwingPoint())
					return true;
			}
		}

		// Player bit a swing point
		if (SwingComponent.GetActiveSwingPoint() != nullptr)
			return true;

		// Other player bit a swing point
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent != nullptr)
		{
			if (OtherPlayerSwingComponent.GetActiveSwingPoint() != nullptr)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeSwingJumpActivationParams ActivationParams)
	{
		SwingComponent.bJumping = true;
		SwingComponent.ForcedSwingJumpTarget = nullptr;
		SwingComponent.bJumpFollower = ActivationParams.bJumpFollower;
		SwingComponent.SwingJumpTarget = ActivationParams.JumpTargetComponent;
		if (SwingComponent.SwingJumpTarget != nullptr)
		{
			Player.BlockCapabilities(CapabilityTags::Input, this);
			bInputBlocked = true;
		}

		CentipedeComponent.ApplyDisableBodyCollisionWithPlayer(this);

		// Stahp replicating body, the swing speed looks assy otherwise.
		CentipedeComponent.Centipede.ApplyBodyReplicationBlock(this);

		if (HasControl())
		{
			// Jump towards a swing point
			FVector JumpImpulse;
			if (SwingComponent.SwingJumpTarget != nullptr)
			{
				if (SwingComponent.bJumpFollower)
				{
					if (!ActivationParams.SlackTeleport.IsZero())
						Player.SmoothTeleportActor(ActivationParams.SlackTeleport, Player.ActorRotation, this, 0.02);

					// Follow other player to his own landing spawt
					if (SwingComponent.SwingJumpTarget.IsA(UCentipedeSwingLandTargetComponent)) // Eman TODO: Irrelevant and redundant (and shallow and pedantic)
					{
						JumpImpulse = SwingComponent.SwingJumpTarget.GetJumpImpulseForPlayer(Player, MovementComponent.GravityForce * GravityMultiplier);
						SwingJumpPlane = SwingComponent.SwingJumpTarget.GetNormalVector();
					}
					else
					{
						// Add just a smidgen of velocity
						JumpImpulse = SwingComponent.SwingJumpTarget.GetJumpImpulseForPlayer(Player, MovementComponent.GravityForce * GravityMultiplier);
						SwingJumpPlane = SwingComponent.SwingJumpTarget.GetNormalVector();

						// Redirect impulse to torsion
						FVector Torsion = SwingJumpPlane.CrossProduct(Player.OtherPlayer.ActorVelocity.GetSafeNormal()).GetSafeNormal().CrossProduct(-SwingJumpPlane).GetSafeNormal();
						JumpImpulse = Torsion * JumpImpulse.Size() * 0.2;
					}
				}
				else
				{
					JumpImpulse = SwingComponent.SwingJumpTarget.GetJumpImpulseForPlayer(Player, MovementComponent.GravityForce * GravityMultiplier);
					SwingJumpPlane = SwingComponent.SwingJumpTarget.GetNormalVector();
				}

				// Debug::DrawDebugDirectionArrow(Player.ActorLocation, LaunchImpulse, LaunchImpulse.Size(), 5, FLinearColor::Green, 10, 2);
			}
			else
			{
				// Just use current velocity
				JumpImpulse = MovementComponent.Velocity;
				SwingJumpPlane = Player.MeshOffsetComponent.UpVector;
			}

			Player.SetActorVelocity(JumpImpulse);
		}
		else
		{
			if (!ActivationParams.bJumpFollower)
			{
				// Teleport to last predcited swing location
				// Player.MeshOffsetComponent.FreezeTransformAndLerpBackToParent(this, 0.2);
				// Player.SetActorLocation(SwingComponent.Remote_LastPredictedSwingLocation);
			}

			if (SwingComponent.SwingJumpTarget != nullptr)
				SwingJumpPlane = SwingComponent.SwingJumpTarget.GetNormalVector();
			else
				SwingJumpPlane = Player.MeshOffsetComponent.UpVector;
		}

		SwingComponent.OnSwingJumpEvent.Broadcast(Player);

		Player.SetActorTimeDilation(UCentipedeSwingMovementSettings::GetSettings(Player).JumpTimeDilation, this);

		Player.BlockCapabilities(CentipedeTags::CentipedeCrawl, this);
		Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bInputBlocked)
		{
			Player.UnblockCapabilities(CapabilityTags::Input, this);
			bInputBlocked = false;
		}

		SwingComponent.bJumping = false;
		SwingComponent.bJumpFollower = false;
		SwingComponent.SwingJumpTarget = nullptr;

		CentipedeComponent.ApplyDisableBodyCollisionWithPlayer(this);
		CentipedeComponent.Centipede.ClearBodyReplicationBlock(this);

		Player.MeshOffsetComponent.ResetOffsetWithLerp(SwingComponent, 0.5);

		Player.UnblockCapabilities(CentipedeTags::CentipedeCrawl, this);
		Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);

		Player.ClearActorTimeDilation(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Network::IsGameNetworked())
			AcceleratedVelocity.AccelerateTo(Player.ActorVelocity, Network::PingRoundtripSeconds, DeltaTime);
		else
			AcceleratedVelocity.SnapTo(Player.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (Player.IsCapabilityTagBlocked(CapabilityTags::Input))
		// 	Debug::DrawDebugString(Player.ActorLocation, "BLOCKED", ColorDebug::Red, 0.0, 3.0);

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Inherit velocity and add gravity
				FVector Velocity = MovementComponent.Velocity;
				Velocity += MovementComponent.Gravity * DeltaTime * GravityMultiplier;

				if (SwingComponent.bJumpFollower)
					Centipede::ConstrainAirVelocityToBody(Player.ActorLocation, Player.OtherPlayer, Centipede::MaxAirPlayerDistance, DeltaTime, Velocity);

				MoveData.AddVelocity(Velocity);

				// Tick mesh rotation
				FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
				FQuat MeshRotation = FQuat::MakeFromXZ(-PlayerToOtherPlayer, SwingJumpPlane);
				Player.MeshOffsetComponent.LerpToRotation(SwingComponent, MeshRotation, 0.1);

				// Debug::DrawDebugDirectionArrow(Player.ActorLocation, SwingJumpPlane, 1000, 5, FLinearColor::Yellow);
			}
			else
			{
				// Get freshest sync info
				float LatestCrumbTrailTime = 0;
				FHazeSyncedActorPosition SyncedPosition;
				UHazeCrumbSyncedActorPositionComponent PlayerCrumbComponent = UHazeCrumbSyncedActorPositionComponent::Get(Player);
				PlayerCrumbComponent.GetLatestAvailableData(SyncedPosition, LatestCrumbTrailTime);

				FVector PredictedLocation = Centipede::GetPredictedLocation(Player.ActorLocation, SyncedPosition, LatestCrumbTrailTime, DeltaTime);

				// Constrain location to body again after lerp
				FVector PredictedDelta = PredictedLocation - Player.ActorLocation;

				if (SwingComponent.bJumpFollower)
					Centipede::ConstrainAirVelocityToBody(PredictedLocation, Player.OtherPlayer, Centipede::MaxAirPlayerDistance, DeltaTime, PredictedDelta);

				PredictedLocation += PredictedDelta * DeltaTime;

				MoveData.ApplyManualSyncedLocationAndRotation(PredictedLocation, SyncedPosition.WorldVelocity, SyncedPosition.WorldRotation);

				FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - PredictedLocation).GetSafeNormal();
				FQuat MeshRotation = FQuat::MakeFromXZ(-PlayerToOtherPlayer, SwingJumpPlane);
				Player.MeshOffsetComponent.LerpToRotation(SwingComponent, MeshRotation, 0.1);

				// Debug::DrawDebugDirectionArrow(Player.ActorLocation, SwingJumpPlane, 1000);
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Tick mesh rotation
		// FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
		// FQuat MeshRotation = FQuat::MakeFromXZ(-PlayerToOtherPlayer, SwingJumpPlane);
		// Player.MeshOffsetComponent.LerpToRotation(SwingComponent, MeshRotation, 0.1);
	}
}