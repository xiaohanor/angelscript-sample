class UTeenDragonRollFloorMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 50;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	USplineLockComponent SplineLockComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UTeenDragonRollSettings RollSettings;
	UTeenDragonRollWallKnockbackSettings KnockbackSettings;

	FVector NonForwardImpulse;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		SplineLockComp = USplineLockComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
		KnockbackSettings = UTeenDragonRollWallKnockbackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;
		

		if(RollComp.IsForcedRolling())
		{
			return true;
		}
		else
		{
			if(!RollComp.bRollIsStarted)
				return false;
			
			if(IsActioning(RollSettings.RollInputActionName))
				return true;

			if(Time::GetGameTimeSince(RollComp.TimeLastStartedRoll) < RollSettings.RollMinDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if(!RollComp.IsForcedRolling())
		{
			if(!IsActioning(RollSettings.RollInputActionName)
			&& Time::GetGameTimeSince(RollComp.TimeLastStartedRoll) > RollSettings.RollMinDuration)
				return true;
		}
		
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTeenDragonRollOnStartedMovingParams Params;
		Params.DragonMesh = DragonComp.DragonMesh;
		UTeenDragonRollVFX::Trigger_OnStartedMovingOnGround(Player, Params);

		if(MoveComp.WasInAir()
		&& Time::GetGameTimeSince(RollComp.TimeLastBecameAirborne) > 0.1)
		{
			float SpeedTowardsGround = MoveComp.PreviousVelocity.DotProduct(MoveComp.CurrentGroundNormal);
			FTeenDragonRollOnLandedParams OnLandParams;
			OnLandParams.GroundLocation = MoveComp.GroundContact.ImpactPoint;
			OnLandParams.GroundNormal = MoveComp.GroundContact.Normal;
			OnLandParams.LandingSpeed = SpeedTowardsGround;
			UTeenDragonRollVFX::Trigger_OnLanded(Player, OnLandParams);
		}

		RollComp.RollUntilImpactInstigators.Reset();
		RollComp.RollingInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UTeenDragonRollVFX::Trigger_OnStoppedMovingOnGround(Player);

		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If anything activate roll until while we are grounded,
		// we only reset it on wall impacts
		if(MoveComp.HasWallContact())
		{
			RollComp.RollUntilImpactInstigators.Reset();
		}

		// if (MoveComp.HasAnyValidBlockingImpacts())
		// {
		// 	for (FMovementHitResult Hit : MoveComp.AllImpacts)
		// 		Print(f"{Hit.Component=}");
		// }

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				auto TempLog = TEMPORAL_LOG(Player, "Teen Dragon Roll")
					.DirectionalArrow("Velocity", Player.ActorLocation, MoveComp.Velocity, 20, 4000, FLinearColor::White)
					.DirectionalArrow("Horizontal Velocity", Player.ActorLocation, MoveComp.HorizontalVelocity, 20, 4000, FLinearColor::Black)
				;

				FVector Impulse = Movement.GetPendingImpulse();

				float ForwardSpeed = MoveComp.HorizontalVelocity.Size();
				FVector ImpulseTowardsForward = Impulse.ConstrainToDirection(Player.ActorForwardVector);
				ForwardSpeed += ImpulseTowardsForward.Size();
				ForwardSpeed -= NonForwardImpulse.DotProduct(Player.ActorForwardVector);

				NonForwardImpulse += Impulse - ImpulseTowardsForward;

				FVector Steering = Player.ActorForwardVector;
				if(!RollComp.bSteeringIsOverridenByAutoAim)
				{
					// STEERING
					FVector MovementInput = MoveComp.GetMovementInput();

					float MovementInputSize = MovementInput.Size();
					if (Math::IsNearlyZero(MovementInputSize))
						MovementInput = RollComp.PreviousMovementInput;
					else
						RollComp.PreviousMovementInput = MovementInput;

					FVector MovementInputDir = MovementInput.GetSafeNormal();
					float SpeedAlpha = Math::NormalizeToRange(ForwardSpeed, RollSettings.MinimumRollSpeed, RollSettings.MaximumRollSpeed);
					float TurnRate = Math::Lerp(RollSettings.RollTurnRateMinSpeed, RollSettings.RollTurnRateMaxSpeed, SpeedAlpha);

					// Reflect off wall turn slowdown
					float TimeSinceLastReflectedOffWall = Time::GetGameTimeSince(RollComp.TimeLastReflectedOffWall);
					if(TimeSinceLastReflectedOffWall < KnockbackSettings.ReflectSteeringSlowdownDuration)
					{
						float SlowDownAlpha = TimeSinceLastReflectedOffWall / KnockbackSettings.ReflectSteeringSlowdownDuration;

						float SlowDownFraction = Math::Lerp(KnockbackSettings.ReflectSteeringSlowdownFraction, 1.0, SlowDownAlpha);
						TurnRate *= SlowDownFraction; 
					}
					// Don't want to not turn when you have a spline lock
					if(!SplineLockComp.HasActiveSplineLock())
						TurnRate *= MovementInputSize;

					Steering = Math::VInterpNormalRotationTo(Player.ActorForwardVector, MovementInputDir, DeltaTime, TurnRate);
				}


				FRotator Rotation = FRotator::MakeFromXZ(Steering, MoveComp.WorldUp);

				if(!RollComp.bHasBeenLaunched)
				{
					if(ForwardSpeed < RollSettings.MinimumRollSpeed - 10.0)
						ForwardSpeed = Math::FInterpConstantTo(ForwardSpeed, RollSettings.MinimumRollSpeed, DeltaTime, RollSettings.RollUnderSpeedAcceleration);
					else if (ForwardSpeed > RollSettings.MaximumRollSpeed + 10.0)
						ForwardSpeed = Math::FInterpConstantTo(ForwardSpeed, RollSettings.MaximumRollSpeed, DeltaTime, RollSettings.RollOverSpeedDeceleration);
					else
					{
						ForwardSpeed -= RollSettings.BaseFloorSpeedLoss * DeltaTime;
						// SLOPE
						FHitResult GroundImpact = MoveComp.GetGroundContact().ConvertToHitResult();
						if (GroundImpact.bBlockingHit)
							UpdateSlopeSpeed(DeltaTime, ForwardSpeed);
					}
				}

				FVector ForwardVelocity = Steering * ForwardSpeed;
				NonForwardImpulse = Math::VInterpTo(NonForwardImpulse, FVector::ZeroVector, DeltaTime,	RollSettings.RollSidewaysDecelerationSpeed);
				
				Movement.AddHorizontalVelocity(ForwardVelocity);
				Movement.AddHorizontalVelocity(NonForwardImpulse);
				Movement.SetRotation(Rotation);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				RollComp.ApplyRollHaptic(ForwardSpeed);

				TempLog
					.DirectionalArrow("Non Forwards Impulse", Player.ActorLocation, NonForwardImpulse, 20, 4000, FLinearColor::Purple)
					.DirectionalArrow("Impulse", Player.ActorLocation, Impulse, 20, 4000, FLinearColor::DPink)
					.DirectionalArrow("Previous Movement Input Dir", Player.ActorLocation, RollComp.PreviousMovementInput * 500, 20, 4000, FLinearColor::Gray)
					.DirectionalArrow("Ground Normal", Player.ActorLocation, MoveComp.CurrentGroundNormal * 500, 20, 4000, FLinearColor::Blue)
					.Value("Forward Speed", ForwardSpeed)
				;
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}

	private void UpdateSlopeSpeed(float DeltaTime, float& Speed)
	{
		FVector HorizontalDirection = MoveComp.HorizontalVelocity.GetSafeNormal();

		float SlopeAlignment = MoveComp.GravityDirection.DotProduct(HorizontalDirection);
		float SlopeMultiplier = SlopeAlignment < 0.0 
			? RollSettings.GravityUpSlopeMultiplier
			: RollSettings.GravityDownSlopeMultiplier;
		float SlopeSpeedChange = (SlopeAlignment * SlopeMultiplier * MoveComp.GetGravityForce() * DeltaTime);

		TEMPORAL_LOG(Player, "Teen Dragon Roll")
			.Value("Slope Speed Change", SlopeSpeedChange)
			.DirectionalArrow("Slope Horizontal Direction", Player.ActorLocation, HorizontalDirection * 500, 20, 4000, FLinearColor::Red)
		;

		Speed += SlopeSpeedChange;
	}
};