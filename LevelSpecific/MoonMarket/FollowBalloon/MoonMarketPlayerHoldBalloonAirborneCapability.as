
class UMoonMarketPlayerHoldBalloonAirborneCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 160;

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerLandingComponent LandingComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UMoonMarketHoldBalloonComp HoldBalloonComp;

	USteppingMovementData Movement;
	bool bUseGroundedTraceDistance = false;
	
	float Drag = 3;
	const float MinAccelerationNeeded = 150;

	float VerticalAcceleration = 0;
	
	const float MinVerticalAcceleration = -600;
	const float MaxVerticalAcceleration = -400;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		HoldBalloonComp = UMoonMarketHoldBalloonComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HoldBalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return false;

		if(MoveComp.HasGroundContact() && VerticalAcceleration < MinAccelerationNeeded)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HoldBalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return true;
			
		if(MoveComp.HasGroundContact() && VerticalAcceleration < MinAccelerationNeeded)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);

		// If we find a follow velocity component on the object we just left
		if (MoveComp.PreviousGroundContact.IsValidBlockingHit())
		{
			UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GetPreviousGroundContact().Actor.GetComponent(UPlayerInheritVelocityComponent));
			if(VelocityComp != nullptr)
			{
				FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
				FVector VerticalVelocity = MoveComp.GetVerticalVelocity();

				VelocityComp.AddFollowAdjustedVelocity(MoveComp, HorizontalVelocity, VerticalVelocity);
				Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		bUseGroundedTraceDistance = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HoldBalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return;

		float CombinedDot = 0;

		for(auto Balloon : HoldBalloonComp.CurrentlyHeldBalloons)
		{
			FVector ToBalloon = Balloon.ActorLocation - Player.ActorLocation;
			float Dot = ToBalloon.GetSafeNormal().DotProduct(FVector::UpVector);
			//The higher this number, the more the balloons will have to be directly above the player for the lifting to take place.
			//If the balloons are following diagonally above the player, the player might get an upward boost or slowly fall down depending on how high this number is.
			int Mult = 4;
			Dot = (Dot * Mult) - (Mult-1);
			CombinedDot += Dot;
		}

		CombinedDot = Math::Clamp(CombinedDot, 0, HoldBalloonComp.BalloonsRequiredToStartLifting);
		float Alpha = CombinedDot / HoldBalloonComp.BalloonsRequiredToStartLifting;
		float AdjustedAlpha = HoldBalloonComp.BalloonLiftStrengthCurve.GetFloatValue(Alpha);
		VerticalAcceleration = Math::Lerp(MinVerticalAcceleration, MaxVerticalAcceleration, AdjustedAlpha);
		VerticalAcceleration = Math::Clamp(VerticalAcceleration, MinVerticalAcceleration, MaxVerticalAcceleration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);

				Movement.AddHorizontalVelocity(AirControlVelocity);

				FVector TargetVerticalVelocity = FVector::UpVector * VerticalAcceleration;

				float InterpSpeedMultipier = 1 - (Math::Saturate(HoldBalloonComp.CurrentlyHeldBalloons.Num() / Math::RoundToFloat(HoldBalloonComp.BalloonsRequiredToStartLifting)) / 2);
				FVector VerticalVelocity = Math::VInterpConstantTo(MoveComp.VerticalVelocity, TargetVerticalVelocity, DeltaTime, 800 * InterpSpeedMultipier);
				if(VerticalVelocity.Z > MaxVerticalAcceleration)
					VerticalVelocity.Z = Math::FInterpConstantTo(VerticalVelocity.Z, MaxVerticalAcceleration, DeltaTime, 1600);
				
				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.AddPendingImpulses();

				if(MoveComp.MovementInput.IsNearlyZero())
					Movement.AddHorizontalVelocity(-MoveComp.HorizontalVelocity * (Drag * DeltaTime));
			

				if(MoveComp.VerticalVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) <= 0)
					AirMotionComp.AnimData.bHighVelocityLandingDetected = TraceAheadForLanding();

				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// If this is the reset frame, we use a bigger stepdown
			// to find out if we are grounded or not
			if(!MoveComp.bHasPerformedAnyMovementSinceReset || bUseGroundedTraceDistance)
			{
				Movement.ForceGroundedStepDownSize();
			}

			// We need to request grounded if this capability finds
			// the ground, else we will get a small step animation
			// in the beginning after a reset
			if(MoveComp.IsOnAnyGround())
			{
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
				bUseGroundedTraceDistance = true;
			}
			else
			{
				Movement.RequestFallingForThisFrame();
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
			}
		}
	}

	const float LANDING_HORIZONTAL_VELOCITY_CUTOFF = 1000;

	bool TraceAheadForLanding()
	{
		if(MoveComp.Velocity.Size() < LANDING_HORIZONTAL_VELOCITY_CUTOFF)
			return false;

		FHazeTraceSettings AnticipationTrace = Trace::InitFromMovementComponent(MoveComp);
		AnticipationTrace.UseLine();
		AnticipationTrace.UseShapeWorldOffset(FVector::ZeroVector);
		
		if(IsDebugActive())
			AnticipationTrace.DebugDrawOneFrame();

		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart + MoveComp.Velocity * 0.75;

		FHitResult AnticipationHit = AnticipationTrace.QueryTraceSingle(TraceStart, TraceEnd);

		return AnticipationHit.bBlockingHit;
	}
}