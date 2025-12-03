struct FSwarmBotDashData
{
	// Fraction
	// float CloseToCore;

	float Bias;
}

struct FSwarmDroneDashCapabilityDeactivationParams
{
	bool bInterruptedByDash = false;
}

class USwarmDroneDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DroneCommonTags::DroneDashCapability);

	// Tick immediately after drone dash
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 101;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerMovementComponent MovementComponent;
	UDroneMovementSettings Settings;

	TArray<FSwarmBotDashData> DashData;

	bool bReconstituted = false;
	bool bInterruptedByDash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		Settings = UDroneMovementSettings::GetSettings(Player);

		// Create structs
		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
			DashData.Add(FSwarmBotDashData());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Check for last frame too, otherwise we can activate double-dash but get interrupted and everything is fuck
		if (!SwarmDroneComponent.IsDashing() && !SwarmDroneComponent.WasDashingLastFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneDashCapabilityDeactivationParams& DeactivationParams) const
	{
		if (SwarmDroneComponent.bJumping)
			return true;

		if (ActiveDuration > Settings.DashDuration)
		{
			if (!bReconstituted && SwarmDroneComponent.IsDashing())
			{
				DeactivationParams.bInterruptedByDash = true;
				return true;
			}
		}

		if (bReconstituted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReconstituted = false;
		SwarmDroneComponent.bSwarmDashing = true;
		USwarmDroneEventHandler::Trigger_OnSwarmDash(Player);

		for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
		{
			FSwarmBotDashData& BotData = DashData[SwarmBot.Id];

			// How close bot is to core
			// BotData.CloseToCore = Math::Saturate((Math::Abs(SwarmBot.ActorRelativeLocation.Z) / (SwarmDroneComponent.DroneMeshRadius)));
			// BotData.CloseToCore = Math::Pow(1.0 - BotData.CloseToCore, 2) + 1.0;

			// Bots aiming backwards take priority
			BotData.Bias = Math::Max(0.1, Math::Pow(1.0 - Player.ActorForwardVector.DotProduct(SwarmBot.ActorUpVector), 2));

			// Bring closer if we are chaining dash
			if (bInterruptedByDash)
			{
				BotData.Bias = Math::Max(0.7, BotData.Bias);
			}

			// Bring bot to world movement; don't do shit if we come from previous dash
			if (!bInterruptedByDash)
			{
				FTransform WorldTransform = SwarmBot.ActorTransform;
				SwarmBot.Root.SetbAbsoluteLocation(true);
				SwarmBot.Root.SetbAbsoluteRotation(true);
				SwarmBot.SetActorTransform(WorldTransform);
			}
		}

		// Yeah FUCK that
		SwarmDroneComponent.ApplySwarmTransitionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FSwarmDroneDashCapabilityDeactivationParams DeactivationParams)
	{
		SwarmDroneComponent.bSwarmDashing = false;

		// Don't reset transform if player is dashing again
		bInterruptedByDash = DeactivationParams.bInterruptedByDash;
		if (!bInterruptedByDash && !SwarmDroneComponent.bJumping)
		{
			for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				SwarmBot.Root.SetbAbsoluteLocation(false);
				SwarmBot.Root.SetbAbsoluteRotation(false);

				SwarmBot.ResetRelativeTransform();
			}
		}

		SwarmDroneComponent.ClearSwarmTransitionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Dashing
		if (ActiveDuration < Settings.DashDuration)
		{
			for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				FSwarmBotDashData& BotData = DashData[SwarmBot.Id];

				// Transform relative target to world
				FVector TargetLocation = SwarmDroneComponent.GetDroneMeshComponent().WorldTransform.TransformPositionNoScale(SwarmBot.InitialTransformOnMesh.Location);

				FVector MoveDelta = TargetLocation - SwarmBot.ActorLocation;
				SwarmBot.SetActorLocation(SwarmBot.ActorLocation + (MoveDelta * BotData.Bias * 0.3) + MovementComponent.GetFollowVelocity() * DeltaTime);

				FQuat TargetRotation = FQuat::MakeFromX(MoveDelta.GetSafeNormal());
				FQuat Rotation = Math::QInterpConstantTo(SwarmBot.ActorQuat, TargetRotation, DeltaTime, 10);
				SwarmBot.SetActorRotation(Rotation);
			}
		}
		else
		{
			float ActiveReconstitutionDuration = ActiveDuration - Settings.DashDuration;
			float ReconstitutionFraction = ActiveReconstitutionDuration / (Settings.DashCooldown * 2);

			if (ReconstitutionFraction >= 1.)
			{
				bReconstituted = true;
				return;
			}

			for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				// Interpolate towards place in ball
				FVector RelativeLocation = SwarmBot.InitialTransformOnMesh.Location;
				FVector TargetWorldLocation = SwarmDroneComponent.DroneMesh.WorldTransform.TransformPositionNoScale(RelativeLocation);
				FVector WorldLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetWorldLocation, DeltaTime, ReconstitutionFraction * 1000.0) + MovementComponent.Velocity * DeltaTime + MovementComponent.GetFollowVelocity() * DeltaTime;
				SwarmBot.SetActorLocation(WorldLocation);

				// Lerp local rotation of little cutie
				FQuat TargetRotation = SwarmDroneComponent.DroneMesh.WorldTransform.TransformRotation(SwarmBot.InitialTransformOnMesh.Rotation);
				FQuat Rotation = Math::QInterpConstantTo(SwarmBot.ActorRotation.Quaternion(), TargetRotation, DeltaTime, 20);
				SwarmBot.SetActorRotation(Rotation);
			}
		}
	}
}