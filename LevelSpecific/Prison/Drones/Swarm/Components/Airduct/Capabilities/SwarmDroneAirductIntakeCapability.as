struct FSwarmDroneAirductIntakeCapabilityActivationParams
{
	USwarmDroneAirductComponent AirductComponent = nullptr;
}

struct FSwarmDroneAirductIntakeCapabilityDeactivationParams
{
	bool bReachedAirduct = false;
}

class USwarmDroneAirductIntakeCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);

	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductCapability);
	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductIntakeCapability);

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneAirductComponent PlayerAirductComponent;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FVector Target;
	float InitialDistanceToTarget;

	bool bReachedTarget;

	FVector RandomRotationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerAirductComponent = UPlayerSwarmDroneAirductComponent::Get(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSwarmDroneAirductIntakeCapabilityActivationParams& ActivationParams) const
	{
		if (PlayerAirductComponent.CurrentAirductComponent == nullptr)
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (PlayerAirductComponent.InAirduct())
			return false;

		if (PlayerAirductComponent.WasJustExpelled())
			return false;

		if (Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmTransitionCapability))
			return false;

		ActivationParams.AirductComponent = PlayerAirductComponent.CurrentAirductComponent;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneAirductIntakeCapabilityDeactivationParams& DeactivationParams) const
	{
		if (bReachedTarget)
		{
			DeactivationParams.bReachedAirduct = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSwarmDroneAirductIntakeCapabilityActivationParams ActivationParams)
	{
		bReachedTarget = true;
		PlayerAirductComponent.CurrentAirductComponent = ActivationParams.AirductComponent;

		Target = PlayerAirductComponent.CurrentAirductComponent.GetWorldIntakeLocation();
		InitialDistanceToTarget = Owner.ActorLocation.Distance(Target);

		RandomRotationOffset = Math::GetRandomRotation().Vector();

		PlayerAirductComponent.OnSwarmDroneAirductIntakeInRangeEvent.Broadcast(PlayerAirductComponent.CurrentAirductComponent);

		SwarmDroneComponent.ApplySwarmTransitionBlock(PlayerAirductComponent.CurrentAirductComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FSwarmDroneAirductIntakeCapabilityDeactivationParams DeactivationParams)
	{
		FVector MeshScale = FVector::OneVector;
		if (DeactivationParams.bReachedAirduct)
		{
			PlayerAirductComponent.bInAirduct = true;
			bReachedTarget = false;
			MeshScale = FVector::ZeroVector;
		}
		else
		{
			SwarmDroneComponent.ClearSwarmTransitionBlock(PlayerAirductComponent.CurrentAirductComponent);
			PlayerAirductComponent.CurrentAirductComponent = nullptr;
		}

		Player.GetMeshOffsetComponent().ClearOffset(this);

		// Eman TODO: Make nicer!
		// for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		// 	SwarmDroneComponent.SwarmBots[i].GroupSkelMeshAnimData.Transform.SetScale3D(MeshScale);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (!MovementComponent.Velocity.IsNearlyZero())
		// 	Player.SetMovementFacingDirection(MovementComponent.Velocity.GetUnsafeNormal());

		if (!MovementComponent.PrepareMove(MoveData))
			return;

		FVector DroneToTarget = Target - Owner.ActorLocation;

		if (HasControl())
		{
			// Inherit velocity and add acceleration
			FVector Velocity = MovementComponent.Velocity;

			Velocity = Velocity.RotateTowards(DroneToTarget, MovementComponent.Velocity.Size() * DeltaTime);
			Velocity += DroneToTarget * DeltaTime;
			Velocity = Velocity.GetClampedToSize(2000.0, 12000.0 / Math::Sqrt(DroneToTarget.Size()));

			// Add acceleration
			// float SteerMultiplier = Math::Pow(Math::Clamp(ActiveDuration, 0.5, 2.0), 3.0) * 140.0;
			// Velocity += Owner.ActorForwardVector * SteerMultiplier;

			// // Steer towards target
			// Velocity = Velocity.RotateTowards(DroneToTarget, SteerMultiplier);

			MoveData.AddVelocity(Velocity);

			// Rotate drone
			// MoveData.InterpRotationToTargetFacingRotation(SteerMultiplier);
			MoveData.SetRotation(Velocity.Rotation());
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MovementComponent.ApplyMove(MoveData);

		// Rotate mesh
		Player.GetMeshOffsetComponent().SnapToRotation(this, Player.Mesh.WorldRotation.Quaternion() * FQuat(RandomRotationOffset, DeltaTime * 5.0));

		// Are we there yet?
		if (DroneToTarget.Size() < MovementComponent.CollisionShape.Shape.SphereRadius * 2.0)
			bReachedTarget = true;

		// float TravelFraction = 1.0 - Math::Saturate((DroneToTarget.Size() - MovementComponent.CollisionShape.Shape.SphereRadius) / InitialDistanceToTarget);
		// float MeshScale = Math::Pow(TravelFraction, 3.0);

		// for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		// {
		// 	ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

		// 	auto BotMovementComponent = SwarmBot.MovementComponent;
		// 	FVector BotToTarget = Target - SwarmBot.ActorLocation;

		// 	FVector BotVelocity = BotMovementComponent.Velocity;
		// 	BotVelocity = BotVelocity.RotateTowards(BotToTarget, BotVelocity.Size());
		// 	BotVelocity += BotToTarget.GetSafeNormal() * BotToTarget.Size() * 100.0 * DeltaTime;

		// 	FVector Binormal = BotVelocity.CrossProduct(BotMovementComponent.WorldUp);
		// 	// Debug::DrawDebugDirectionArrow(SwarmBot.ActorLocation, Binormal, 100, 5, FLinearColor::DPink);

		// 	SwarmBot.AddActorWorldOffset(BotVelocity * DeltaTime);
		// 	SwarmBot.SetActorRotation(BotVelocity.Rotation());

		// 	float BotTraveled = Math::Saturate((BotToTarget.Size() - SwarmBot.Collider.SphereRadius) / InitialDistanceToTarget);
		// 	SwarmBot.GroupSkelMeshAnimData.Transform.SetScale3D(FVector(SwarmBot.RetractedScale * BotTraveled));
		// }
	}
}