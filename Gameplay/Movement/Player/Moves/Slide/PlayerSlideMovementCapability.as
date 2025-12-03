class UPlayerSlideMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);	
	default CapabilityTags.Add(PlayerSlideTags::SlideMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UFloatingMovementData Movement;
	UPlayerSlideComponent SlideComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerSprintComponent SprintComp;

	float SlideTravelledDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UFloatingMovementData);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if (MoveComp.HasUpwardsImpulse())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (!SlideComp.IsSlideActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (!SlideComp.IsSlideActive())
			return true;

		if (SlideComp.IsTemporarySlide())
		{
			float MinDistance = SlideComp.GetSlideInstance().TemporarySlideMinimumDistance;
			if (SlideTravelledDistance >= MinDistance)
			{
				float MaxDuration = SlideComp.GetSlideInstance().TemporarySlideMaximumDuration;
				if (MaxDuration > 0.0 && ActiveDuration >= MaxDuration)
					return true;

				float MinDuration = SlideComp.GetSlideInstance().TemporarySlideMinimumDuration;
				if (ActiveDuration > MinDuration)
				{
					if (MoveComp.HorizontalVelocity.Size() < SlideComp.Settings.SlideMinimumSpeed)
						return true;

					if (MoveComp.HasWallContact())
						return true;
				}
			}

			if (MoveComp.HasUpwardsImpulse())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SlideComp.bIsSliding = true;
		SlideComp.bHasSlidOnGround = true;
		SlideTravelledDistance = 0.0;

		Player.BlockCapabilities(BlockedWhileIn::Slide, this);
		Player.CapsuleComponent.OverrideCapsuleHalfHeight(SlideComp.Settings.CapsuleHalfHeight, this);

		// All our horizontal velocity should be bent into the slide
		FSlideSlopeData Slope = SlideComp.GetSlideSlopeData();

		FVector PrevHorizontalVelocity = MoveComp.GetHorizontalVelocity();
		FVector NewHorizontalVelocity;
		NewHorizontalVelocity += Slope.SlopeForward * PrevHorizontalVelocity.DotProduct(Slope.FacingForward);

		FVector FacingRight = MoveComp.WorldUp.CrossProduct(Slope.FacingForward).GetSafeNormal();
		float SidewaysStartingSpeed = PrevHorizontalVelocity.DotProduct(FacingRight);
		float SidewaysWantedSpeed = MoveComp.MovementInput.DotProduct(FacingRight);

		NewHorizontalVelocity += Slope.SlopeRight * Math::Max(SidewaysStartingSpeed, SidewaysWantedSpeed);

		Player.SetActorHorizontalVelocity(NewHorizontalVelocity);

		if(HasControl())
		{
			FSlideStartedEffectEventParams Params;
			FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MoveComp);
			Params.SurfaceType = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.InternalHitResult,Trace).SurfaceType;
			CrumbStartSlideEffect(Params);
		}

		UMovementFloatingSettings::SetFloatingHeight(Player, FMovementSettingsValue::MakeValue(10), this, EHazeSettingsPriority::Defaults);
		UMovementFloatingSettings::SetValidationMethod(Player, EFloatingMovementValidateMethod::ValidateSweep, this, EHazeSettingsPriority::Defaults);
		UMovementFloatingSettings::SetPerformEdgeDetection(Player, true, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartSlideEffect(FSlideStartedEffectEventParams Params)
	{
		UPlayerCoreMovementEffectHandler::Trigger_Slide_Start(Player, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SlideComp.bIsSliding = false;

		Player.UnblockCapabilities(BlockedWhileIn::Slide, this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		SlideComp.StopTemporarySlides();

		UPlayerCoreMovementEffectHandler::Trigger_Slide_Stop(Player);

		UMovementFloatingSettings::ClearFloatingHeight(Player, this);
		UMovementFloatingSettings::ClearValidationMethod(Player, this);
		UMovementFloatingSettings::ClearPerformEdgeDetection(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FSlideSlopeData Slope = SlideComp.GetSlideSlopeData();

			if (HasControl())
			{
				// Perform movement along the slide forward
				float ForwardSpeed = MoveComp.Velocity.DotProduct(Slope.SlopeForward);

				// Always try to reach a target velocity (or friction down to 0 for temporary slides)
				float TargetForwardSpeed = 0.0;
				float ForwardSpeedAcceleration = 0.0;

				if (SlideComp.IsTemporarySlide())
				{
					TargetForwardSpeed = SlideComp.Settings.SlideTargetSpeed * Slope.RubberBandMultiplier;

					float SpeedAlpha = 0.0;
					float MinDistance = SlideComp.GetSlideInstance().TemporarySlideMinimumDistance;

					float DurationAlpha = 1.0;
					float DistanceAlpha = 1.0;
					if (SlideComp.GetTemporarySlideMinimumDuration() > 0)
						DurationAlpha = Math::Pow(Math::Saturate(ActiveDuration / SlideComp.GetTemporarySlideMinimumDuration()), 2.0);
					if (MinDistance > 0)
						DistanceAlpha = Math::Max(Math::Pow(SlideTravelledDistance / MinDistance, 2.0), 0.1);

					SpeedAlpha = Math::Min(DurationAlpha, DistanceAlpha);
					TargetForwardSpeed = Math::Lerp(TargetForwardSpeed, 0.0, SpeedAlpha);
					ForwardSpeedAcceleration = SlideComp.Settings.TemporarySlideSlowdownDeceleration;
				}
				else
				{
					TargetForwardSpeed = SlideComp.Settings.SlideTargetSpeed * Slope.RubberBandMultiplier;
					ForwardSpeedAcceleration = SlideComp.Settings.TargetInterpAcceleration;
				}

				ForwardSpeed = Math::FInterpConstantTo(
					ForwardSpeed, TargetForwardSpeed,
					DeltaTime, ForwardSpeedAcceleration
				);

				float SlopeAngle = Slope.SlopeForward.GetAngleDegreesTo(Slope.FacingForward);
				if (MoveComp.WorldUp.DotProduct(Slope.SlopeForward - Slope.FacingForward) <= 0.0)
					SlopeAngle = -SlopeAngle;

				// Going downhill speeds up the velocity
				if (SlopeAngle < 0.0 && ForwardSpeed < SlideComp.Settings.SlideMaximumSpeed * Slope.RubberBandMultiplier)
				{
					ForwardSpeed += SlideComp.Settings.DownhillAcceleration * Math::Abs(SlopeAngle) * DeltaTime;
					ForwardSpeed = Math::Min(ForwardSpeed, SlideComp.Settings.SlideMaximumSpeed * Slope.RubberBandMultiplier);
				}

				// Going uphill slows down the velocity
				if (SlopeAngle > 0.0 && ForwardSpeed > SlideComp.Settings.SlideMinimumSpeed * Slope.RubberBandMultiplier)
				{
					ForwardSpeed -= SlideComp.Settings.UphillDeceleration * Math::Abs(SlopeAngle) * DeltaTime;
					if (!SlideComp.IsTemporarySlide())
						ForwardSpeed = Math::Max(ForwardSpeed, SlideComp.Settings.SlideMinimumSpeed * Slope.RubberBandMultiplier);
				}

				// Perform left and right movement depending on our input and settings
				float SidewaysSpeed = MoveComp.Velocity.DotProduct(Slope.SlopeRight);
				float SidewaysInput = MoveComp.MovementInput.DotProduct(Slope.SlopeRight);

				// If we're holding very sideways on the stick, finesse the input so we
				// redirect the magnitude to sideways on the slide, to avoid losing input unexpectedly
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				float StickSidewaysMagnitude = Math::Abs(RawInput.X);
				if (StickSidewaysMagnitude > 0.5 && Math::Abs(SidewaysInput) > 0.1)
					SidewaysInput = Math::Sign(SidewaysInput) * Math::Max(Math::Abs(SidewaysInput), StickSidewaysMagnitude);

				float SidewaysTargetSpeed = SidewaysInput * SlideComp.Settings.SidewaysSpeed;
				float SidewaysAcceleration = SlideComp.Settings.SidewaysAcceleration;

				// Add additional sideways movement when the ground underneath us is tilted
				float TiltAngle = Slope.SlopeRight.GetAngleDegreesTo(Slope.FacingRight);
				if (MoveComp.WorldUp.DotProduct(Slope.SlopeRight - Slope.FacingRight) >= 0.0)
					TiltAngle = -TiltAngle;

				float TiltSpeed = Math::Clamp(
					TiltAngle * SlideComp.Settings.TiltSidewaysSpeedPerDegree,
					-SlideComp.Settings.TiltSidewaysSpeedMaximum,
					SlideComp.Settings.TiltSidewaysSpeedMaximum,
				);
				SidewaysTargetSpeed += TiltSpeed;

				// If we started outside the spline, steer back into it
				bool bIsAutoSteering = false;
				float PreviousLateralDistance = BIG_NUMBER;
				if (Slope.bConstrainToSlopeWidth)
				{
					PreviousLateralDistance = Slope.ConstrainRight.DotProduct(Player.ActorLocation - Slope.SlopeWidthOrigin);

					if (PreviousLateralDistance < -Slope.SlopeWidth)
					{
						SidewaysTargetSpeed = SlideComp.Settings.SidewaysSpeed;
						bIsAutoSteering = true;
					}
					else if (PreviousLateralDistance > Slope.SlopeWidth)
					{
						SidewaysTargetSpeed = -SlideComp.Settings.SidewaysSpeed;
						bIsAutoSteering = true;
					}
				}
				else
				{
					PreviousLateralDistance = 0;
				}

				// When not holding input, we use a different slowdown deceleration rate for sideways speed
				if (MoveComp.MovementInput.IsNearlyZero(0.05) && !bIsAutoSteering)
				{
					if (Math::Abs(SidewaysSpeed) < SlideComp.Settings.SidewaysSpeed
						&& Math::Abs(TiltSpeed) < Math::Abs(SidewaysSpeed))
					{
						SidewaysAcceleration = SlideComp.Settings.SidewaysNoInputDeceleration;
					}
				}

				SidewaysSpeed = Math::FInterpConstantTo(
					SidewaysSpeed, SidewaysTargetSpeed,
					DeltaTime, SidewaysAcceleration,
				);

				// When constrained, slow down lateral velocity to zero if we're reaching the edge
				float ConstrainMultiplier = 1.0;
				if (Slope.bConstrainToSlopeWidth)
				{
					float ConstrainStartPercentage = 1.0 - SlideComp.Settings.SidewaysConstrainedWidthPercentage;
					if (SidewaysSpeed < 0)
					{
						ConstrainMultiplier = Math::GetMappedRangeValueClamped(
								FVector2D(-1.0 * Slope.SlopeWidth, -ConstrainStartPercentage * Slope.SlopeWidth),
								FVector2D(0.0, 1.0),
								PreviousLateralDistance);
					}
					else
					{
						ConstrainMultiplier = Math::GetMappedRangeValueClamped(
								FVector2D(Slope.SlopeWidth, ConstrainStartPercentage * Slope.SlopeWidth),
								FVector2D(0.0, 1.0),
								PreviousLateralDistance);
					}
				}

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value("SlopeAngle", SlopeAngle)
					.Value("TargetForwardSpeed", TargetForwardSpeed)
					.Value("TiltAngle", TiltAngle)
					.Value("ForwardSpeed", ForwardSpeed)
					.Value("SidewaysSpeed", SidewaysSpeed)
					.Value("RubberBandMultiplier", Slope.RubberBandMultiplier)
					.DirectionalArrow("SlopeNormal", Player.ActorLocation, Slope.SlopeNormal * 100.0)
					.DirectionalArrow("SlopeForward", Player.ActorLocation, Slope.SlopeForward * 100.0)
					.DirectionalArrow("ConstrainRight", Player.ActorLocation, Slope.ConstrainRight * 100.0)
					.Value("PreviousLateralDistance", PreviousLateralDistance)
					.Value("SlopeWidth", Slope.SlopeWidth)
					.Value("ConstrainMultiplier", ConstrainMultiplier)
					.DirectionalArrow("ForwardVelocity", Player.ActorLocation, Slope.SlopeForward * ForwardSpeed)
					.DirectionalArrow("RightVelocity", Player.ActorLocation, Slope.SlopeRight * SidewaysSpeed)
				;
#endif
				FVector TargetVelocity;
				TargetVelocity += Slope.SlopeForward * ForwardSpeed;
				TargetVelocity += Slope.SlopeRight * SidewaysSpeed;

				FVector TargetLocation = Player.ActorLocation;
				TargetLocation += Slope.SlopeForward * ForwardSpeed * DeltaTime;
				TargetLocation += Slope.SlopeRight * SidewaysSpeed * DeltaTime * ConstrainMultiplier;

				// Hard constrain the target to the slope width so we never leave it
				if (Slope.bConstrainToSlopeWidth && SlideComp.ActiveSlide.Get().Parameters.SlideType == ESlideType::SplineSlide)
				{
					UHazeSplineComponent SplineComp = SlideComp.ActiveSlide.Get().Parameters.SplineComp;
					float TargetSplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(TargetLocation);
					FTransform TargetSplineTransform = SplineComp.GetWorldTransformAtSplineDistance(TargetSplineDistance);

					float TargetSlopeWidth = Math::Max(TargetSplineTransform.Scale3D.Y * 30.0, Math::Abs(PreviousLateralDistance));

					FVector DeltaFromSpline = TargetLocation - TargetSplineTransform.Location;
					float SidewaysDistance = DeltaFromSpline.DotProduct(TargetSplineTransform.Rotation.RightVector);

#if !RELEASE
					TEMPORAL_LOG(this)
						.Point("TargetLocatonBeforeConstrain", TargetLocation)
						.Point("TargetSplineLocation", TargetSplineTransform.Location)
						.DirectionalArrow("TargetSplineRight", TargetSplineTransform.Location, TargetSplineTransform.Rotation.RightVector * 100.0)
						.Value("SidewaysDistance", SidewaysDistance)
						.Value("TargetSlopeWidth", TargetSlopeWidth)
					;
	#endif

					if (SidewaysDistance > TargetSlopeWidth)
						TargetLocation -= TargetSplineTransform.Rotation.RightVector * (SidewaysDistance - TargetSlopeWidth);
					else if (SidewaysDistance < -TargetSlopeWidth)
						TargetLocation += TargetSplineTransform.Rotation.RightVector * (-SidewaysDistance - TargetSlopeWidth);
				}

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetLocation, TargetVelocity);

				// The ground stickyness is tweaked for 60FPS, but is not sufficient sometimes for 30FPS play
				// Increase the stickiness at lower framerates to compensate
				float FrameStickyness = SlideComp.Settings.GroundStickynessDistance * Math::GetMappedRangeValueClamped(
					FVector2D(1.0/60.0, 1.0/30.0),
					FVector2D(1.0, 2.0),
					DeltaTime
				);
				Movement.UseGroundStickynessDistanceThisFrame(FrameStickyness);

				if (SlideComp.IsTemporarySlide())
				{
					FVector DeltaToMove = TargetLocation - Owner.ActorLocation;
					if (SlideComp.IsFreeformSlide())
						SlideTravelledDistance += DeltaToMove.Size();
					else
						SlideTravelledDistance += DeltaToMove.DotProduct(Slope.SlopeForward);
				}

				// Rotate our facing to be in the direction that we're moving
				FQuat WantedRotation = Player.ActorQuat;
				if (!MoveComp.Velocity.IsNearlyZero())
				{
					if (ForwardSpeed < 0.0)
						WantedRotation = FQuat::MakeFromXZ(Slope.FacingForward, MoveComp.WorldUp);
					else
						WantedRotation = FQuat::MakeFromXZ(MoveComp.Velocity.GetSafeNormal(), MoveComp.WorldUp);
				}

				Movement.InterpRotationTo(
					WantedRotation,
					Math::Lerp(6.0, SlideComp.Settings.FacingRotationSpeed, Math::Saturate(ActiveDuration))
				);

				//Set ForceFeedback
				float FFFrequency = 75.0;
				float FFIntensity = 0.2;
				FHazeFrameForceFeedback FF;
				FF.RightMotor = Math::Sin(ActiveDuration * FFFrequency) * (FFIntensity * (Math::Saturate(MoveComp.Velocity.Size() / SlideComp.Settings.SlideMaximumSpeed)));
				Player.SetFrameForceFeedback(FF);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
				
			//Set turn angle for animation
			if(SlideComp.GetSlideParameters().SlideType == ESlideType::Freeform)
			{
				//If we are freform sliding then get the angle difference from our input / Actor forward
				float AngleDiff = MoveComp.SyncedMovementInputForAnimationOnly.GetAngleDegreesTo(Player.ActorForwardVector.ConstrainToPlane(MoveComp.WorldUp));
				float AngleDot = MoveComp.SyncedMovementInputForAnimationOnly.DotProduct(Player.ActorRightVector.ConstrainToPlane(MoveComp.WorldUp));

				//Then clamp our Angle in the Blendspace range
				AngleDiff *= Math::Sign(AngleDot);
				SlideComp.TurnAngle = Math::Clamp(AngleDiff, -90, 90);
			}
			else
			{
				//If we are sliding in a specific direction then just intrepret our sideways input as an Angle
				SlideComp.TurnAngle = MoveComp.SyncedMovementInputForAnimationOnly.DotProduct(Slope.SlopeRight) * 90;
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Slide");
		}
	}
};
