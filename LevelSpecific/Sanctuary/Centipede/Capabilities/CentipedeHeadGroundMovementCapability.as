class UCentipedeHeadGroundMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeMovement);
	default CapabilityTags.Add(CentipedeTags::CentipedeGroundMovement);

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UCentipedeMovementSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
		Settings = UCentipedeMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!MovementComponent.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementComponent.OverrideResolver(UCentipedeGroundMovementResolver, this);

		UMovementGravitySettings::SetGravityScale(Player, 2.0, this);
		UMovementSteppingSettings::SetEdgeRedirectType(Player, EMovementEdgeNormalRedirectType::Soft, this);

		MovementComponent.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled, EInstigatePriority::High);

		// Apply collisions with spline bounds
		auto SplineColliders = TListedActors<ACentipedeSplineCollision>().Array;
		if (SplineColliders.Num() > 0)
			MovementComponent.ApplySplineCollision(SplineColliders, this, ESplineCollisionWorldUp::GlobalUp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementComponent.ClearResolverOverride(UCentipedeGroundMovementResolver, this);

		UMovementGravitySettings::ClearGravityScale(Player, this);
		UMovementSteppingSettings::ClearEdgeRedirectType(Player, this);

		CentipedeComponent.ClearCentipedeBodyPlayerWorldUp(this);

		Player.MeshOffsetComponent.ClearOffset(this);

		MovementComponent.ClearFollowEnabledOverride(this);
		MovementComponent.ClearSplineCollision(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bOtherPlayerFalling = CentipedeComponent.IsOtherPlayerFalling();

		SetMovementFacingDirection(bOtherPlayerFalling);

		if (MovementComponent.PrepareMove(MoveData/*GetWorldUp(bOtherPlayerFalling)*/))
		{
			if (HasControl())
			{
				MoveData.OverrideStepUpAmountForThisFrame(Settings.StepUpSize);
				MoveData.OverrideStepDownAmountForThisFrame(Settings.StepDownSize);

				if (ShouldBeDraggedTowardsPlayer())
				{
					FVector PlayerToOtherPlayer = Player.OtherPlayer.ActorLocation - Player.ActorLocation;
					FVector FrameVelocity = PlayerToOtherPlayer.ConstrainToPlane(MovementComponent.WorldUp).GetSafeNormal() * Settings.MoveSpeed;
					FrameVelocity = Math::VInterpTo(MovementComponent.Velocity, FrameVelocity, DeltaTime, Settings.Acceleration);

					MoveData.AddVelocity(FrameVelocity);
					MoveData.AddGravityAcceleration();
				}
				else
				{
					// Eman TODO: pre-UXR no edge-lock test
					// if (!Settings.bCanLeaveEdges)
					// 	MoveData.StopMovementWhenLeavingEdgeThisFrame();

					FVector PlayerInput = GetInput(false);
					FVector FrameVelocity = Math::VInterpTo(MovementComponent.Velocity, PlayerInput, DeltaTime, Settings.Acceleration * 0.5);
					CentipedeComponent.ApplyHurryToOtherHeadSpeed(PlayerInput);

					ConstrainVelocityToBody(FrameVelocity, DeltaTime);
					ResolvePlayerCollision(FrameVelocity, DeltaTime);
					ConstrainToCrawlableArea(FrameVelocity, DeltaTime);

					MoveData.AddHorizontalVelocity(FrameVelocity);

					FVector VerticalVelocity = MovementComponent.Velocity.ConstrainToPlane(MovementComponent.GroundContact.Normal);
					VerticalVelocity -= MovementComponent.GroundContact.Normal * MovementComponent.GravityForce;
					MoveData.AddVerticalVelocity(VerticalVelocity);
				}

				MoveData.InterpRotationToTargetFacingRotation(Settings.GroundRotationSpeed);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		CentipedeComponent.ApplyCentipedeBodyPlayerWorldUp(MovementComponent.WorldUp, this);

		// Smooth out those ground normal transitions
		Player.MeshOffsetComponent.LerpToRotation(this, Player.ActorRotation.Quaternion(), 0.1);
	}

	void SetMovementFacingDirection(bool bOtherPlayerFalling)
	{
		if (CentipedeComponent.HasMovementFacingDirectionOverride())
		{
			Player.SetMovementFacingDirection(CentipedeComponent.GetMovementFacingDirectionOverride());
		}
		else
		{
			FVector MovementDirection = GetInput(true);
			if(!MovementDirection.IsNearlyZero())
			{
				Player.SetMovementFacingDirection(MovementDirection.GetSafeNormal());
			}
			else if (bOtherPlayerFalling && !MovementComponent.Velocity.IsZero())
			{
				Player.SetMovementFacingDirection(-MovementComponent.Velocity.GetSafeNormal());
			}
			else
			{
				// Rotate head with body in case other player is moving
				FVector NeckLocation = CentipedeComponent.GetNeckJointLocationForPlayer(Player.Player);
				FVector NeckHeadVector = (Player.ActorLocation - NeckLocation).GetSafeNormal().ConstrainToPlane(MovementComponent.WorldUp);
				FVector FacingDirection = Player.ActorForwardVector.ConstrainToCone(NeckHeadVector, Math::DegreesToRadians(Centipede::MaxHeadAngle));
				Player.SetMovementFacingDirection(FacingDirection);
			}
		}
	}

	FVector GetInput(bool bConstrainToNeck) const
	{
		FVector Input = CentipedeComponent.GetMovementInput();
		if (bConstrainToNeck)
		{
			// Constrain to neck joint
			FVector NeckLocation = CentipedeComponent.GetNeckJointLocationForPlayer(Player.Player);
			FVector NeckHeadVector = (Player.ActorLocation - NeckLocation).GetSafeNormal();
			Input = Input.ConstrainToCone(NeckHeadVector, Math::DegreesToRadians(Centipede::MaxHeadAngle));
		}

		return Input * Settings.MoveSpeed * CentipedeComponent.CatchUpSpeedMultiplier;
	}

	void ConstrainVelocityToBody(FVector& Velocity, float DeltaTime)
	{
		// Nvm if the other player is airborne
		if (Player.OtherPlayer.IsAnyCapabilityActive(CentipedeTags::CentipedeAirMovement))
			return;

		// Nvm if player aims towards other player
		FVector PlayerToOtherPlayer = Player.OtherPlayer.ActorLocation - Player.ActorLocation;
		if (PlayerToOtherPlayer.GetSafeNormal().DotProduct(Velocity.GetSafeNormal()) >= 0.0)
			return;

		// Get distance between heads
		FVector NextPlayerLocation = Player.ActorLocation + Velocity * DeltaTime;
		float DistanceBetweenPlayers = Player.OtherPlayer.ActorLocation.DistSquared(NextPlayerLocation);

		if (DistanceBetweenPlayers >= Centipede::GetMaxPlayerDistanceSquared())
		{
			Velocity = PlayerToOtherPlayer.CrossProduct(Player.MovementWorldUp) * 0.5;
			Velocity *= CentipedeComponent.GetMovementInput().ConstrainToDirection(Velocity.GetSafeNormal()).DotProduct(Velocity.GetSafeNormal());
			Velocity += PlayerToOtherPlayer * 0.25;

			Velocity = Math::VInterpTo(MovementComponent.Velocity, Velocity, DeltaTime, 5);
		}
	}

	// Handle stuff like when player lands on other player
	void ResolvePlayerCollision(FVector& Velocity, float DeltaTime)
	{
		// Eman TODO: Make nice
		// if (MovementComponent.GroundImpact.Actor.IsA(ACentipedeHead))
		// {
		// 	FVector Binormal = MovementComponent.GroundImpact.ImpactNormal.CrossProduct(MovementComponent.WorldUp);
		// 	Binormal = MovementComponent.GroundImpact.ImpactNormal.CrossProduct(Binormal);

		// 	Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, Binormal, 800, 5, FLinearColor::DPink);
		// 	Velocity += MovementComponent.GroundImpact.ImpactNormal * 10;
		// }
	}

	void ConstrainToCrawlableArea(FVector& FrameVelocity, float DeltaTime)
	{
		if (!CentipedeComponent.IsCrawling())
			return;

		FVector NextLocation = Player.ActorLocation + FrameVelocity * DeltaTime;

		// Go through active constraints
		ACentipedeCrawlConstraintVolume FailedConstraint;
		bool bInsideConstraints = false;
		for (ACentipedeCrawlConstraintVolume Constraint : CentipedeComponent.GetActiveCrawlConstraints())
		{
			// Constraint.DrawDebug();

			if (Constraint.IsLocationWithinConstraints(NextLocation))
			{
				bInsideConstraints = true;
				break;
			}

			FailedConstraint = Constraint;
		}

		if (!bInsideConstraints && FailedConstraint != nullptr)
		{
			FVector ConstrainedLocation = FailedConstraint.ConstrainLocation(NextLocation);
			FVector MoveDelta = ConstrainedLocation - Player.ActorLocation;
			FrameVelocity = (MoveDelta / DeltaTime).GetClampedToMaxSize(FrameVelocity.Size());
		}
	}

	void ConstrainToCrawlableArea_Legacy(FVector& FrameVelocity, float DeltaTime)
	{
		if (!CentipedeComponent.IsCrawling())
			return;

		UCentipedeCrawlableComponent CrawlableComponent = UCentipedeCrawlableComponent::Get(MovementComponent.GroundContact.Actor);
		if (CrawlableComponent != nullptr)
		{
			FCentipedeCrawlConstraint CrawlConstraint;
			if (CrawlableComponent.GetCurrentlyUsedConstraintForLocation(Player.ActorLocation, CrawlConstraint))
			{
				FVector NextLocation = Player.ActorLocation + FrameVelocity * DeltaTime;
				// if (!CrawlableComponent.IsLocationWithinConstraints(NextLocation))
				{
					FTransform CrawlConstraintTransform = CrawlConstraint.GetWorldTransform(CrawlableComponent.Owner);
					FVector ConstrainedLocation = CrawlConstraint.ConstrainLocation(NextLocation, CrawlConstraintTransform, DeltaTime);
					FrameVelocity = (ConstrainedLocation - Player.ActorLocation) / DeltaTime;
				}
			}
		}
	}

	bool ShouldBeDraggedTowardsPlayer() const
	{
		if (!CentipedeComponent.IsOtherPlayerFalling())
			return false;

		// Players must be at full stretch
		if (CentipedeComponent.GetStretchFraction() < 0.8)
			return false;

		// Don't follow player if other player is still moving towards us
		FVector OtherPlayerToPlayer = (Player.ActorLocation - Player.OtherPlayer.ActorLocation).GetSafeNormal();
		if (OtherPlayerToPlayer.DotProduct(Player.OtherPlayer.ActorVelocity.GetSafeNormal()) > 0)
			return false;

		// I mean, won't work in some cases but mÄh. We'll see...
		// if (Player.ActorLocation.Z < Player.OtherPlayer.ActorLocation.Z)
		// 	return false;

		return true;
	}

	// // Poopy
	// void ConstrainVelocityToVerletBody(FVector& Velocity, float DeltaTime)
	// {
	// 	// Nvm if the other player is airborne
	// 	if (Player.OtherPlayer.IsAnyCapabilityActive(CentipedeTags::AirMovement))
	// 		return;

	// 	// Eman TODO: Temp, implement proper slack stuff
	// 	FVector PlayerToOtherPlayer = CentipedeComponent.CentipedeBody.GetNextSegmentAfterHead(Player).ActorLocation - Player.ActorLocation;
	// 	float Slack = CentipedeComponent.CentipedeBody.GetHeadSlack(Player);
	// 	if (Slack > 250)
	// 	{
	// 		FVector NextHeadLocation = Player.ActorLocation + Velocity * DeltaTime;
	// 		float DistanceBetweenHeads = Player.OtherPlayer.ActorLocation.DistSquared(NextHeadLocation);

	// 		Velocity = PlayerToOtherPlayer.CrossProduct(Player.MovementWorldUp) * 0.5;
	// 		Velocity *= MovementComponent.MovementInput.ConstrainToDirection(Velocity.GetSafeNormal()).DotProduct(Velocity.GetSafeNormal());
	// 		Velocity += PlayerToOtherPlayer * 0.25;

	// 		Velocity = Math::VInterpTo(MovementComponent.Velocity, Velocity, DeltaTime, 5);
	// 	}
	// }

	FVector GetWorldUp(bool bOtherPlayerFalling) const
	{
		if (CentipedeComponent.IsCrawling() && !bOtherPlayerFalling)
			return MovementComponent.GroundContact.Normal;

		return FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value ("Speeed", MovementComponent.Velocity.Size());
	}
}