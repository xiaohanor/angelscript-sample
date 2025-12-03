struct FCentipedeHeadAirMovementActivationParams
{
	FVector SlackTeleport = FVector::ZeroVector;
}

class UCentipedeHeadAirMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeMovement);
	default CapabilityTags.Add(CentipedeTags::CentipedeAirMovement);

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerMovementComponent MovementComponent;
	UPlayerCentipedeSwingComponent SwingComponent;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		SwingComponent = UPlayerCentipedeSwingComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeHeadAirMovementActivationParams& ActivationParams) const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		ActivationParams.SlackTeleport = Centipede::ConstrainPlayerLocationToBody(Player, Player.ActorLocation, Centipede::MaxPlayerDistance + Centipede::SegmentRadius);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeHeadAirMovementActivationParams ActivationParams)
	{
		if (!ActivationParams.SlackTeleport.IsZero())
			Player.SmoothTeleportActor(ActivationParams.SlackTeleport, Player.ActorRotation, this, 0.01);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector Velocity = MovementComponent.Velocity;

				// Add gravity
				FVector Gravity = MovementComponent.Gravity * 2.0;
				Velocity += Gravity * DeltaTime;

				// Add drag
				const float Coefficient = 0.3; // I dunno?
				FVector Drag = -Velocity * Coefficient * DeltaTime;
				Velocity += Drag.GetClampedToMaxSize(Velocity.Size());

				ConstrainToEventualSwing(Velocity);
				Centipede::ConstrainAirVelocityToBody(Player.ActorLocation, Player.OtherPlayer, Centipede::MaxAirPlayerDistance, DeltaTime, Velocity);

				MoveData.AddVelocity(Velocity);

				// if (!Velocity.IsNearlyZero())
				// 	MoveData.InterpRotationTo(Velocity.ToOrientationQuat(), 3.0);

				FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
				FQuat Rotation = FQuat::MakeFromX(-PlayerToOtherPlayer);

				MoveData.InterpRotationTo(Rotation, 3.0);
			}
			else
			{
				// Get freshest sync info
				float LatestCrumbTrailTime = 0;
				FHazeSyncedActorPosition SyncedPosition;
				UHazeCrumbSyncedActorPositionComponent PlayerCrumbComponent = UHazeCrumbSyncedActorPositionComponent::Get(Player);
				PlayerCrumbComponent.GetLatestAvailableData(SyncedPosition, LatestCrumbTrailTime);

				// Get predicted location
				FVector PredictedLocation = Centipede::GetPredictedLocation(Player.ActorLocation, SyncedPosition, LatestCrumbTrailTime, DeltaTime);

				// Constrain location to body again after lerp
				FVector PredictedDelta = PredictedLocation - Player.ActorLocation;
				Centipede::ConstrainAirVelocityToBody(PredictedLocation, Player.OtherPlayer, Centipede::MaxAirPlayerDistance, DeltaTime, PredictedDelta);
				PredictedLocation += PredictedDelta * DeltaTime;

				MoveData.ApplyManualSyncedLocationAndRotation(PredictedLocation, SyncedPosition.WorldVelocity, SyncedPosition.WorldRotation);
			}

			MovementComponent.ApplyMove(MoveData);

			// Rotate mesh on both sides
			FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();

			// Gotta flip when going other way!
			FVector UpVector = MovementComponent.Velocity.GetSafeNormal().CrossProduct(PlayerToOtherPlayer).GetSafeNormal();
			float SignMuliplier = -Math::Sign(UpVector.DotProduct(Player.ViewRotation.ForwardVector));

			FQuat Rotation = FQuat::MakeFromXZ(-PlayerToOtherPlayer, UpVector * SignMuliplier);
			Player.MeshOffsetComponent.LerpToRotation(this, Rotation, 0.2);
		}
	}

	FVector CalculatePlayerInput() const
	{
		// if (CentipedeComponent.IsFullyStretched())
		// {
			FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();

			FVector Binormal = PlayerToOtherPlayer.CrossProduct(MovementComponent.MovementInput).GetSafeNormal();
			Binormal = -PlayerToOtherPlayer.CrossProduct(Binormal);

			FVector PlayerInput = Binormal * 2500.0;
		// }

		return PlayerInput;
	}

	void ConstrainToEventualSwing(FVector& Velocity)
	{
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(Player.OtherPlayer);
		if (OtherPlayerSwingComponent == nullptr)
			return;

		UCentipedeSwingPointComponent SwingPoint = OtherPlayerSwingComponent.GetActiveSwingPoint();
		if (SwingPoint == nullptr)
			return;

		SwingPoint.ConstrainVelocityToSwingPlane(Velocity);
	}
}