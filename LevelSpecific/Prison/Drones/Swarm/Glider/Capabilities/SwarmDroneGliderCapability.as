class USwarmDroneGliderCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmGliderCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneGliderComponent GliderComponent;

	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		GliderComponent = UPlayerSwarmDroneGliderComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GliderComponent.bGliding)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.BlockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);

		SwarmDroneComponent.DroneMesh.SetWorldRotation(Player.ActorRotation);

		// Set up bot
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			// Swap attachment to player drone mesh and use relative space so we can use its rotation for free
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			SwarmBot.ApplyRespawnBlock(this);

			SwarmBot.AttachToComponent(SwarmDroneComponent.DroneMesh);
			SwarmBot.RootComponent.SetbAbsoluteLocation(false);
			SwarmBot.RootComponent.SetbAbsoluteRotation(false);

		}

		// Temp camera shit
		Player.SnapCameraBehindPlayer();
		UCameraSettings::GetSettings(Player).IdealDistance.Apply(400, this, 1, EHazeCameraPriority::Medium);
		UCameraSettings::GetSettings(Player).FOV.Apply(60, this, 1, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);
		Player.UnblockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);

		// Reset bot
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			SwarmBot.AttachToComponent(SwarmDroneComponent.DroneMesh);
			SwarmBot.RootComponent.SetbAbsoluteLocation(true);
			SwarmBot.RootComponent.SetbAbsoluteRotation(true);

			SwarmBot.ClearRespawnBlock(this);
		}

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			FVector Velocity = MovementComponent.Velocity;
			Velocity -= Player.MovementWorldUp * Drone::Gravity * DeltaTime * 0.1;

			FVector Drag = -Velocity * 0.6;
			Drag = Drag.GetClampedToMaxSize(MovementComponent.Velocity.Size());
			Velocity += Drag * DeltaTime;

			MoveData.AddVelocity(Velocity);
			MoveData.SetRotation(Velocity.ToOrientationQuat());

			MovementComponent.ApplyMove(MoveData);

		}

		TickSwarmBots(DeltaTime);
	}

	void TickSwarmBots(float DeltaTime)
	{
		const float Padding = 40;
		float RowCount = Math::IntegerDivisionTrunc(SwarmDrone::DeployedBotCount, 5);
		float Row = -1;

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			float Position = i % RowCount;
			if (Position == 0)
				Row++;

			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			float AdjustedIndex = RowCount * (2 / RowCount);
			float OffsetMultiplier = (RowCount - Row) * 0.2;
			float Offset = Position - AdjustedIndex;
			FVector Location_Y = Player.ActorRightVector * Padding * Offset * OffsetMultiplier;

			FVector Location_X = Player.ActorForwardVector * Padding * Row;
			
			// Add height offset
			float HeightOffset = 10;
			float HeightMultiplier = Math::Pow(-Math::Abs(Position - 2), 1);
			FVector Location_Z = Player.ActorUpVector * HeightOffset * HeightMultiplier;

			FVector Location = Location_X + Location_Y + Location_Z;
			SwarmBot.Root.SetRelativeLocation(Location);

			FVector UpVector = Player.ActorUpVector.RotateAngleAxis(-Offset * 20, Player.ActorForwardVector);
			FQuat Rotation = FQuat::MakeFromXZ(Player.ActorForwardVector, UpVector);
			SwarmBot.Root.SetRelativeRotation(Rotation);

			// Player.DebugDrawCollisionCapsule();
		}
	}
}