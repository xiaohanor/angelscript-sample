struct FSwarmBotJumpData
{
	FVector Velocity;

	// [0, 1] bigger bias = greater lag
	float Bias;
}

struct FSwarmDroneJumpDeactivationParams
{
	bool bJumpDone = false;
}

class USwarmDroneJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneJumpCapability);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneActionMovement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerMovementComponent MovementComponent;
	USwarmDroneBounceComponent BouncedComp;

	TArray<FSwarmBotJumpData> BotData;

	bool bBotsInPlace;
	bool bShouldLerpToBall;
	bool bHasReachedApex = false;
	float LerpTime;

	const float ReconstitutionDuration = 0.2;

	float JumpGraceTimer = 0;

	// Eman TODO: Ideal value is 0.9, but we have to handle faster jumping
	const float BotFormationInterruptionAtJumpFraction = 0.65;

	// This is an interpolated player forward that lags behind the actual movement one
	FQuat JumpForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		BouncedComp = USwarmDroneBounceComponent::Get(Owner);

		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
			BotData.Add(FSwarmBotJumpData());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStartedDuringTime(ActionNames::MovementJump, SwarmDroneComponent.MovementSettings.JumpInputBufferTime))
			return false;

		if (SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if(!IsInJumpGracePeriod())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneJumpDeactivationParams& DeactivationParams) const
	{
		// Eman TODO: Switch to air movement after vertical impulse is done
		if (bBotsInPlace && (MovementComponent.IsOnWalkableGround() || BouncedComp.bIsInBounceState))
		{
			DeactivationParams.bJumpDone = true;
			return true;
		}

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmTransitionCapability))
			return true;

		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	FVector DroneVelocity;
	FVector Target;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwarmDroneComponent.bJumping = true;
		JumpForward = FQuat::MakeFromXZ(Player.ActorForwardVector, Player.MovementWorldUp);

		// If we are moving over a certain speed (say we dashed or rolled very quickly), limit horizontal speed
		if(MovementComponent.HorizontalVelocity.Size() > SwarmDroneComponent.MovementSettings.JumpMaxHorizontalSpeed)
		{
			FVector ClampedHorizontalVelocity = MovementComponent.HorizontalVelocity.GetClampedToMaxSize(SwarmDroneComponent.MovementSettings.JumpMaxHorizontalSpeed);
			Player.SetActorHorizontalVelocity(ClampedHorizontalVelocity);
		}

		FVector Impulse = Player.MovementWorldUp * SwarmDroneComponent.MovementSettings.JumpImpulse;

		// Limit max vertical impulse to prevent super high jumps
		float CurrentSpeedInJumpDirection = Player.ActorVelocity.DotProduct(Player.MovementWorldUp);
		if(CurrentSpeedInJumpDirection > SwarmDroneComponent.MovementSettings.JumpImpulse)
		{
			// If we are already moving fast upwards, don't jump
			Impulse = FVector::ZeroVector;
		}
		else if(CurrentSpeedInJumpDirection > 0)
		{
			Impulse -= Player.MovementWorldUp * CurrentSpeedInJumpDirection;
		}

		Player.AddMovementImpulse(Impulse);

		Target = Player.ActorLocation;
		DroneVelocity = MovementComponent.Velocity + MovementComponent.GetFollowVelocity() + Impulse;

		for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
		{
			FTransform Transform = SwarmBot.ActorTransform;
			SwarmBot.Root.SetbAbsoluteLocation(true);
			SwarmBot.Root.SetbAbsoluteRotation(true);
			SwarmBot.SetActorTransform(Transform);

			BotData[SwarmBot.Id].Velocity = DroneVelocity;

			// Move first the ones closest to the top
			FVector PlayerToBot = (SwarmBot.ActorLocation - Player.ActorLocation).GetSafeNormal();
			BotData[SwarmBot.Id].Bias = 1.0 - ((PlayerToBot.DotProduct(Player.MovementWorldUp) + 1.0) * 0.5);
		}

		bBotsInPlace = false;
		bShouldLerpToBall = false;
		bHasReachedApex = false;
		LerpTime = 0.;

		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);

		USwarmDroneEventHandler::Trigger_OnJump(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSwarmDroneJumpDeactivationParams DeactivationParams)
	{
		// Reset bots to relative space IF jump completed and deactivated normally
		if (DeactivationParams.bJumpDone || Player.IsPlayerDead() || Player.IsPlayerRespawning())
		{
			for (ASwarmBot SwarmBot : SwarmDroneComponent.SwarmBots)
			{
				SwarmBot.Root.SetbAbsoluteLocation(false);
				SwarmBot.Root.SetbAbsoluteRotation(false);

				SwarmBot.ResetRelativeTransform();
			}
		}
		else
		{
			// Player (stupidly) interrputed by swarmifying mid-jump... reset non-deployed bots only
			// reset everything otherwise (maybe depends?)
			int StartIndex = SwarmDroneComponent.IsSwarmTransitionActive() ? SwarmDrone::DeployedBotCount : 0;

			for (int i = StartIndex; i < SwarmDrone::TotalBotCount; i++)
			{
				ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
				SwarmBot.Root.SetbAbsoluteLocation(false);
				SwarmBot.Root.SetbAbsoluteRotation(false);

				SwarmBot.ResetRelativeTransform();
			}
		}

		SwarmDroneComponent.bJumping = false;

		SwarmDroneComponent.ClearSwarmTransitionBlock(this);
		// USwarmDroneEventHandler::Trigger_OnSwarmLand(Player);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MovementComponent.IsOnWalkableGround() || MovementComponent.HasUnstableGroundContactEdge())
			JumpGraceTimer = 0.0;
		else
			JumpGraceTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update player movement forward
		JumpForward = Math::QInterpTo(JumpForward, Player.ActorQuat, DeltaTime, 10);

		// Start ballifying when we're almost done with a regular jump (no ground height difference)
		float JumpProgress = Math::Saturate(ActiveDuration / BotFormationInterruptionAtJumpFraction);
		if (!bShouldLerpToBall && JumpProgress >= 1.0)
			bShouldLerpToBall = true;

		const float SquaredActiveDuration = Math::Pow(ActiveDuration, 3);

		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			// FVector TargetLocation = SwarmBot.GetInitialWorldTransformOnMesh().Location;

			// // float InterpSpeed = (SwarmBot.Id + 10) * 0.02 * MovementComponent.Velocity.Size(); / Snake
			// float InterpSpeed = (SwarmBot.Id + 10) * 0.03 * MovementComponent.Velocity.Size() + ActiveDuration * 1000;

			// FVector Location = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetLocation, DeltaTime, InterpSpeed);

			// SwarmBot.SetActorLocation(Location);
			// SwarmBot.SetActorRotation(SwarmBot.GetInitialWorldTransformOnMesh().Rotator());


			// Use bias to calculate bot position offset,
			// reincorporate faster with time the further behind (bigger bias)
			float RawBias = BotData[SwarmBot.Id].Bias;
			float AcceleratedBias = RawBias - (SquaredActiveDuration * RawBias * 5.0);

			// Calculate velocity and set location
			FVector& Velocity = BotData[i].Velocity;
			float Offset = Math::Lerp(1.2, 0.2 * Math::Min(ActiveDuration, 0.3) * 10, AcceleratedBias);
			Velocity -= Player.MovementWorldUp * Drone::Gravity * DeltaTime * Offset;

 			// Add inherited velocity but remove offset (don't want them to lag behind)
			FVector InheritedHorizontalVelocity = MovementComponent.Velocity.ConstrainToDirection(JumpForward.RightVector);
			{
				// Add bot vertical velocity
				Velocity = Velocity.ConstrainToDirection(Player.MovementWorldUp);

				// Add horizontal velocity plus potential follow, but remove
				// inherited player's horizontal velocity since we handle that separately
				Velocity += MovementComponent.Velocity.ConstrainToDirection(Player.ActorForwardVector) - InheritedHorizontalVelocity + MovementComponent.GetFollowVelocity() / Offset;

				// Magic math to lower steering in tail bots
				float HorizontalFollowBias = Math::Pow((1.0 - RawBias) * 1.2, 3.0);
				Velocity += InheritedHorizontalVelocity * HorizontalFollowBias;
			}

			// Check if its time to tell event handlers to prepare for landing
			if(!bHasReachedApex)
			{
				if(Velocity.Z <= 0)
				{
					USwarmDroneEventHandler::Trigger_OnLand_SwarmBots(Player);
					bHasReachedApex = true;
				}
			}

			FVector Location = SwarmBot.ActorLocation + Velocity * DeltaTime * Offset;

			FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
			Trace.UseSphereShape(SwarmBot.Collider.SphereRadius * 1.0);
			Trace.IgnorePlayers();

			FVector FrameVelocity = Location - SwarmBot.ActorLocation;
			FVector MoveDelta = FrameVelocity * DeltaTime;
			if (!MoveDelta.IsNearlyZero())
			{
				FHitResult HitResult = Trace.QueryTraceSingle(SwarmBot.ActorLocation, SwarmBot.ActorLocation + MoveDelta);
				if (HitResult.bBlockingHit)
				{
					// FrameVelocity *= DeltaTime;
					FrameVelocity += HitResult.ImpactNormal * FrameVelocity.ConstrainToDirection(HitResult.ImpactNormal).Size();

					// FVector BotToPlayer = (Player.ActorLocation - SwarmBot.ActorLocation).GetSafeNormal();
					// FrameVelocity = FrameVelocity.RotateTowards(BotToPlayer, 1000);

					// We well go back to ball now, block transition
					if (!bShouldLerpToBall && MoveDelta.GetSafeNormal().DotProduct(SwarmDroneComponent.Player.MovementWorldUp) < 0.0)
					{
						bShouldLerpToBall = true;
						SwarmDroneComponent.ApplySwarmTransitionBlock(this);
					}
				}
			}

			if (bShouldLerpToBall)
			{
				float Alpha = Math::Saturate(LerpTime / ReconstitutionDuration);

				// Interpolate towards place in ball
				FVector RelativeLocation = SwarmBot.GetSwarmBotRelativeLocationOnDroneMeshWithFraction(Alpha);
				FVector TargetWorldLocation = SwarmDroneComponent.DroneMesh.WorldTransform.TransformPositionNoScale(RelativeLocation);
				FVector WorldLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetWorldLocation, DeltaTime, Alpha * 2500.0 * (1.2 - AcceleratedBias)) + MovementComponent.Velocity * DeltaTime + MovementComponent.GetFollowVelocity() * DeltaTime;
				SwarmBot.SetActorLocation(WorldLocation);

				// Lerp local rotation of little cutie
				FQuat TargetRotation = SwarmBot.PlayerSwarmDroneComponent.DroneMesh.WorldTransform.TransformRotation(SwarmBot.InitialTransformOnMesh.Rotation);
				FQuat Rotation = Math::QInterpConstantTo(SwarmBot.ActorRotation.Quaternion(), TargetRotation, DeltaTime, 20);
				SwarmBot.SetActorRotation(Rotation);
			}
			else
			{
				SwarmBot.SetActorLocation(SwarmBot.ActorLocation + FrameVelocity);

				// Add some flavour if jump is static
				FQuat TargetRotation = FrameVelocity.ConstrainToPlane(Player.MovementWorldUp).Size() > 1.0 ?
					Velocity.ToOrientationQuat() :
					SwarmBot.ActorQuat * FQuat(Player.MovementWorldUp, DeltaTime * 20);

				FQuat Rotation = Math::QInterpConstantTo(SwarmBot.ActorRotation.Quaternion(), TargetRotation, DeltaTime, 10);
				SwarmBot.SetActorRotation(Rotation);
			}
		}

		if (bShouldLerpToBall)
		{
			LerpTime += DeltaTime;
			if (LerpTime >= ReconstitutionDuration)
				bBotsInPlace = true;
		}
	}

	bool IsInJumpGracePeriod() const
	{
		// We can always jump after bouncing
		if(BouncedComp.bIsInBounceState)
			return true;

		return JumpGraceTimer <= SwarmDroneComponent.MovementSettings.JumpGraceTime;
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Is Inputting", WasActionStartedDuringTime(ActionNames::MovementJump, SwarmDroneComponent.MovementSettings.JumpInputBufferTime));
		TemporalLog.Value("JumpGraceTimer", JumpGraceTimer);
		TemporalLog.Value("JumpGraceTime", SwarmDroneComponent.MovementSettings.JumpGraceTime);
		TemporalLog.Value("IsInJumpGracePeriod", IsInJumpGracePeriod());
	}
	#endif
}

