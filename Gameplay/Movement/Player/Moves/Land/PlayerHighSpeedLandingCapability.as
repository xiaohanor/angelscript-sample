struct FPlayerHighSpeedLandingActivationParams
{
	bool bForcedActivation = false;
}

struct FPlayerHighSpeedLandingDeactivationParams
{
	bool bLandingFinished = false;
}

class UPlayerHighSpeedLandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerMovementTags::LandingApexDive);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionHighSpeedLanding);

	default CapabilityTags.Add(BlockedWhileIn::ShapeShiftForm);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 145;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USteppingMovementData Movement;
	UPlayerMovementComponent MoveComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerSprintComponent SprintComp;
	UPlayerAirMotionComponent AirMotionComp;

	const float LandingDuration = 0.5;
	const float MaxSlideDistance = 500;
	const float MinimumStopPowerCurve = 1;

	FVector StartVelocity;
	FVector StartLoc;
	FVector EndLoc;
	FVector Dir;
	
	bool bInLandingState = false;
	float LandingCurvePower;
	float CurvedLandingPeriod;
	float ExitSpeed;
	float CurrentDuration = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerHighSpeedLandingActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsInAir())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (FloorMotionComp.Data.bForceHighSpeedLanding)
		{
			Params.bForcedActivation = true;
			return true;
		}

		if (!MoveComp.WasFalling())
			return false;

		if (MoveComp.HorizontalVelocity.Size() < AirMotionComp.Settings.HighspeedLandingHorizontalThreshhold)
			return false;

		// Don't perform landing on an edge that we're leaving
		if (MoveComp.GetGroundContactEdge().IsMovingPastEdge())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerHighSpeedLandingDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (CurrentDuration >= LandingDuration)
		{
			Params.bLandingFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerHighSpeedLandingActivationParams Params)
	{
		//Might change or add to this to a landing or equivalent tag
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);
		Player.BlockCapabilities(BlockedWhileIn::HighSpeedLanding, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);

		FloorMotionComp.AnimData.bTriggeredHighSpeedLanding = true;

		//Check for forced activation and set our enter velocity
		if(Params.bForcedActivation)
		{
			StartVelocity = FloorMotionComp.Data.ForceHighSpeedLandingVelocity;

			if(FloorMotionComp.Data.ForceHighSpeedExitSpeed >= 0)
				ExitSpeed = FloorMotionComp.Data.ForceHighSpeedExitSpeed;
			else
				ExitSpeed = Player.IsSprintToggled() ? SprintComp.Settings.MaximumSpeed * 1.5 : FloorMotionComp.Settings.MaximumSpeed * 1.5;

			FloorMotionComp.Data.ResetForceHighSpeedlandingData();
		}
		else
		{
			//Do we want to convert a bit of vertical for this horizontal aswell? - AL
			StartVelocity = MoveComp.HorizontalVelocity;
			ExitSpeed = Player.IsSprintToggled() ? SprintComp.Settings.MaximumSpeed * 1.5 : FloorMotionComp.Settings.MaximumSpeed * 1.5;
		}

		StartLoc = Player.ActorLocation;
		EndLoc = (StartVelocity * LandingDuration) / 2;
		EndLoc += StartLoc;

		bInLandingState = true;

		Dir = MoveComp.HorizontalVelocity.GetSafeNormal();

		//This should never happen as we have a minimum velocity requirement but you never know.
		if (Dir.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		float StartSpeed = Math::Max(StartVelocity.Size(), 1);

		float WantedPower = (StartSpeed * LandingDuration) / MaxSlideDistance - 1.0;
		LandingCurvePower = Math::Max(MinimumStopPowerCurve, WantedPower);
		CurvedLandingPeriod = LandingDuration;


		CurrentDuration = 0;

		//If we are to missaligned with our landing direction then snap our rotation
		if(Player.ActorForwardVector.DotProduct(MoveComp.HorizontalVelocity.GetSafeNormal()) <= 0)
			Player.SetActorRotation(Dir.Rotation());

		Player.SetMovementFacingDirection(Dir);

#if !RELEASE
		if (IsDebugActive())
			Print(f"Slowdown from speed {StartSpeed} for {CurvedLandingPeriod} with power curve {LandingCurvePower}");
#endif

		if(Player.IsMovementCameraBehaviorEnabled())
		{
			FHazeCameraImpulse GroundImpactImpulse;

			GroundImpactImpulse.WorldSpaceImpulse = MoveComp.GravityDirection * 1000;
			GroundImpactImpulse.ExpirationForce = 80;
			GroundImpactImpulse.Dampening = 0.4;
			
			Player.ApplyCameraImpulse(GroundImpactImpulse, this);

			if(FloorMotionComp.HighSpeedLandingShake != nullptr)
				Player.PlayCameraShake(FloorMotionComp.HighSpeedLandingShake, this);
		}

		if(FloorMotionComp.HighSpeedLandingFF != nullptr)
			Player.PlayForceFeedback(FloorMotionComp.HighSpeedLandingFF, this);

		FHighSpeedLandingStartedEffectEventParams EffectParams;
		FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MoveComp);
		EffectParams.SurfaceType = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.InternalHitResult,Trace).SurfaceType;
		UPlayerCoreMovementEffectHandler::Trigger_Landing_HighSpeed_Start(Player, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerHighSpeedLandingDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);
		Player.UnblockCapabilities(BlockedWhileIn::HighSpeedLanding, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);

		FloorMotionComp.AnimData.bTriggeredHighSpeedLanding = false;
		FloorMotionComp.Data.ResetForceHighSpeedlandingData();

		//Cleanup
		bInLandingState = false;

#if !RELEASE
		if (IsDebugActive())
			Print(f"Actually covered {Player.ActorLocation.Distance(StartLoc)}");
#endif
		UPlayerCoreMovementEffectHandler::Trigger_Landing_HighSpeed_Stop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(Dir);

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				CurrentDuration += DeltaTime;

				float CurvedPct = Math::Saturate(CurrentDuration / CurvedLandingPeriod);
				float SpeedAlpha = Math::Pow(1.0 - CurvedPct, LandingCurvePower);
				SpeedAlpha = Math::Clamp(SpeedAlpha, 0.0, 1.0);

				Dir = MoveComp.HorizontalVelocity.GetSafeNormal();

				if (Dir.IsNearlyZero())
					Dir = Player.ActorForwardVector;

				float Speed = Math::Lerp(ExitSpeed, StartVelocity.Size(), SpeedAlpha);
				FVector Velocity = Dir * Speed;
				Velocity = Velocity.RotateVectorTowardsAroundAxis(MoveComp.MovementInput.GetSafeNormal(), MoveComp.WorldUp, (Math::Clamp(270 * (SpeedAlpha * 1.25), 0, 270)) * DeltaTime);

				Movement.AddHorizontalVelocity(Velocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(20.0);

				Movement.StopMovementWhenLeavingEdgeThisFrame();
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0));
				Movement.BlockStepUpForThisFrame();

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Landing");
		}

#if !RELEASE
		if (IsDebugActive())
			Debug::DrawDebugPoint(Player.ActorLocation, 10.0, FLinearColor::Blue, 10.0);
#endif

	}
};
