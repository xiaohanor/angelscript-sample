struct FSwarmDroneTransitionCapabilityParams
{
	bool bSwarmModeActiveBeforeTransition = false;
}

class UDroneSwarmTransitionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmTransitionCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;

	const float DeswarmTransitionDuration = 0.5;

	// Swarmifying should last just a fraction of deswarmify
	const float SwarmifyDurationMultiplier = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);

		UPlayerHealthComponent::Get(Player).OnReviveTriggered.AddUFunction(this, n"OnPlayerRevive");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSwarmDroneTransitionCapabilityParams& ActivationParams) const
	{
		if (Player.IsPlayerDead())
			return false;

		if (Player.IsPlayerRespawning())
			return false;

		if (SwarmDroneComponent.bSwarmModeActive)
		{
			// Don't deactivate if still in boat-mode
			if (SwarmBoatComponent.IsBoatActive())
				return false;

			// Forced deactivation overrides everything else
			if (SwarmDroneComponent.bShouldDeactivateSwarmMode)
			{
				ActivationParams.bSwarmModeActiveBeforeTransition = SwarmDroneComponent.bSwarmModeActive;
				return true;
			}

			if (IsActioning(ActionNames::PrimaryLevelAbility))
				return false;
		}
		else
		{
			if (SwarmDroneHijackComponent.IsHijackActive())
				return true;

			// Transition automatically if on boat zone (FloatZone)
			if (SwarmBoatComponent.IsBoatActive())
				return true;

			if (!IsActioning(ActionNames::PrimaryLevelAbility))
				return false;

			// Don't transition automatically when in special zones
		// 	if (SwarmDroneComponent.IsInsideHoverZone() && SwarmDroneComponent.bJumping)
		// 		return true;
		}

		if (SwarmDroneComponent.IsSwarmTransitionBlocked())
			return false;

		if (SwarmDroneHijackComponent.IsHijackActive())
			return false;

		ActivationParams.bSwarmModeActiveBeforeTransition = SwarmDroneComponent.bSwarmModeActive;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneTransitionCapabilityParams& DeactivationParams) const
	{
		const float DurationCheck = SwarmDroneComponent.bDeswarmifying ? DeswarmTransitionDuration : DeswarmTransitionDuration * SwarmifyDurationMultiplier;
		if (ActiveDuration >= DurationCheck)
		{
			DeactivationParams.bSwarmModeActiveBeforeTransition = SwarmDroneComponent.bSwarmModeActive;
			return true;
		}

		// Deactivate immediately if starting a hack
		if (SwarmDroneHijackComponent.IsHijackActive() && SwarmDroneComponent.bDeswarmifying)
		{
			DeactivationParams.bSwarmModeActiveBeforeTransition = true;
			return true;
		}

		if (Player.IsPlayerDead())
		{
			DeactivationParams.bSwarmModeActiveBeforeTransition = SwarmDroneComponent.bSwarmModeActive;
			return true;
		}

		if (Player.IsPlayerRespawning())
		{
			DeactivationParams.bSwarmModeActiveBeforeTransition = SwarmDroneComponent.bSwarmModeActive;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSwarmDroneTransitionCapabilityParams ActivationParams)
	{
		SwarmDroneComponent.bSwarmModeActive = ActivationParams.bSwarmModeActiveBeforeTransition;

		if (SwarmDroneComponent.bSwarmModeActive)
		{
			SwarmDroneComponent.bDeswarmifying = true;

			// Stand-up to align deswarmification
			SwarmDroneComponent.DroneMesh.SetWorldRotation(FRotator(0, 0, -90));

			// Deactivate swarm camera
			Player.ClearCameraSettingsByInstigator(this);

			// Consume override
			SwarmDroneComponent.bShouldDeactivateSwarmMode = false;
		}
		else
		{
			// Activate swarm camera
			UCameraSettings::GetSettings(Player).IdealDistance.Apply(600, this, 2, EHazeCameraPriority::Low);
		}
	
		if(SwarmDroneComponent.bDeswarmifying)
		{
			USwarmDroneEventHandler::Trigger_OnTransformToBall(Player);
			USwarmDroneEventHandler::Trigger_StopSwarmBotMovement(Player);
		}
		else
		{
			if(!SwarmDroneComponent.IsInsideHoverZone() && !SwarmDroneHijackComponent.IsHijackActive())
				USwarmDroneEventHandler::Trigger_OnTransformToSwarm(Player);
		}

		// Safe to always stop swarm drone movement, it will possibly restart on deactivate
		USwarmDroneEventHandler::Trigger_StopSwarmDroneMovement(Player);
		
		SwarmDroneComponent.bSwarmTransitionActive = true;
		SwarmDroneComponent.OnSwarmTransitionStartEvent.Broadcast(!SwarmDroneComponent.bDeswarmifying);

		Player.BlockCapabilities(SwarmDroneTags::SwarmDroneActionMovement, this);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSwarmDroneTransitionCapabilityParams DeactivationParams)
	{
		SwarmDroneComponent.bSwarmModeActive = !DeactivationParams.bSwarmModeActiveBeforeTransition;

		if (SwarmDroneComponent.bSwarmModeActive)
		{
			if(!SwarmDroneHijackComponent.IsHijackActive())
				USwarmDroneEventHandler::Trigger_StartSwarmBotMovement(Player);
		}
		else
		{
			USwarmDroneEventHandler::Trigger_StartSwarmDroneMovement(Player);
			SwarmDroneComponent.bDeswarmifying = false;
		}

		SwarmDroneComponent.bSwarmTransitionActive = false;

		// Don't teleport bots if we interrupted for hack
		if (!SwarmDroneHijackComponent.IsHijackActive())
			SwarmDroneComponent.OnSwarmTransitionCompleteEvent.Broadcast(SwarmDroneComponent.bSwarmModeActive);

		Player.UnblockCapabilities(SwarmDroneTags::SwarmDroneActionMovement, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Swarm is being dismissed
		if (SwarmDroneComponent.bSwarmModeActive)
		{
			float Alpha = Math::Saturate(ActiveDuration / DeswarmTransitionDuration);

			for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				// Interpolate towards place in ball
				FVector RelativeLocation = SwarmBot.GetSwarmBotRelativeLocationOnDroneMeshWithFraction(Alpha);
				FVector TargetWorldLocation = SwarmDroneComponent.DroneMesh.WorldTransform.TransformPositionNoScale(RelativeLocation);
				FVector WorldLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetWorldLocation, DeltaTime, Alpha * 2500.0) + MovementComponent.Velocity * DeltaTime;
				SwarmBot.SetActorLocation(WorldLocation);

				// Lerp local rotation of little cutie
				FQuat TargetRotation = SwarmBot.PlayerSwarmDroneComponent.DroneMesh.WorldTransform.TransformRotation(SwarmBot.InitialTransformOnMesh.Rotation);
				FQuat Rotation = Math::QInterpConstantTo(SwarmBot.ActorRotation.Quaternion(), TargetRotation, DeltaTime, 10);
				SwarmBot.SetActorRotation(Rotation);

				// Scale up phony bots to smooth-in transition
				if (SwarmBot.Id >= SwarmDrone::DeployedBotCount)
				{
					FVector Scale = FVector(Alpha * Alpha * SwarmBot.RetractedScale);
					SwarmBot.GroupSkelMeshAnimData.Transform.SetScale3D(Scale);
				}
			}
		}
		// Swarm is being summoned
		else
		{
			const float Alpha = Math::Saturate(ActiveDuration / (DeswarmTransitionDuration * SwarmifyDurationMultiplier));

			// Add a little push upwards
			if (SwarmDroneComponent.MoveComp.IsOnAnyGround())
			{
				float Magnitude = 5000.0 * DeltaTime * Math::Square(1.0 - Alpha);

				for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
				{
					ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
					FVector Acceleration = (SwarmBot.ActorUpVector.ConstrainToCone(Player.MovementWorldUp, PI * 0.5) * 0.5 + Player.MovementWorldUp) * Magnitude;
					SwarmBot.MovementComponent.Velocity += Acceleration;

					// Grow collider radius to avoid initial overlaps
					float ColliderRadius = Math::Max(1.0, SwarmBot.OGColliderRadius * Alpha);
					SwarmBot.SetColliderRadius(ColliderRadius);
				}
			}
		}
	}

	// Clear all swarmification
	UFUNCTION()
	private void OnPlayerRevive()
	{
		SwarmDroneComponent.bDeswarmifying = false;
		SwarmDroneComponent.bSwarmModeActive = false;

		for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			SwarmBot.SetSwarmActive(false);

		// Deactivate swarm camera
		Player.ClearCameraSettingsByInstigator(this);
	}
}