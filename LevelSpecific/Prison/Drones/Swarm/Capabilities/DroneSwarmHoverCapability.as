class UDroneSwarmHoverCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmHoverCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;

	default DebugCategory = Drone::DebugCategory;

	UPlayerMovementComponent MovementComponent;
	USwarmDroneHoverMovementData MoveData;

	UPlayerSwarmDroneComponent SwarmDroneComponent;

	FHazeAcceleratedQuat AcceleratedLeadBotRotation;
	FHazeAcceleratedVector AcceleratedInput;
	FHazeAcceleratedVector AcceleratedPlayerForward;

	const float ParachuteDeployDuration = 0.2;

	// Temp expensive shit to get juice feel
	TArray<UHazeTEMPCableComponent> ParachuteCables;

	// Hmmm feels weird...
	const float HorizontalDecelerationDuration = 2.0;
	FVector ZoneImpulse = FVector::ZeroVector;
	float ZoneImpulseTimer;

	ADroneSwarmMoveZone PreviousHoverZone = nullptr;
	float InitialVerticalDistanceToPeak;

	// How long has player been inside hover zone
	float DurationInZone;

	bool bWasInsideZone;

	UCameraShakeBase DraftCameraShake = nullptr;
	UCameraShakeBase RegularAssMovementCameraShake = nullptr;

	const float RegularVerticalBotOffsetExp = 2.0;
	const float DraftyVerticalBotOffsetExp = 2.1;

	float VerticalBotOffsetExp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupMovementData(USwarmDroneHoverMovementData);
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);

		const float Count = 4;
		for (int i = 0; i < Count; i++)
		{
			UHazeTEMPCableComponent Cable = USwarmDroneParachuteCableComponent::GetOrCreate(Player, FName("SwarmDroneHoverParachuteCable" + i));

			if (SwarmDroneComponent.ParachuteInfo.RopeMaterial != nullptr)
				Cable.SetMaterial(0, SwarmDroneComponent.ParachuteInfo.RopeMaterial);

			ParachuteCables.Add(Cable);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (SwarmDroneComponent.bDeswarmifying)
			return false;

		if (!SwarmDroneComponent.IsInsideHoverZone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return true;

		if (SwarmDroneComponent.bDeswarmifying)
			return true;

		if (SwarmDroneComponent.bHoverDashing)
			return true;

		if (MovementComponent.HasGroundContact() && !SwarmDroneComponent.IsInsideHoverZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwarmDroneComponent.bHovering = true;

		AcceleratedLeadBotRotation.SnapTo(Player.ActorQuat);
		AcceleratedPlayerForward.SnapTo(Player.ActorForwardVector);
		AcceleratedInput.SnapTo(FVector::ZeroVector);

		VerticalBotOffsetExp = RegularVerticalBotOffsetExp;

		// SwarmDroneComponent.ApplySwarmTransitionBlock(this);

		bWasInsideZone = false;
		ZoneImpulse = FVector::ZeroVector;

		Player.BlockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);

		// Temp cable comps
		for (auto Cable : ParachuteCables)
		{
			Cable.SetHiddenInGame(false);
			Cable.SetComponentTickEnabled(true);

			Cable.TeleportCable(Player.ActorLocation);
		}

		SpeedEffect::RequestSpeedEffect(Player, 0.1, this, EInstigatePriority::Normal, 0.3, false);

		UPlayerSwarmDroneHoverEventHandler::Trigger_OnHoverStart(Player);

		// Audio uses other event handler
		USwarmDroneEventHandler::Trigger_OnStartSwarmHover(Player);

		PreviousHoverZone = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwarmDroneComponent.bHovering = false;

		// SwarmDroneComponent.ClearSwarmTransitionBlock(this);

		Player.UnblockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);

		// Temp cable comps
		for (auto Cable : ParachuteCables)
		{
			Cable.SetComponentTickEnabled(false);
			Cable.SetHiddenInGame(true);

			Cable.ResetParticleForces();
			Cable.ResetParticleVelocities();
			Cable.ResetRelativeTransform();

			Cable.SetScalarParameterValueOnMaterials(n"DitherFade", 0);
		}

		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this, false);
		RegularAssMovementCameraShake = nullptr;
		DraftCameraShake = nullptr;

		if (bWasInsideZone)
		{
			UPlayerSwarmDroneHoverEventHandler::Trigger_OnHoverStop(Player);
		}
		
		// Audio uses other event handler
		USwarmDroneEventHandler::Trigger_OnStopSwarmHover(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedInput.AccelerateTo(MovementComponent.MovementInput, 2, DeltaTime);

		if (!MovementComponent.Velocity.IsNearlyZero(5))
			Player.SetMovementFacingDirection(MovementComponent.Velocity.GetSafeNormal());

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector Velocity = MovementComponent.Velocity;
				Velocity += AcceleratedInput.Value * SwarmDrone::Movement::Speed;

				// Get smooth acceleration when hopping in
				float ZoneEaseInFraction = Math::Square(Math::Saturate(DurationInZone / 0.2));

				// Start accelerating slightly before 'parachute' has been fully deployed
				if (ActiveDuration >= ParachuteDeployDuration * 0.7)
				{
					if (SwarmDroneComponent.IsInsideHoverZone())
					{
						// Handle eye candy
						if (!bWasInsideZone)
							Crumb_EnteredDraft();

						bWasInsideZone = true;
						ZoneImpulse = FVector::ZeroVector;
						ZoneImpulseTimer = HorizontalDecelerationDuration;

						for (ADroneSwarmMoveZone MoveZone : SwarmDroneComponent.ActiveSwarmMoveZones)
						{
							if (!MoveZone.IsA(ADroneSwarmHoverZone))
								continue;

							if(MoveZone != PreviousHoverZone)
								USwarmDroneHoverZoneEventHandler::Trigger_SwarmDroneHoveringStart(MoveZone);

							FVector PlayerToPeak = (MoveZone.GetZonePeak() - Player.ActorLocation).ConstrainToDirection(MoveZone.ActorUpVector);
							InitialVerticalDistanceToPeak = PlayerToPeak.Size();

							PreviousHoverZone = MoveZone;

							// Add hover impulse
							ZoneImpulse += MoveZone.CalculateAccelerationAtLocation(Player.ActorLocation) * ZoneEaseInFraction;

							// Add vertical drag
							float DragIndex = MoveZone.GetMoveFractionAtLocation(Player.ActorLocation);
							FVector MoveZoneDrag = -MovementComponent.VerticalVelocity * DragIndex;
									MoveZoneDrag = MoveZoneDrag.GetClampedToMaxSize(MovementComponent.Velocity.Size());

							ZoneImpulse += MoveZoneDrag * ZoneEaseInFraction;
						}

						Velocity += ZoneImpulse;
						DurationInZone += DeltaTime;

						// Force feedback juice
						FHazeFrameForceFeedback FF;
						FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(ActiveDuration)) * 0.1;
						FF.RightMotor = Math::Abs(Math::PerlinNoise1D(ActiveDuration * 3.26)) * 0.2;
						FF.RightTrigger = 0.1 + Math::Abs(Math::PerlinNoise1D(ActiveDuration * 6.37)) * 0.7;
						Player.SetFrameForceFeedback(FF, 0.6);
					}
					else
					{
						DurationInZone = 0;

						// Inherit last zone's horizontal impulse for a couple of secs
						if (ZoneImpulseTimer > 0.0)
						{
							float ImpulseFraction = Math::Saturate(ZoneImpulseTimer / HorizontalDecelerationDuration);
							float ZoneImpulseMultiplier = Math::Saturate(((ImpulseFraction - 0.1) / ImpulseFraction) * 1.1);
							FVector HorizontalZoneImpulse = ZoneImpulse.ConstrainToPlane(Player.MovementWorldUp);
							Velocity += HorizontalZoneImpulse * ZoneImpulseMultiplier;

							// Do vertical too and add drag
							if (PreviousHoverZone != nullptr)
							{
								FVector PlayerToPeak = (PreviousHoverZone.GetZonePeak() - Player.ActorLocation).ConstrainToDirection(PreviousHoverZone.ActorUpVector);
								FVector VerticalVelocity = PlayerToPeak.GetSafeNormal() * InitialVerticalDistanceToPeak;
								VerticalVelocity -= VerticalVelocity * PreviousHoverZone.GetMoveFractionAtLocation(Player.ActorLocation);
								VerticalVelocity = VerticalVelocity.GetClampedToMaxSize(MovementComponent.Velocity.Size());

								// Only apply if velocity is pointing upwards
								if (VerticalVelocity.DotProduct(Player.MovementWorldUp) > 0)
									Velocity += VerticalVelocity * DeltaTime;
							}

							ZoneImpulseTimer -= DeltaTime;
						}

						// Revert to regular eye candy
						if (bWasInsideZone)
						{
							Crumb_ExitedDraft();
							bWasInsideZone = false;
						}

						// Force feedback juice
						FHazeFrameForceFeedback FF;
						FF.RightMotor = Math::Abs(Math::PerlinNoise1D(ActiveDuration * 6.26)) * 0.1;
						FF.RightTrigger = 0.05 + Math::Abs(Math::PerlinNoise1D(ActiveDuration * 2)) * 0.1;
						Player.SetFrameForceFeedback(FF, 0.4);
					}

					VerticalBotOffsetExp = Math::FInterpTo(VerticalBotOffsetExp, RegularVerticalBotOffsetExp, DeltaTime, 5);
				}

				// Add drag
				FVector Drag = -MovementComponent.HorizontalVelocity * SwarmDrone::Movement::DragAirborne;
						Drag += -MovementComponent.VerticalVelocity * DeltaTime;
						Drag = Drag.GetClampedToMaxSize(MovementComponent.Velocity.Size());

				Velocity += Drag;

				// Add toned down gravity
				Velocity += -MovementComponent.WorldUp * Drone::Gravity * SwarmDrone::Movement::HoverGravityMultiplier * DeltaTime;

				MoveData.AddVelocity(Velocity);
				MoveData.InterpRotationToTargetFacingRotation(3);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Handle mesh movement
			TickSwarmBots(DeltaTime);

			// Handle cable transparency
			TickCableComponents(DeltaTime);
		}
	}

	// Make a nice star parachuty formation
	void TickSwarmBots(float DeltaTime)
	{
		float DeployFraction = Math::Saturate(ActiveDuration / ParachuteDeployDuration);

		if (!MovementComponent.MovementInput.IsNearlyZero())
			AcceleratedLeadBotRotation.AccelerateTo(FQuat::MakeFromX(MovementComponent.MovementInput), 1.0, DeltaTime);

		AcceleratedPlayerForward.AccelerateTo(Player.ActorForwardVector, 1.5, DeltaTime);
		AcceleratedPlayerForward.SnapTo(AcceleratedPlayerForward.Value.GetSafeNormal());

		// First swarm will represent player's true position
		ASwarmBot LeadSwarmBot = SwarmDroneComponent.SwarmBots[0];
		LeadSwarmBot.SetActorLocation(Math::VInterpConstantTo(LeadSwarmBot.ActorLocation, Player.ActorLocation, DeltaTime, 3000 ));
		LeadSwarmBot.SetActorRotation(AcceleratedLeadBotRotation.Value);

		const float Padding = 30;
		const int LineCount = 4;
		const int LineSize = Math::IntegerDivisionTrunc((SwarmDrone::DeployedBotCount - 1), LineCount);
		const float AngleIncrement = 180.0 / LineCount;

		int Line = -1;

		float Angle = -AngleIncrement;

		for (int i = 1; i < SwarmDrone::DeployedBotCount; i++)
		{
			const int PositionInLine = (i - 1) % LineSize;
			if (PositionInLine == 0)
				Angle += AngleIncrement;

			// Blergh, easy to just access directly
			if (i == 1 || i == 6 || i == 18 || i == 13)
			{
				Line += 1;
				if (Line < ParachuteCables.Num())
				{
					auto& Cable = ParachuteCables[Line];
					Cable.EndLocation = Player.ActorTransform.InverseTransformPositionNoScale(SwarmDroneComponent.SwarmBots[i].ActorLocation);				
				}
			}

			// Get position in line and offset horizontally
			FVector LineDirection = AcceleratedPlayerForward.Value.RotateAngleAxis(Angle, Player.MovementWorldUp);
			FVector Location = Player.ActorLocation + LineDirection * Padding * (PositionInLine - 2.5);

			// Add some vertical flavour
			FVector HeightOffset = Player.MovementWorldUp * 150 - Player.MovementWorldUp * Math::Pow(4, VerticalBotOffsetExp) * Math::Abs(PositionInLine - 2.5);
			Location += HeightOffset;

			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			const float LerpSpeed = (SwarmBot.ActorLocation.Distance(Location) / ParachuteDeployDuration) * DeployFraction * 5;
			FVector SwarmBotLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, Location, DeltaTime, LerpSpeed);

			// Add a little bit of wavey juice
			float ShakeMultiplier = SwarmDroneComponent.IsInsideHoverZone() ? 0.3 : 0.1;
			FVector ShakeOffset =  (Player.ActorLocation - Location) * Math::Sin(ActiveDuration * (i + 30)) * DeltaTime * ShakeMultiplier;
			SwarmBotLocation += ShakeOffset;

			SwarmBot.SetActorLocation(SwarmBotLocation);

			// Rotate them to make it look like parachute; inside guys get special treatment
			FQuat Rotation = FQuat((Player.ActorLocation - Location).CrossProduct(Player.MovementWorldUp), Math::DegreesToRadians(2)) * (Player.ActorLocation - Location).ToOrientationQuat();
			if (PositionInLine == 2 || PositionInLine == 3)
			{
				Rotation *= FQuat(FVector::RightVector, 2);
			}

			SwarmBot.SetActorRotation(Rotation);
		}
	}

	void TickCableComponents(float DeltaTime)
	{
		float Opacity = Math::Saturate(0.3 + ActiveDuration / ParachuteDeployDuration);

		for (auto Cable : ParachuteCables)
			Cable.SetScalarParameterValueOnMaterials(n"DitherFade", Opacity);
	}
	
	UFUNCTION(CrumbFunction)
	void Crumb_EnteredDraft()
	{
		Player.StopCameraShakeByInstigator(this);
		RegularAssMovementCameraShake = nullptr;

		USwarmDroneEventHandler::Trigger_OnParachuteCatchWind(Player);
		DraftCameraShake = Player.PlayCameraShake(SwarmDroneComponent.ParachuteInfo.DraftCameraShake, this, 0.6);

		// Agitate those bots!
		VerticalBotOffsetExp = DraftyVerticalBotOffsetExp;

		// Add some camera juice god damn 
		//pich had some issues when looking staight down will take a look at this
		
		// FHazeCameraImpulse CameraImpulse;
		// CameraImpulse.AngularImpulse = FRotator(-25, 0, 0);
		// CameraImpulse.CameraSpaceImpulse = FVector::UpVector * 100;
		// CameraImpulse.Dampening = 0.5;
		// CameraImpulse.ExpirationForce = 50;
		// Player.ApplyCameraImpulse(CameraImpulse, this);
	}

	UFUNCTION(CrumbFunction)
	void Crumb_ExitedDraft()
	{
		UPlayerSwarmDroneHoverEventHandler::Trigger_OnHoverStop(Player);

		Player.StopCameraShakeByInstigator(this);
		DraftCameraShake = nullptr;

		RegularAssMovementCameraShake = Player.PlayCameraShake(SwarmDroneComponent.ParachuteInfo.MovementCameraShake, this, 0.3);
	}
}

class USwarmDroneHoverMovementData : USteppingMovementData
{
	default DefaultResolverType = USwarmDroneHoverMovementResolver;
}

class USwarmDroneHoverMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = USwarmDroneHoverMovementData;

	// Don't end up with more vertical velocity than when we started
	FMovementDelta ProjectMovementUponImpact(FMovementResolverState& State, FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const override
	{
		FMovementDelta MovementDelta = Super::ProjectMovementUponImpact(State, DeltaState, DeltaStateType, Impact, GroundedState);

		// Lazy but mäh, we are not messing around with world up here
		MovementDelta.Delta.Z = Math::Min(MovementDelta.Delta.Z, DeltaState.Delta.Z);
		MovementDelta.Velocity.Z = Math::Min(MovementDelta.Velocity.Z, DeltaState.Velocity.Z);

		return MovementDelta;
	}
}