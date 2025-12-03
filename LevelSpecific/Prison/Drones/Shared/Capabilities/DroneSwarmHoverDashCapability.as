class UDroneSwarmHoverDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmHoverDashCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 120;

	UPlayerSwarmDroneComponent SwarmDroneComponent;

	const float DashForce = 2000;
	const float DashDuration = 0.8;

	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FVector DashDirection;

	const float HoverBlockDuration = 0.5;
	bool bHoverBlocked;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;

		// if (!SwarmDroneComponent.bSwarmModeActive)
		// 	return false;

		// if (!SwarmDroneComponent.bHovering)
		// 	return false;

		// if (!WasActionStarted(ActionNames::MovementDash))
		// 	return false;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmDroneComponent.bSwarmModeActive)
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (SwarmDroneComponent.bHovering)
			return true;

		if (MovementComponent.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmHoverCapability, this);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);

		bHoverBlocked = true;
		DashDirection = MovementComponent.MovementInput.IsNearlyZero(0.1) ? Player.ActorForwardVector : MovementComponent.MovementInput;

		SwarmDroneComponent.bHoverDashing = true;

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
			SwarmDroneComponent.SwarmBots[i].ApplyRespawnBlock(this);
		
		auto CameraSettings = UCameraSettings::GetSettings(Player);
		CameraSettings.FOV.Apply(Player.ViewFOV - 20, this, 0.3, EHazeCameraPriority::Low);
		CameraSettings.IdealDistance.Apply(800, this, 0.3, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
		if (bHoverBlocked)
			Player.UnblockCapabilities(SwarmDroneTags::SwarmHoverCapability, this);

		SwarmDroneComponent.bHoverDashing = false;

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
			SwarmDroneComponent.SwarmBots[i].ClearRespawnBlock(this);

		Player.ClearCameraSettingsByInstigator(this, 2);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Player.DebugDrawCollisionCapsule();	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bHoverBlocked && ActiveDuration >= HoverBlockDuration)
		{
			Player.UnblockCapabilities(SwarmDroneTags::SwarmHoverCapability, this);
			bHoverBlocked = false;
		}

		if (MovementComponent.PrepareMove(MoveData))
		{
			float DashFraction = Math::Saturate(ActiveDuration / DashDuration);
			float ForceMultiplier = Math::Pow(1 - DashFraction, 2);

			FVector Velocity = MovementComponent.Velocity;

			if (!MovementComponent.MovementInput.IsNearlyZero(0.1))
				DashDirection = DashDirection.RotateTowards(MovementComponent.MovementInput, DeltaTime * 300);

			// Add dash force
			Velocity = DashDirection * 1000 * ForceMultiplier;

			// Accumulate gravity after a bit
			if (ActiveDuration > 0.3)
				Velocity += MovementComponent.VerticalVelocity - Player.MovementWorldUp * Drone::Gravity * DeltaTime;

			// Add input
			Velocity += DashDirection * SwarmDrone::Movement::Speed * MovementComponent.MovementInput.Size() * 0.75;

			MoveData.AddVelocity(Velocity);
			if (!Velocity.IsNearlyZero(5))
				MoveData.SetRotation(Velocity.Rotation());

			MovementComponent.ApplyMove(MoveData);
		}

		TickSwarmBots(DeltaTime);
	}

	// TEMP MOVE
	void TickSwarmBots(float DeltaTime)
	{
		float Padding = 30;
		int Count = 14;
		int LineSize = Math::IntegerDivisionTrunc(Count, 2);
		FVector LineDirection = Player.ActorUpVector;

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			if (i < Count && ActiveDuration <= 0.5)
			{
				int PositionInLine = i % LineSize;
				if (PositionInLine == 0)
					LineDirection = LineDirection.RotateAngleAxis(90, DashDirection);

				// Place beind player
				FVector Location = Player.ActorLocation + LineDirection * Padding * (PositionInLine - 3);
				Location -= Player.ActorForwardVector * 100;


				float PositionMultipier = Math::Abs(PositionInLine - 3);
				float SkewExp = Math::Lerp(1, 4, Math::Saturate(ActiveDuration / 0.5));
				FVector Skew = (Player.ActorLocation - SwarmBot.ActorLocation).GetSafeNormal().CrossProduct(DashDirection).GetSafeNormal() * Math::Pow(PositionMultipier, SkewExp);
				// Debug::DrawDebugDirectionArrow(Location, Skew, 100);

				Location = Location + Skew;

				// Debug::DrawDebugSphere(Location, 5, 6, FLinearColor::MakeFromHex(3222) * PositionMultipier * PositionMultipier * PositionMultipier);

				FVector LerpLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, Location, DeltaTime, 1000);
				SwarmBot.SetActorLocation(LerpLocation);
			}
			else
			{
				// Bring closer for a short while
				if (ActiveDuration < 0.2)
				{
					FVector TargetLocation = SwarmBot.GetInitialWorldTransformOnMesh().Location;
					FVector LerpLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetLocation, DeltaTime, 400);
					SwarmBot.SetActorLocation(LerpLocation);
				}

				// Add offset from swarm center
				FVector Offset = SwarmBot.ActorUpVector * Math::PerlinNoise1D(Time::GameTimeSeconds + SwarmBot.Id) * 60;

				// Add some twist
				FVector BotToPlayer = SwarmBot.ActorLocation - Player.ActorLocation;
				Offset += BotToPlayer.GetSafeNormal().CrossProduct(Player.ActorRightVector).GetSafeNormal() * 200.0;

				// Add some noise in the velocity vector
				float ForwardMultiplier = SwarmBot.Id - SwarmDrone::DeployedBotCount * 0.8;
				Offset += MovementComponent.Velocity.GetSafeNormal() * ForwardMultiplier * 6.0;

				// Move!
				FVector BotVelocity = MovementComponent.Velocity + Offset;
				MoveBot(SwarmBot, BotVelocity);

				SwarmBot.RootComponent.AddRelativeRotation(Offset.Rotation() * DeltaTime);
			}
		}
	}

	// TEMP MOVE
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