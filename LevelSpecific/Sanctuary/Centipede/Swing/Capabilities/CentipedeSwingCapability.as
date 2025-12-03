struct FCentipedeSwingActivationParams
{
	UCentipedeSwingPointComponent SwingPoint = nullptr;

	FVector SlackTeleport = FVector::ZeroVector;
	bool bCrawlTeleport = false;
}

class UCentipedeSwingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeSwing);

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50; // Must tick before other centipede movement

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerCentipedeSwingComponent SwingComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UCentipedeSwingPointComponent SwingPoint;

	UCentipedeSwingMovementSettings SwingSettings;

	const float SmoothInAccelerationDuration = 0.02;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		SwingComponent = UPlayerCentipedeSwingComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSweepingMovementData();
		SwingSettings = UCentipedeSwingMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeSwingActivationParams& ActivationParams) const
	{
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent.GetActiveSwingPoint() == nullptr)
			return false;

		ActivationParams.SwingPoint = OtherPlayerSwingComponent.GetActiveSwingPoint();
		ActivationParams.bCrawlTeleport = CentipedeComponent.IsCrawling();
		ActivationParams.SlackTeleport = Centipede::ConstrainPlayerLocationToBody(Player, Player.ActorLocation, SwingComponent.MaxPlayerSwingDistance - Centipede::SegmentRadius);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent.GetActiveSwingPoint() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeSwingActivationParams ActivationParams)
	{
		SwingPoint = ActivationParams.SwingPoint;
		SwingComponent.bSwinging = true;

		CentipedeComponent.ApplyDisableBodyCollisionWithPlayer(this);

		// Need to relocate player due to collider's rotation change if player
		// was crawling (was using  MovementAlignsWithGroundContact)
		if (ActivationParams.bCrawlTeleport)
		{
			// Eman TODO: Add a multiplier depending on slope angle?
			FVector ColliderCenter = Player.ActorLocation + Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;

			// Eman TODO: Add collision check
			FVector Offset = -FVector::UpVector * Player.CapsuleComponent.CapsuleHalfHeight;

			FQuat MeshRotation = Player.ActorQuat;
			FRotator Rotation = FRotator::MakeFromXZ(Player.ActorLocation - Player.OtherPlayer.ActorLocation, FVector::UpVector);
			// Player.TeleportActor(ColliderCenter + Offset, Rotation, this, false);
			Player.SetActorTransform(FTransform(Rotation, ColliderCenter + Offset));
			Player.MeshOffsetComponent.SnapToRotation(SwingComponent, MeshRotation);

			// Eman TODO: Potentially add downwards acceleration when starting from crawl position
			// FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
			// float DirectionMultiplier = Math::Sign(PlayerToOtherPlayer.DotProduct(-SwingPoint.RightVector));
			// FVector Impulse = PlayerToOtherPlayer.CrossProduct(SwingPoint.SwingPlaneVector).GetSafeNormal() * DirectionMultiplier + PlayerToOtherPlayer;
			// Player.SetActorVelocity(Impulse * Centipede::BodyGravityMagnitude);

			// Debug::DrawDebugDirectionArrow(Player.ActorLocation, Impulse, 1000, 4, FLinearColor::Purple, 4, 4);
		}

		// Smooth teleport player closer if slacking
		if (!ActivationParams.SlackTeleport.IsZero())
		{
			Player.SmoothTeleportActor(ActivationParams.SlackTeleport, Player.ActorRotation, this, SmoothInAccelerationDuration);
			CentipedeComponent.Centipede.bJustTeleported = true;
		}

		// Stahp replicating body, the swing speed looks assy otherwise.
		// Also since body is stretched we don't need to worry about both sides being diferentes.
		CentipedeComponent.Centipede.ApplyBodyReplicationBlock(this);

		Player.BlockCapabilities(CentipedeTags::CentipedeCrawl, this);
		Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);

		SwingComponent.OnSwingStart.Broadcast(Player, ECentipedePlayerSwingRole::Swinger, SwingPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComponent.bSwinging = false;

		Player.MeshOffsetComponent.ResetOffsetWithLerp(SwingComponent, 0.5);
		Player.MeshOffsetComponent.ClearOffset(this);

		CentipedeComponent.ClearDisableBodyCollisionWithPlayer(this);
		CentipedeComponent.Centipede.ClearBodyReplicationBlock(this);

		Player.UnblockCapabilities(CentipedeTags::CentipedeCrawl, this);
		Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			MoveData.BlockGroundTracingForThisFrame();

			if (HasControl())
			{
				FVector Velocity = MovementComponent.Velocity;

				// Add input
				FVector Input = CalculatePlayerInput();
				Velocity += Input * DeltaTime;

				AddGravity(Velocity, DeltaTime);
				AddDrag(Velocity, Input, DeltaTime);

				SwingPoint.ConstrainVelocityToSwingPlane(Velocity);
				ConstrainVelocityToBody(Player.ActorLocation + Velocity * DeltaTime, Velocity, DeltaTime);

				// Push player to swing plane, if oot
				// add offset downwards to compensate for mesh-collider rotation
				FVector AdjustedPlayerLocation = Player.ActorLocation + SwingPoint.SwingPlaneVector * Player.CapsuleComponent.CapsuleHalfHeight;
				FVector SwingPlaneOffset = (SwingPoint.WorldLocation - AdjustedPlayerLocation + SwingPoint.SwingPlaneVector * Player.CapsuleComponent.CapsuleHalfHeight * 2).ConstrainToDirection(SwingPoint.SwingPlaneVector);
				Velocity += SwingPlaneOffset * SwingPlaneOffset.Size() * DeltaTime;

				MoveData.AddVelocity(Velocity);

				if (!Velocity.IsNearlyZero())
					MoveData.SetRotation(Velocity.Rotation());
			}
			else
			{
				// Eman TODO: Needs more testing when releasing and jumping

				// Get freshest sync info
				float LatestCrumbTrailTime = 0;
				FHazeSyncedActorPosition SyncedPosition;
				UHazeCrumbSyncedActorPositionComponent PlayerCrumbComponent = UHazeCrumbSyncedActorPositionComponent::Get(Player);
				PlayerCrumbComponent.GetLatestAvailableData(SyncedPosition, LatestCrumbTrailTime);

				// Add potential swing point velocity (do we really need to???)
				SyncedPosition.WorldVelocity += SwingPoint.GetVelocity();

				// Constrain predicted velocity to body
				// ConstrainVelocityToBody(Player.ActorLocation, SyncedPosition.WorldVelocity, DeltaTime);

				// Push player down if going above swingPoint height
				{
					FVector PlayerToSwingPoint = (SwingPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
					float VerticalSwingProjection = PlayerToSwingPoint.DotProduct(FVector::UpVector);
					float SwingAngle = Math::RadiansToDegrees(Math::Acos(VerticalSwingProjection));

					// Only push down if velocity is aiming upwards
					FVector VerticalVelocity = SyncedPosition.WorldVelocity.ConstrainToDirection(FVector::UpVector);
					if (VerticalVelocity.DotProduct(FVector::UpVector) > 0)
					{
						// Check if player is exceeding max angle and push down
						if (SwingAngle > SwingSettings.MaxSwingAngle)
							SyncedPosition.WorldVelocity -= VerticalVelocity * Math::Sqrt(VerticalVelocity.Size()) * DeltaTime * 0.1;
					}
				}

				FVector PredictedSwingLocation = Centipede::GetPredictedLocation(Player.ActorLocation, SyncedPosition, LatestCrumbTrailTime, DeltaTime);

				// Constrain location to body again after lerp
				FVector PredictedDelta = PredictedSwingLocation - Player.ActorLocation;
				ConstrainVelocityToBody(PredictedSwingLocation, PredictedDelta, DeltaTime);
				PredictedSwingLocation += PredictedDelta * DeltaTime;

				// Go go go!
				MoveData.ApplyManualSyncedLocationAndRotation(PredictedSwingLocation, SyncedPosition.WorldVelocity, SyncedPosition.WorldRotation);
				SwingComponent.Remote_LastPredictedSwingLocation = PredictedSwingLocation;
			}

			MovementComponent.ApplyMove(MoveData);

			// Offset mesh rotation
			FVector MoveInput = CentipedeComponent.MovementInput.GetSafeNormal();
			FQuat MeshRotation = GetMeshRotation(MoveInput);
			Player.MeshOffsetComponent.LerpToRotation(SwingComponent, MeshRotation, MoveInput.IsNearlyZero() ? 0.5 : 0.2);

			// Offset mesh location to compensate for plane adjust in movement.
			// Do this after initial smooth in is done.
			if (ActiveDuration >= SmoothInAccelerationDuration)
			{
				FVector AdjustedLocation = Player.ActorLocation - SwingPoint.SwingPlaneVector * Player.CapsuleComponent.CapsuleRadius * 2.0;
				Player.MeshOffsetComponent.SnapToLocation(this, AdjustedLocation);
			}
		}
	}

	FVector CalculatePlayerInput() const
	{
		FVector PlayerToSwingPoint = (SwingPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
		
		// note(Ylva) The swing for a head is really just a left or right movement. Therefore we remap up & down into additional force, like a swing!
		/*
		
		\|/_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_\|/
		@}8_)>|_>|_>|_>|_>__<_|<_|<_|<_|<(_8{
		/|\ v v v v v v v v v v v v v v v /|\
		                                   V
		
		^ Totally a centipede attached to a swing point
		Pressing down here should move Cento head towards bottom, which is head local right
		*/
		
		// Some SwingPoints have their right vector pointing right, some have it pointing upwards, so we just calculate this manually
		FVector SwingRightVector = SwingPoint.SwingPlaneVector.CrossProduct(MovementComponent.WorldUp).GetSafeNormal();
		FVector SwingForwardVector = MovementComponent.WorldUp.CrossProduct(SwingRightVector).GetSafeNormal();
		float MovementRightwards = SwingRightVector.DotProduct(CentipedeComponent.MovementInput);
		float MovementForwards = SwingForwardVector.DotProduct(CentipedeComponent.MovementInput);

		// Hazing the up and down into left and right
		FVector HazedInput = SwingRightVector * MovementRightwards;
		if (PlayerToSwingPoint.DotProduct(SwingRightVector) > 0.0)
			HazedInput += SwingRightVector * MovementForwards; // right side
		else
			HazedInput -= SwingRightVector * MovementForwards; // left side
		HazedInput = HazedInput.GetSafeNormal();

		// Used to flip cross product if player swings hard and ends above swing point
		float DirectionMultiplier = PlayerToSwingPoint.DotProduct(Player.MovementWorldUp) < 0.0 ? -1.0 : 1.0;

		FVector Binormal = PlayerToSwingPoint.CrossProduct(HazedInput).GetSafeNormal();
		Binormal = -PlayerToSwingPoint.CrossProduct(Binormal) * DirectionMultiplier;

		// Don't add any input if we are aiming upwards and exceeding max swing angle
		if (VelocityExceedsMaxSwingAngle(Binormal))
			return FVector::ZeroVector;

		FVector PlayerInput = Binormal * SwingSettings.MoveSpeed * HazedInput.Size();
		SwingPoint.ConstrainVelocityToSwingPlane(PlayerInput);
		return PlayerInput;
	}

	void AddGravity(FVector& Velocity, float DeltaTime)
	{
		Velocity += MovementComponent.Gravity * DeltaTime * 2.0;
	}

	void AddDrag(FVector& Velocity, FVector Input, float DeltaTime)
	{
		float Coefficient = Math::Lerp(0.3, 0.7, CentipedeComponent.MovementInput.Size());

		// Add more drag if player is going above swingPoint height
		FVector PlayerToSwingPoint = (SwingPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
		float VerticalSwingProjection = PlayerToSwingPoint.DotProduct(FVector::UpVector);
		float SwingAngle = Math::RadiansToDegrees(Math::Acos(VerticalSwingProjection));

		// Only push down if velocity is aiming upwards
		FVector VerticalVelocity = Velocity.ConstrainToDirection(FVector::UpVector);
		if (VerticalVelocity.DotProduct(FVector::UpVector) > 0)
		{
			// Check if player is exceeding max angle
			if (SwingAngle > SwingSettings.MaxSwingAngle)
			{
				VerticalVelocity -= VerticalVelocity * Math::Sqrt(VerticalVelocity.Size()) * DeltaTime * 0.1;
			}
			// Smooth-in drag somehow?
			// else if (SwingAngle > SwingSettings.MaxSwingAngle - 15.0)
			{
				// VerticalVelocity -= VerticalVelocity * Math::Sqrt(VerticalVelocity.Size()) * DeltaTime * 0.05;
			}

			FVector HorizontalVelocity = Velocity.ConstrainToPlane(FVector::UpVector);
			Velocity = HorizontalVelocity + VerticalVelocity;
		}

		FVector Drag = -Velocity * Coefficient * DeltaTime;
		Velocity += Drag.GetClampedToMaxSize(Velocity.Size());
	}

	void ConstrainVelocityToBody(FVector PlayerLocation, FVector& Velocity, float DeltaTime)
	{
		// Nvm if player aims towards other player
		FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - PlayerLocation).GetSafeNormal();
		// if (PlayerToOtherPlayer.DotProduct(Velocity.GetSafeNormal()) >= 0.0) // This was optimization but messes up when when moving swing point upwards
		// 	return;

		// Get distance between heads and redirect velocity if too high
		FVector NextPlayerLocation = PlayerLocation + Velocity * DeltaTime;
		float DistanceBetweenPlayers = Player.OtherPlayer.ActorLocation.Distance(NextPlayerLocation);
		if (DistanceBetweenPlayers >= SwingComponent.MaxPlayerSwingDistance)
		{
			// Redirect velocity to swing
			// FVector Binormal = PlayerToOtherPlayer.CrossProduct(Velocity.GetSafeNormal()).GetSafeNormal();
			// Binormal = Binormal.CrossProduct(PlayerToOtherPlayer).GetSafeNormal();
			// Velocity = Binormal * Velocity.Size();

			// Make up for any slack we give
			float DeltaLength = DistanceBetweenPlayers - SwingComponent.MaxPlayerSwingDistance;

			FVector MoveDelta = Velocity * DeltaTime;
			FVector DeltaCorrection = PlayerToOtherPlayer * DeltaLength;

			float MaxSpeed = MoveDelta.Size() + Player.OtherPlayer.ActorVelocity.Size();
			MoveDelta = (MoveDelta + DeltaCorrection).GetClampedToMaxSize(MaxSpeed);

			// Convert back to velocity
			Velocity = MoveDelta / DeltaTime;

			// Debug::DrawDebugDirectionArrow(Player.ActorLocation, DeltaCorrection, DeltaLength * 10, 10, FLinearColor::Green, 10, 1);
		}
	}

	FQuat GetMeshRotation(FVector Input) const
	{
		FVector ForwardVector = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
		// if (!Input.IsNearlyZero())
		// 	return FQuat::MakeFromXZ(Input - ForwardVector * 0.5, SwingPoint.GetSwingPlaneVector());

		FVector VelocityComponent = FVector::ZeroVector;
		if (!MovementComponent.Velocity.IsNearlyZero(300.0))
		{
			VelocityComponent =	MovementComponent.Velocity.GetSafeNormal().ConstrainToPlane(SwingPoint.SwingPlaneVector);
			VelocityComponent *= Math::Sqrt(MovementComponent.Velocity.Size()) * 0.03;
		}

		return FQuat::MakeFromXZ(VelocityComponent - ForwardVector, SwingPoint.GetSwingPlaneVector());
	}

	bool VelocityExceedsMaxSwingAngle(const FVector Velocity) const
	{
		// Only check if velocity is going upwards
		FVector VerticalVelocity = Velocity.ConstrainToDirection(Player.MovementWorldUp);
		if (VerticalVelocity.DotProduct(Player.MovementWorldUp) > 0)
		{
			FVector PlayerToSwingPoint = (SwingPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
			float VerticalSwingProjection = PlayerToSwingPoint.DotProduct(Player.MovementWorldUp);
			float SwingAngle = Math::RadiansToDegrees(Math::Acos(VerticalSwingProjection));

			// Check if swinger is exceeding max angle
			if (SwingAngle > SwingSettings.MaxSwingAngle)
				return true;
		}

		return false;
	}
}