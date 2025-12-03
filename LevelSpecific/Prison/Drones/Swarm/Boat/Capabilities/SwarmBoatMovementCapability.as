class USwarmBoatMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::BoatMovementCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 95;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;
	USimpleMovementData MoveData;

	USwarmBoatSettings Settings;

	FHazeAcceleratedFloat AcceleratedTilt;
	FHazeAcceleratedFloat AcceleratedFov;

	UHazeCrumbSyncedFloatComponent CrumbedInputSize;

	bool bHadWallImpact = false;

	const float BlendInDuration = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSimpleMovementData();

		CrumbedInputSize = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"SwarmBoatMovementCrumbedInputSize");

		Settings = USwarmBoatSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return false;

		if (!SwarmDroneComponent.IsInsideFloatZone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return true;

		if (!SwarmDroneComponent.IsInsideFloatZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwarmDroneComponent.bFloating = true;

		AcceleratedFov.SnapTo(0);
		AcceleratedTilt.SnapTo(0);

		FVector InputSnap = MovementComponent.Velocity.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal().GetClampedToMaxSize(0.37);
		SwarmBoatComponent.AcceleratedInput.SnapTo(InputSnap);

		// MovementComponent.Reset();

		Player.ApplyCameraSettings(SwarmBoatComponent.CameraSettings.WaterMovementSettings, 2, this);

		// One shot enter shake
		Player.PlayCameraShake(SwarmBoatComponent.CameraShakes.MagnetDroneBoardingCameraShakeClass, this);

		// Looping wavy juice
		Player.PlayCameraShake(SwarmBoatComponent.CameraShakes.IdleCameraShakeClass, this);

		// Sweeten deal with rumble
		Player.PlayForceFeedback(ForceFeedback::Default_Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwarmDroneComponent.bFloating = false;

		Player.ClearCameraSettingsByInstigator(this, 2.0);
		Player.StopCameraShakeByInstigator(this, false);

		FVector DerivedLocation = Player.ActorLocation + Player.ActorVelocity * Time::GetActorDeltaSeconds(Owner);
		USwarmBoatEventHandler::Trigger_OnWaterExit(Player, DerivedLocation);

		CrumbedInputSize.Value = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Accelerate and sync input
				SwarmBoatComponent.AcceleratedInput.AccelerateTo(MovementComponent.MovementInput, Settings.InputAccelerationDuration, DeltaTime);
				CrumbedInputSize.Value = SwarmBoatComponent.AcceleratedInput.Value.Size();

				// Inherit velocity
				FVector Velocity = MovementComponent.Velocity;

				// Changing drag with input doesn't play nice when adding external impulses (whitewater)
					// More "icy" movement
					// float DragMultiplier = 0.5 * Math::Max(0.25, MovementComponent.MovementInput.Size());
				float DragMultiplier = 0.23;

				// Just move forward, but slower if we are not yet aiming to where player wants to go
				float SpeedMultiplier = Math::Pow(Player.ActorForwardVector.DotProductNormalized(SwarmBoatComponent.AcceleratedInput.Value), 2.0);

				// Do previous only if player is starting from a low velocity
				float SpeedFraction = 1.0 - Math::Saturate(MovementComponent.Velocity.Size() / Settings.MaxSpeed);
				SpeedMultiplier = Math::Min(SpeedMultiplier + SpeedFraction, 1.0);
				Velocity += Player.ActorForwardVector * Settings.MaxSpeed * DragMultiplier * SwarmBoatComponent.AcceleratedInput.Value.Size() * SpeedMultiplier;

				for (ADroneSwarmMoveZone MoveZone : SwarmDroneComponent.ActiveSwarmMoveZones)
				{
					if (!MoveZone.IsA(ADroneSwarmFloatZone))
						continue;

					// Add hover impulse
					Velocity += MoveZone.CalculateAccelerationAtLocation(Player.ActorLocation);

					// Add vertical drag
					Velocity += MoveZone.CalculateDrag(MovementComponent.Velocity, Player.ActorLocation, Player.MovementWorldUp);
				}

				// Add drag
				FVector Drag = -MovementComponent.HorizontalVelocity * SwarmDrone::Movement::DragAirborne * DragMultiplier;
						Drag = Drag.GetClampedToMaxSize(MovementComponent.Velocity.ConstrainToPlane(Player.MovementWorldUp).Size());

				Velocity += Drag;

				// Add toned down gravity
				Velocity += -MovementComponent.WorldUp * Drone::Gravity * DeltaTime * 0.2;

				// Add pending impulses
				Velocity += MovementComponent.GetPendingImpulse();

				FVector DepenetrationDelta;
				FVector Bounce;
				HandleExtendedBodyCollisions(Velocity, DepenetrationDelta, Bounce, DeltaTime);
				MoveData.AddVelocity(Velocity);
				MoveData.AddDelta(DepenetrationDelta * DeltaTime);

				// Calculate rotation
				FQuat Rotation = Player.ActorQuat;
				if (!MovementComponent.MovementInput.IsNearlyZero())
				{
					// How much is the input aiming towards the player forward; make faster if player is aiming backwards
					float FacingMultilpier = 2.0 - Math::Pow(Player.ActorForwardVector.DotProduct(MovementComponent.MovementInput), 3.0	);
					FQuat TargetRotation = FQuat::MakeFromXZ(MovementComponent.MovementInput, Player.MovementWorldUp);
					Rotation = Math::QInterpTo(Rotation, TargetRotation, DeltaTime, 1.5 * MovementComponent.MovementInput.Size() * FacingMultilpier);
				}

				// Eman TODO: Apply rotation over several ticks
				// if (!Bounce.IsNearlyZero())
				// {
				// 	FQuat TargetRotation = FQuat::MakeFromXZ(Bounce, Player.MovementWorldUp);
				// 	Rotation = Math::QInterpTo(Rotation, TargetRotation, DeltaTime, 1.5 * MovementComponent.MovementInput.Size());
				// }

				MoveData.SetRotation(Rotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Spin that sucker'round
			TickPropellerBot(DeltaTime);

			// Adds wavy move feels
			TickJuicyMeshMovement(DeltaTime);

			// Fov juice, cause why not? (camera shake?)
			float SpeedFraction = Math::Saturate(MovementComponent.Velocity.Size() / Settings.MaxSpeed);
			AcceleratedFov.AccelerateTo(Settings.AdditiveSpeedFov * Math::Square(SpeedFraction), 3.0, DeltaTime);
			UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(AcceleratedFov.Value, this);

			// Eman TODO: Temp lol mast
			// Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + Player.MovementWorldUp * 170, FLinearColor::Black);
		}
	}

	// Do extra collision handling in the front part of the boat
	void HandleExtendedBodyCollisions(FVector& OutVelocity, FVector& OutDepenetrationDelta, FVector& OutBounce, float DeltaTime)
	{
		FVector MoveDelta = OutVelocity * DeltaTime;
		if (MoveDelta.IsNearlyZero())
			return;

		FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MovementComponent);
		Trace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
		Trace.SetTraceComplex(true);
		Trace.IgnorePlayers();

		FVector ForwardOffset = Player.ActorForwardVector * Player.CapsuleComponent.CapsuleRadius;
		FHitResult HitResult = Trace.QueryTraceSingle(Player.ActorLocation + ForwardOffset, Player.ActorLocation + ForwardOffset + MoveDelta);
		if (HitResult.bBlockingHit)
		{
			if (HitResult.ImpactNormal.DotProduct(MovementComponent.WorldUp) > 0.5)
			{
				if (OutVelocity.GetSafeNormal().DotProduct(-HitResult.ImpactNormal) > 0.2)
				{
					// Eman TODO: Check for tag or volume
					// Eman TODO: workout proper jump
					FSwarmBoatBeachingParams BeachingParams;
					BeachingParams.ExitImpluse = MovementComponent.Velocity.GetDirectionTangentToSurface(HitResult.ImpactNormal, MovementComponent.WorldUp).GetSafeNormal();
					BeachingParams.ExitImpluse = BeachingParams.ExitImpluse * 500 + MovementComponent.WorldUp * SwarmDroneComponent.MovementSettings.JumpImpulse * 0.7;
					SwarmBoatComponent.EnterBeach(BeachingParams);

					return;
				}
			}

			const FVector Velocity = OutVelocity;
			float VelocitySurfaceProjection = Velocity.GetSafeNormal().DotProduct(-HitResult.ImpactNormal);

			// Do we want this fucker to bounce?
			OutVelocity = (Velocity + HitResult.ImpactNormal * VelocitySurfaceProjection * Velocity.Size()) * 0.95;
			// OutVelocity = (OutVelocity + Math::GetReflectionVector(MoveDelta, HitResult.Normal)) * 0.95;

			// Add bounce if player is not acttively trying to hit the surface
			if (MovementComponent.MovementInput.DotProduct(-HitResult.ImpactNormal) < 0.5)
			{
				FVector Bounce = Math::GetReflectionVector(Velocity, HitResult.ImpactNormal);
				OutBounce = Bounce.ConstrainToPlane(Player.MovementWorldUp) * VelocitySurfaceProjection;
				OutVelocity += OutBounce;
			}

			// Giggitty
			if (HitResult.bStartPenetrating)
			{
				OutDepenetrationDelta = HitResult.ImpactNormal * (HitResult.PenetrationDepth / DeltaTime);
				OutDepenetrationDelta = OutDepenetrationDelta.GetClampedToMaxSize(Settings.MaxSpeed);
			}

			OutVelocity = OutVelocity.GetClampedToMaxSize(Settings.MaxSpeed);

			if(!bHadWallImpact)
			{
				FSwarmBoatWallImpactEventParams Params;
				Params.Strength = SwarmDroneComponent.MoveComp.PreviousVelocity.Size() / 900;
				USwarmBoatEventHandler::Trigger_OnWallImpact(Player, Params);

				SwarmBoatComponent.DetachMagnetDroneFromBoat();
			}
		}

		bHadWallImpact = HitResult.bBlockingHit;
	}

	void TickPropellerBot(float DeltaTime)
	{
		ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[SwarmBoatComponent.BotCount - 1];

		// Spin them engine bros 
		float Speed = CrumbedInputSize.Value * Settings.MaxSpeed * 1.2 + Player.CapsuleComponent.GetPhysicsAngularVelocityInDegrees().Size() * 0.5;
		FQuat Torque = FQuat(FVector::UpVector, Math::DegreesToRadians(Speed) * DeltaTime * 2.5);
		SwarmBot.AddActorLocalRotation(Torque);
	}

	void TickJuicyMeshMovement(float DeltaTime)
	{
		float SpeedFraction = Math::Saturate(MovementComponent.Velocity.Size() / Settings.MaxSpeed);
		float BlendInAlpha = Math::Pow((Math::Saturate(ActiveDuration / BlendInDuration)), 2.5);

		// Roll boat to follow velocity (Sweetlips was right 🍬👄)
		float Tilt = -Player.ActorRightVector.DotProduct(SwarmBoatComponent.AcceleratedInput.Value) * 20;
		AcceleratedTilt.AccelerateTo(Tilt, 0.2, DeltaTime);
		FVector BoatUpVector = Player.ActorUpVector.RotateAngleAxis(AcceleratedTilt.Value, Player.ActorForwardVector);
		FQuat BoatRotation = FQuat::MakeFromXZ(Player.ActorForwardVector, BoatUpVector);

		// Add some floaty movement (lessen the faster the boat goes)
		float FloatyMultiplier = (1.0 - Math::Pow(SpeedFraction, 0.15)) * 8.0;
		float FloatySpeedMultiplier = 0.7;
		FVector PerlinNoise = FVector(Math::PerlinNoise1D((ActiveDuration + 161) * FloatySpeedMultiplier), Math::PerlinNoise1D(ActiveDuration * FloatySpeedMultiplier), 0) * FloatyMultiplier;
		FQuat TideOffset = FQuat::MakeFromEuler(PerlinNoise);
		BoatRotation *= TideOffset;

		// Add acceleration pitch
		float SpeedPitchMultiplier = SpeedFraction;
		float WaveMultiplier = Math::Abs(Math::PerlinNoise1D(ActiveDuration * SwarmBoatComponent.AcceleratedInput.Value.GetSafeNormal().Size()) * 1.5);
		FQuat SpeedPitch = FQuat::MakeFromEuler(FVector(0, 10.0 * SpeedPitchMultiplier * WaveMultiplier, 0));
		BoatRotation *= SpeedPitch;

		// Add boarding rumble
		BoatRotation *= SwarmBoatComponent.BoardingMeshRumble;

		// Blend in rotation
		BoatRotation = FQuat::FastLerp(SwarmDroneComponent.DroneMesh.ComponentQuat, BoatRotation, BlendInAlpha);

		SwarmDroneComponent.DroneMesh.SetWorldRotation(BoatRotation);
	}
}