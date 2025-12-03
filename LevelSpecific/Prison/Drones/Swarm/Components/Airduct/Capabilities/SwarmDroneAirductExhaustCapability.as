struct FSwarmDroneAirductExhaustDeactivationParams
{
	bool bDroneDeswarmified = false;
}

class USwarmDroneAirductExhaustCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);

	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductCapability);
	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductExhaustCapability);

	default TickGroup = EHazeTickGroup::Movement;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneAirductComponent PlayerAirductComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	USwarmDroneAirductComponent AirductComponent;

	FVector RandomRotationOffset;
	FVector InitialVelocity;

	bool bBecameGrounded;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerAirductComponent = UPlayerSwarmDroneAirductComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);

		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerAirductComponent.WasJustExpelled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneAirductExhaustDeactivationParams& DeactivationParams) const
	{
		if (bBecameGrounded)
			return true;

		if (Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirductIntakeCapability))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{


		// Get initial velocity
		InitialVelocity = PlayerAirductComponent.CurrentAirductComponent.GetExhaustLaunchVelocity();
		Player.SetActorVelocity(InitialVelocity);

		PlayerAirductComponent.OnSwarmDroneAirductExpelledEvent.Broadcast(PlayerAirductComponent.CurrentAirductComponent);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);

		RandomRotationOffset = Math::GetRandomRotation().Vector();
		bBecameGrounded = false;
		PlayerAirductComponent.bBeingExpelled = true;
		AirductComponent = PlayerAirductComponent.CurrentAirductComponent;

		PlayerAirductComponent.CurrentAirductComponent = nullptr;

		// Reset transform to OG relative
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
			SwarmDroneComponent.SwarmBots[i].ResetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSwarmDroneAirductExhaustDeactivationParams DeactivationParams)
	{
		PlayerAirductComponent.bWasJustExpelled = false;
		PlayerAirductComponent.bBeingExpelled = false;

		SwarmDroneComponent.ClearSwarmTransitionBlock(AirductComponent);
		AirductComponent = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);

		// If swarm mode is still active we need to go back to absolute transform
		if (SwarmDroneComponent.bSwarmModeActive && !SwarmDroneComponent.bDeswarmifying)
		{
			for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
			{
				ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
				SwarmBot.RootComponent.SetbAbsoluteLocation(true);
				SwarmBot.RootComponent.SetbAbsoluteRotation(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector InheritedVelocity = MovementComponent.Velocity;
		if (!InheritedVelocity.IsNearlyZero())
			Player.SetMovementFacingDirection(InheritedVelocity.GetSafeNormal());

		// Grow little guys
		// Hmmp.. Make nicer!
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			FVector MeshScale = FVector(Math::Saturate(ActiveDuration / 0.1) * SwarmBot.RetractedScale);
			SwarmBot.GroupSkelMeshAnimData.Transform.SetScale3D(MeshScale);
		}

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector VerticalVelocity = MovementComponent.VerticalVelocity;
				FVector HorizontalVelocity = MovementComponent.HorizontalVelocity;

				if (!MovementComponent.MovementInput.IsNearlyZero())
				{
					FVector InputVelocity = MovementComponent.MovementInput * SwarmDroneComponent.MovementSettings.AirAcceleration * DeltaTime;
					HorizontalVelocity = (HorizontalVelocity + InputVelocity).GetClampedToMaxSize(HorizontalVelocity.Size());
				}

				HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(InitialVelocity.ConstrainToPlane(Player.MovementWorldUp).Size());
				MoveData.AddHorizontalVelocity(HorizontalVelocity);
				MoveData.AddVerticalVelocity(VerticalVelocity + -Player.MovementWorldUp * Drone::Gravity * DeltaTime);

				MoveData.InterpRotationToTargetFacingRotation(20.0);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// TODO: Do something nicer
			if (ActiveDuration > 0.2)
				bBecameGrounded = MovementComponent.IsOnAnyGround();

			RotateRootDroneMesh(DeltaTime);
		}

		if (SwarmDroneComponent.bSwarmModeActive && !SwarmDroneComponent.bDeswarmifying)
			MoveSwarm(DeltaTime);

		if (PlayerAirductComponent.bWasJustExpelled)
			PlayerAirductComponent.bWasJustExpelled = false;
	}

	void RotateRootDroneMesh(float DeltaTime)
	{
		FQuat DroneRotation = SwarmDroneComponent.DroneMesh.WorldRotation.Quaternion();
		FQuat RotationDelta = FQuat(RandomRotationOffset, DeltaTime * 2.0);

		SwarmDroneComponent.DroneMesh.SetWorldRotation(RotationDelta * DroneRotation); 
	}

	void MoveSwarm(float DeltaTime)
	{
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			// Add offset from swarm center
			FVector Offset = SwarmBot.ActorUpVector * Math::PerlinNoise1D(Time::GameTimeSeconds + SwarmBot.Id) * 60;

			// Add some twist
			FVector BotToPlayer = SwarmBot.ActorLocation - Player.ActorLocation;
			Offset += BotToPlayer.GetSafeNormal().CrossProduct(Player.ActorRightVector).GetSafeNormal() * 100.0;

			// Add some noise in the velocity vector
			float ForwardMultiplier = SwarmBot.Id - SwarmDrone::DeployedBotCount * 0.8;
			Offset += MovementComponent.Velocity.GetSafeNormal() * ForwardMultiplier * 6.0;

			// Move!
			FVector BotVelocity = SwarmBot.AttachParentActor.ActorVelocity + Offset;
			MoveBot(SwarmBot, BotVelocity);

			SwarmBot.RootComponent.AddRelativeRotation(Offset.Rotation() * DeltaTime);
		}
	}

	// Simple collision handling
	void MoveBot(ASwarmBot SwarmBot, FVector Velocity)
	{
		FVector FrameVelocity = Velocity;

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		Trace.UseSphereShape(SwarmBot.Collider.SphereRadius * 2.0);
		Trace.IgnorePlayers();

		FHitResult HitResult = Trace.QueryTraceSingle(SwarmBot.ActorLocation, SwarmBot.ActorLocation + Velocity * Time::GetActorDeltaSeconds(SwarmBot));
		if (HitResult.bBlockingHit)
			FrameVelocity += HitResult.ImpactNormal * FrameVelocity.ConstrainToDirection(HitResult.ImpactNormal).Size();

		SwarmBot.SetActorLocation(SwarmBot.ActorLocation + FrameVelocity * Time::GetActorDeltaSeconds(SwarmBot));
	}
}