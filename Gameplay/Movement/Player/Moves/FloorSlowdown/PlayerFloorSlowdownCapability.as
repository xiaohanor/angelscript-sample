
//[AL] Should we be slowing down with local velocity when impacting a moving target
// OR
// Should we be adjusting with the follow Velocity:
//		- Impacting with a greater aligned velocity would cause a slowdown
//		- Impacting with a lower velocity would cause no slowdown / a stumble / etc
//		- Impacting AGAINST the velocity would cause a very long distance slowdown or even a roll as the velocity delta is very big?

struct FPlayerSlowdownDeactivationParams
{
	bool bSlowdownFinished = false;
};

class UPlayerFloorSlowdownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionSlowdown);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 148;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerFloorSlowdownComponent SlowdownComp;
	UPlayerFloorMotionComponent FloorMotionComp;

	float CurrentSpeed;
	FVector Dir;
	FVector StartVelocity;
	FVector LocalVelocity;
	FVector StartLoc;
	FVector EndLoc;

	float CurvedSlowdownPeriod = 0.0;
	float SlowdownCurvePower = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SlowdownComp = UPlayerFloorSlowdownComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if(MoveComp.HasUnstableGroundContactEdge())
			return false;

		// Don't perform slowdown on an edge that we're leaving
		if (MoveComp.GetGroundContactEdge().IsMovingPastEdge())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		if (!MoveComp.MovementInput.IsNearlyZero())
			return false;

		if (MoveComp.HorizontalVelocity.IsNearlyZero(25.0))
			return false;

		if (SlowdownComp.Settings.Duration <= 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerSlowdownDeactivationParams& DeactivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (!MoveComp.MovementInput.IsNearlyZero())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (ActiveDuration >= SlowdownComp.Settings.Duration)
		{
			DeactivationParams.bSlowdownFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		StartVelocity = MoveComp.HorizontalVelocity;
		if(MoveComp.PreviousVerticalVelocity.Size() >= 1500)
			StartVelocity += MoveComp.HorizontalVelocity.GetSafeNormal() * MoveComp.PreviousVerticalVelocity.Size() * 0.2;

		StartLoc = Player.ActorLocation;
		EndLoc = (StartVelocity * SlowdownComp.Settings.Duration) / 2;
		EndLoc += StartLoc;
		SlowdownComp.EndLoc = EndLoc;
		
		SlowdownComp.bInSlowDownState = true;
		Dir = MoveComp.HorizontalVelocity.GetSafeNormal();
		if(Dir.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		float StartSpeed = Math::Max(StartVelocity.Size(), 1.0);

		// d = Duration
		// s = StartSpeed
		// t = Time
		// f(t) = Velocity at time
		// p = Power Curve

		// f(t) = t^p * s
		// F(t) = (1/(p+1)) * t^(p+1) * s

		// CoveredDistance = (F(1.0) - F(0.0)) * d
		// CoveredDistance = (1/(p+1)) * s * d
		float WantedPower = (StartSpeed * SlowdownComp.Settings.Duration) / SlowdownComp.Settings.MaxSlideDistance - 1.0;
		SlowdownCurvePower = Math::Max(SlowdownComp.Settings.MinimumStopPowerCurve, WantedPower);
		CurvedSlowdownPeriod = SlowdownComp.Settings.Duration;

		//Set our vertical landingspeed for animation
		FloorMotionComp.AnimData.VerticalLandingSpeed = Math::Abs(MoveComp.PreviousVerticalVelocity.Size());

#if !RELEASE
		if (IsDebugActive())
			Print(f"Slowdown from speed {StartSpeed} for {CurvedSlowdownPeriod} with power curve {SlowdownCurvePower}");
#endif

		Player.SetMovementFacingDirection(Dir);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerSlowdownDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);

		if (DeactivationParams.bSlowdownFinished)
			Player.SetActorHorizontalVelocity(FVector::ZeroVector);

		//Cleanup
		SlowdownComp.bInSlowDownState = false;

#if !RELEASE
		if (IsDebugActive())
			Print(f"Actually covered {Player.ActorLocation.Distance(StartLoc)}");
#endif

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(Dir);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{

				float CurvedPct = Math::Saturate(ActiveDuration / CurvedSlowdownPeriod);
				float SpeedAlpha = Math::Pow(1.0 - CurvedPct, SlowdownCurvePower);
				SpeedAlpha = Math::Clamp(SpeedAlpha, 0.0, 1.0);

				FVector Velocity = Math::Lerp(FVector::ZeroVector, StartVelocity, SpeedAlpha);

				Movement.AddHorizontalVelocity(Velocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(20.0, false);

				Movement.StopMovementWhenLeavingEdgeThisFrame();
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(0));
				Movement.BlockStepUpForThisFrame();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Movement";
			if (MoveComp.WasFalling())
			{
				AnimTag = n"Landing";

				UPlayerCoreMovementEffectHandler::Trigger_Landed(Player);

				FloorMotionComp.LastLandedTime = Time::GameTimeSeconds;
			}

			// (NS) We not longer use FloorMotionComp in AnimInstances, we check SyncedMovementInputForAnimationOnly directly instead
			// FloorMotionComp.AnimData.bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}

#if !RELEASE
		if (IsDebugActive())
			Debug::DrawDebugPoint(Player.ActorLocation, 10.0, FLinearColor::Blue, 10.0);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}
};