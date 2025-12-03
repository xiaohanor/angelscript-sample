#if !RELEASE
namespace DevTogglesMagnetDrone
{
	const FHazeDevToggleBool DrawAttachToBoatCone;
};
#endif

enum EMagnetDroneAttachToBoatMovementState
{
	FallingIntoBoat,
	Bounced,
	Attached
};

class UMagnetDroneAttachToBoatCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MagnetDroneTags::AttachToBoat);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	
	default BlockExclusionTags.Add(MagnetDroneTags::AttachToBoatBlockExclusionTag);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 10;	// Very early

	UMagnetDroneAttachToBoatComponent AttachToBoatComp;
	UMagnetDroneComponent DroneComp;
	UMagnetDroneJumpComponent JumpComp;

	UPlayerMovementComponent MoveComp;
	UMagnetDroneAttachToBoatMovementData MoveData;

	AHazePlayerCharacter SwarmDrone;
	UPlayerSwarmDroneComponent SwarmDroneComp;
	UPlayerSwarmBoatComponent SwarmBoatComp;

	float TimeToLand;
	bool bSyncingRelativeToBoat = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UMagnetDroneAttachToBoatMovementData);

		SwarmDrone = Drone::GetSwarmDronePlayer();
		SwarmDroneComp = UPlayerSwarmDroneComponent::Get(SwarmDrone);
		SwarmBoatComp = UPlayerSwarmBoatComponent::Get(SwarmDrone);

#if !RELEASE
		DevTogglesMagnetDrone::DrawAttachToBoatCone.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnAnyGround())
			return false;

		if(MoveComp.VerticalSpeed > 0)
			return false;

		if(!SwarmBoatComp.CanMagnetDroneAttach())
			return false;

		//Debug::DrawDebugSphere(SwarmDrone.ActorLocation, DistanceThreshold, 12);

		if(!IsPointWithinCone(Player.ActorLocation))
			return false;
		
		FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player, n"AttachToBoat");
		const FHitResult Hit = TraceSettings.QueryTraceSingle(Player.ActorLocation, AttachToBoatComp.GetTargetLocation());

#if !RELEASE
		TEMPORAL_LOG(AttachToBoatComp).HitResults("AttachToBoat", Hit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if(Hit.IsValidBlockingHit())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		if(!SwarmBoatComp.CanMagnetDroneAttach())
			return true;

		if(AttachToBoatComp.HadCollisionWhileOnBoatThisFrame())
			return true;

		if(!AttachToBoatComp.IsAttachedToBoat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, MagnetDroneTags::AttachToBoatBlockExclusionTag, this);
		Player.BlockCapabilitiesExcluding(MagnetDroneTags::MagnetDroneJump, MagnetDroneTags::AttachToBoatBlockExclusionTag, this);
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);

		MoveComp.FollowComponentMovement(SwarmDroneComp.CollisionComponent, this, EMovementFollowComponentType::ReferenceFrame);

		FVector Offset = Player.ActorLocation - AttachToBoatComp.GetTargetLocation();

		FVector HorizontalOffset = Offset;
		HorizontalOffset.Z = 0;

		AttachToBoatComp.VerticalOffset = Offset.Z;
		AttachToBoatComp.VerticalSpeed = MoveComp.Velocity.DotProduct(FVector::UpVector);

		AttachToBoatComp.AccHorizontalOffset.SnapTo(HorizontalOffset, Player.ActorVelocity.VectorPlaneProject(FVector::UpVector) - AttachToBoatComp.GetTargetVelocity().VectorPlaneProject(FVector::UpVector));

		AttachToBoatComp.AttachToBoat();

		MoveComp.ApplyCrumbSyncedRelativePosition(this, SwarmDrone.RootComponent);
		bSyncingRelativeToBoat = true;

		TimeToLand = AttachToBoatComp.CalculateTimeToLand();
		AttachToBoatComp.MovementState = EMagnetDroneAttachToBoatMovementState::FallingIntoBoat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneJump, this);
		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);

		MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);

		AttachToBoatComp.DetachFromBoat();
		AttachToBoatComp.bHasLandedOnBoat = false;

		USwarmBoatEventHandler::Trigger_OnMagnetDroneExit(Player.OtherPlayer);

		UPlayerSwarmBoatComponent SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Player.OtherPlayer);
		if (SwarmBoatComponent != nullptr)
			SwarmBoatComponent.OnMagnetDroneDisembarked.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && bSyncingRelativeToBoat)
		{
			if (HasControl())
			{
				bool bKeepRelativeSync = true;

				FVector RelativeLocation = Player.ActorLocation - AttachToBoatComp.GetTargetLocation();

				// Too far away
				if(!IsPointWithinCone(RelativeLocation))
					bKeepRelativeSync = false;

				// Going downward
				if(MoveComp.VerticalSpeed < 0)
					bKeepRelativeSync = false;

				// Blocked
				if (IsBlocked())
					bKeepRelativeSync = false;

				// Continue syncing relative to the boat until we definitively leave it
				if (!bKeepRelativeSync)
				{
					MoveComp.ClearCrumbSyncedRelativePosition(this);
					bSyncingRelativeToBoat = false;
				}
			}
			else
			{
				// On the remote side, do a smooth teleport once we aren't relative to the boat anymore
				if (MoveComp.GetCrumbSyncedPosition().RelativeComponent != SwarmDrone.RootComponent)
				{
					const float LerpTime = Math::GetMappedRangeValueClamped(FVector2D(0, 500), FVector2D(0.0, 1.0), SwarmDrone.ActorVelocity.Size());
					Player.MeshOffsetComponent.FreezeHorizontalLocationAndLerpBackToParent(this, LerpTime, MoveComp.WorldUp);
					bSyncingRelativeToBoat = false;
				}
			}
		}

#if !RELEASE
		if(DevTogglesMagnetDrone::DrawAttachToBoatCone.IsEnabled())
		{
			FVector Intersection;
			if(Trajectory::TrajectoryPlaneIntersection(Player.ActorLocation, Player.ActorVelocity, AttachToBoatComp.GetTargetLocation(), Drone::Gravity, Intersection, MoveComp.WorldUp))
				Debug::DrawDebugPoint(Intersection, 5, FLinearColor::Yellow);
			//Debug::DrawDebugCircle(AttachToBoatComp.GetTargetLocation(), AttachToBoatComp.Settings.ConeTopRadius, 12, FLinearColor::Yellow);

			Debug::DrawDebugCircle(AttachToBoatComp.GetTargetLocation(), AttachToBoatComp.Settings.ConeBotRadius, 12, FLinearColor::Green);
			Debug::DrawDebugCircle(AttachToBoatComp.GetTargetLocation() + FVector(0, 0, AttachToBoatComp.Settings.ConeHeight), AttachToBoatComp.Settings.ConeTopRadius, 12, FLinearColor::Red);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			TickMovement(DeltaTime);

			FVector Offset = AttachToBoatComp.AccHorizontalOffset.Value;
			Offset += FVector(0, 0, AttachToBoatComp.VerticalOffset);

			const FVector TargetLocation = AttachToBoatComp.GetTargetLocation() + Offset;
			const FVector Delta = TargetLocation - Player.ActorLocation;

			FVector Velocity = Delta.VectorPlaneProject(MoveComp.WorldUp) / DeltaTime;
			Velocity += MoveComp.WorldUp * AttachToBoatComp.VerticalSpeed;

			MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void TickMovement(float DeltaTime)
	{
		switch(AttachToBoatComp.MovementState)
		{
			case EMagnetDroneAttachToBoatMovementState::FallingIntoBoat:
			{
				TickFalling(DeltaTime);

				if(AttachToBoatComp.VerticalOffset < 0)
				{
					// We have landed on the boat now
					if(!AttachToBoatComp.bHasLandedOnBoat)
						Crumb_InitialLandingInBoat();

					if(AttachToBoatComp.VerticalSpeed < -100)
					{
						// We landed with some speed, do a nice lil bounce
						AttachToBoatComp.VerticalSpeed = -AttachToBoatComp.VerticalSpeed * AttachToBoatComp.Settings.Bounciness;
						AttachToBoatComp.VerticalOffset = 1;
						AttachToBoatComp.MovementState = EMagnetDroneAttachToBoatMovementState::Bounced;
					}
					else
					{
						// We landed with very little speed, attach
						AttachToBoatComp.VerticalSpeed = 0;
						AttachToBoatComp.VerticalOffset = 0;
						AttachToBoatComp.MovementState = EMagnetDroneAttachToBoatMovementState::Attached;
					}
				}
				break;
			}

			case EMagnetDroneAttachToBoatMovementState::Bounced:
			{
				TickFalling(DeltaTime);

				if(AttachToBoatComp.VerticalOffset < 0)
				{
					// We landed after bouncing, this always means attach
					AttachToBoatComp.VerticalSpeed = 0;
					AttachToBoatComp.VerticalOffset = 0;
					AttachToBoatComp.MovementState = EMagnetDroneAttachToBoatMovementState::Attached;
				}
				break;
			}

			case EMagnetDroneAttachToBoatMovementState::Attached:
			{
				AttachToBoatComp.VerticalSpeed = 0;
				AttachToBoatComp.VerticalOffset = 0;
				break;
			}
		}
	}

	void TickFalling(float DeltaTime)
	{
		float Delta = AttachToBoatComp.VerticalSpeed * DeltaTime;
		AttachToBoatComp.VerticalSpeed = Acceleration::FInterpSpeedConstantToFramerateIndependent(AttachToBoatComp.VerticalSpeed, DroneComp.MovementSettings.AirMaxFallSpeed, DeltaTime, DroneComp.MovementSettings.AirMaxFallDeceleration, Delta);
		AttachToBoatComp.VerticalOffset += Delta;

		// While performing relative jumps, UMagnetDroneAttachToBoatRelativeJumpCapability handles horizontal offset
		if(!AttachToBoatComp.bIsPerformingRelativeJump)
		{
			if(!AttachToBoatComp.bHasLandedOnBoat)
			{
				// Move towards boat!
				AttachToBoatComp.AccHorizontalOffset.AccelerateTo(FVector::ZeroVector, TimeToLand, DeltaTime);
			}
			else
			{
				AttachToBoatComp.AccHorizontalOffset.AccelerateTo(FVector::ZeroVector, 0.1, DeltaTime);
			}
		}
	}

	// Call only from control side!
	UFUNCTION(CrumbFunction)
	void Crumb_InitialLandingInBoat()
	{
		if(AttachToBoatComp.bHasLandedOnBoat)
			return;

		AttachToBoatComp.bHasLandedOnBoat = true;

		FSwarmBoatWallImpactEventParams Params;
		Params.Strength = DroneComp.MoveComp.PreviousVelocity.Size() / 850;
		USwarmBoatEventHandler::Trigger_OnMagnetDroneEnter(Player.OtherPlayer, Params);

		UPlayerSwarmBoatComponent SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Player.OtherPlayer);
		if (SwarmBoatComponent != nullptr)
			SwarmBoatComponent.OnMagnetDroneBoarded.Broadcast();
	}

	bool IsPointWithinCone(FVector Location) const
	{
		FVector RelativeLocation = Location - AttachToBoatComp.GetTargetLocation();

		// Too high
		if(RelativeLocation.Z > AttachToBoatComp.Settings.ConeHeight)
			return false;

		// Too low
		if(RelativeLocation.Z < 5)
			return false;

		// Too far away horizontally
		const float HorizontalDistance = RelativeLocation.Size2D(FVector::UpVector);
		if(HorizontalDistance > AttachToBoatComp.Settings.ConeTopRadius)
			return false;

		FVector Intersection;
		if(Trajectory::TrajectoryPlaneIntersection(Player.ActorLocation, Player.ActorVelocity, AttachToBoatComp.GetTargetLocation(), Drone::Gravity, Intersection, MoveComp.WorldUp))
		{
			if(Intersection.Dist2D(AttachToBoatComp.GetTargetLocation()) < AttachToBoatComp.Settings.ConeBotRadius)
			{
				// We will land within the bottom circle
				// Attach!
				return true;
			}
		}

		const float HeightAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(0, AttachToBoatComp.Settings.ConeHeight),
			FVector2D(0, 1),
			RelativeLocation.Z
		);

		const float ConeRadius = Math::Lerp(
			AttachToBoatComp.Settings.ConeBotRadius,
			AttachToBoatComp.Settings.ConeTopRadius,
			HeightAlpha
		);

		// Too far away
		if(HorizontalDistance > ConeRadius)
			return false;

		return true;
	}
};