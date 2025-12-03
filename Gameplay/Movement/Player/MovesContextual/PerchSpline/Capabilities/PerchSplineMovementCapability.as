

class UPlayerPerchSplineMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointSpline);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);
	
	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 4;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerAirMotionComponent AirMotionComp;

	bool bHasBroadcastLandEvent = false;
	bool bBlockedAirMoves = false;

	float CurrentSpeed;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Player.ActorForwardVector;

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bBlockedAirMoves)
		{
			Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
			Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
			bBlockedAirMoves = false;
		}

		MoveComp.ClearCustomMovementStatus(this);

		if (PerchComp.bIsLandingOnSpline)
		{
			PerchComp.bIsLandingOnSpline = false;
			Player.RootOffsetComponent.ResetOffsetWithLerp(this, 0.2);
		}

		bHasBroadcastLandEvent = false;

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		bool bFakeAirborne = false;
		float VerticalDistanceToSpline = 0;
		FVector SplineForward;
		if (IsValid(PerchComp.Data.ActiveSpline))
		{
			float SplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
			FVector SplineLocation = PerchComp.Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
			VerticalDistanceToSpline = (Player.ActorLocation - SplineLocation).DotProduct(MoveComp.WorldUp);

			float FakeGroundedDistance = 10.0;
			FakeGroundedDistance += MoveComp.GetVerticalVelocity().Size() * DeltaTime;
			FakeGroundedDistance += MoveComp.GetGravityForce() * DeltaTime * DeltaTime * 0.5;
			SplineForward = PerchComp.Data.ActiveSpline.Spline.GetWorldForwardVectorAtSplineDistance(SplineDistance);

			TEMPORAL_LOG(this)
				.Value("VerticalDistanceToSpline", VerticalDistanceToSpline)
				.Value("FakeGroundedDistance", FakeGroundedDistance)
			;

			bFakeAirborne = Math::Abs(VerticalDistanceToSpline) > FakeGroundedDistance && !MoveComp.HasGroundContact();
		}

		if (!bFakeAirborne)
			MoveComp.ApplyCustomMovementStatus(n"Perching", this);
		else
			MoveComp.ClearCustomMovementStatus(this);

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MoveInput = MoveComp.MovementInput;

				// Fall, but don't allow falling below the spline
				float VerticalVelocity = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
				float VerticalDelta = VerticalVelocity * DeltaTime;
				VerticalDelta -= MoveComp.GetGravityForce() * DeltaTime * DeltaTime * 0.5;
				VerticalVelocity -= MoveComp.GetGravityForce() * DeltaTime;

				if (VerticalDelta < -VerticalDistanceToSpline)
				{
					VerticalDelta = -VerticalDistanceToSpline;
					VerticalVelocity = 0.0;
				}

				// If we're grounded but hovering very slightly above the spline, don't move down to the spline,
				// this is to prevent vibrating the position into penetrating geometry.
				if (MoveComp.HasGroundContact() && VerticalDelta > 0.0 && VerticalDelta < 10.0)
					VerticalDelta = 0.0;

				Movement.AddDeltaWithCustomVelocity(MoveComp.WorldUp * VerticalDelta, MoveComp.WorldUp * VerticalVelocity);

				if (bFakeAirborne)
				{

					FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
						MoveComp.MovementInput,
						MoveComp.HorizontalVelocity,
						DeltaTime,
					);
					Movement.AddHorizontalVelocity(AirControlVelocity);

					CurrentSpeed = MoveComp.HorizontalVelocity.Size();
					Direction = Player.ActorForwardVector;
				}
				else
				{
					MoveComp.ApplyCustomMovementStatus(n"Perching", this);

					if(!bHasBroadcastLandEvent)
					{
						if(IsValid(PerchComp.Data.ActiveSpline))
							PerchComp.Data.ActiveSpline.OnPlayerLandedOnSpline.Broadcast(Player);
						
						bHasBroadcastLandEvent = true;
					}

					FVector TargetDirection = MoveComp.MovementInput;
					float InputSize = MoveComp.MovementInput.Size();

					float MaxSpeedMultiplier = 1;
					//Enforces Deadzone + Speed limiting zone based on angular delta away from spline
					EnforceInputZones(MoveComp.NonLockedMovementInput, InputSize, MoveInput, MaxSpeedMultiplier);
					PerchComp.Data.bHasValidInput = !MoveInput.IsNearlyZero();

					Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

					//If we hit minimum speed or stop then disable sprint
					if(MoveComp.HorizontalVelocity.Size() <= PerchComp.Settings.MinSpeed && SprintComp.IsSprintToggled())
						SprintComp.SetSprintToggled(false);

					float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
					float TargetSpeed = Math::Lerp(PerchComp.Settings.MinSpeed, Math::Max((SprintComp.IsSprintToggled() ? PerchComp.Settings.MaxSprintSpeed : PerchComp.Settings.MaxSpeed) * MaxSpeedMultiplier, PerchComp.Settings.MinSpeed), SpeedAlpha);

					// Calculate the target speed
					TargetSpeed *= MoveComp.MovementSpeedMultiplier;

					if(InputSize < KINDA_SMALL_NUMBER)
						TargetSpeed = 0.0;
				
					// Update new velocity
					float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
					if(TargetSpeed < CurrentSpeed)
						InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
					CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
					FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;

					// If we aren't actually grounded and we're going down, put the velocity on the spline's direction so we get the angle right
					if (!MoveComp.HasGroundContact() && !SplineForward.IsNearlyZero())
					{
						FVector ConstrainedVelocity = HorizontalVelocity.ConstrainToDirection(SplineForward).GetSafeNormal() * HorizontalVelocity.Size();
						if (ConstrainedVelocity.DotProduct(MoveComp.WorldUp) < 0)
							HorizontalVelocity = ConstrainedVelocity;
					}

					Movement.AddHorizontalVelocity(HorizontalVelocity);

					if (IsDebugActive())
					{
						PrintToScreenScaled("Vel: " + Player.GetActorRotation().UnrotateVector(MoveComp.HorizontalVelocity) + " | " + Math::RoundToFloat(MoveComp.HorizontalVelocity.Size()));
						PrintToScreenScaled("SpeedAlpha: " + SpeedAlpha);
						PrintToScreenScaled("TargetSpeed: " + TargetSpeed);
					}
				}

				if ((!PerchComp.bIsLandingOnSpline || !bFakeAirborne) && PerchComp.Data.bHasValidInput)
					Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();

				FVector MoveInput = MoveComp.SyncedMovementInputForAnimationOnly;
				float InputSize = MoveInput.Size();
				float MaxSpeedMultiplier = 1;

				EnforceInputZones(MoveInput, InputSize, MoveInput, MaxSpeedMultiplier);

				PerchComp.Data.bHasValidInput = !MoveInput.IsNearlyZero();
			}
		
			MoveComp.ApplyMove(Movement);

			if(IsValid(PerchComp.Data.ActiveSpline))
				PerchComp.Data.CurrentSplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

			if(Player.Mesh.CanRequestLocomotion())
			{
				if (bFakeAirborne)
					Player.Mesh.RequestLocomotion(n"AirMovement", this);
				else
					Player.Mesh.RequestLocomotion(n"Perch", this);
			}
		}

		Player.SetBlendSpaceValues(MoveComp.SyncedMovementInputForAnimationOnly.X, MoveComp.SyncedMovementInputForAnimationOnly.Y);

		//Calculate Lean anim data
		if(MoveComp.HasCustomMovementStatus(n"Perching"))
			CalculateAdditiveLeanAndSlopeAngle(DeltaTime);

		//Check if we have reached the spline ends and set animation data accordingly (stop animating walk when ends are reached)
		const float END_DISTANCE_MARGIN = 20.0;
		if(IsValid(PerchComp.Data.ActiveSpline))
		{
			if(!PerchComp.Data.ActiveSpline.StartZoneSettings.bAllowRunningOffEdge
				&& PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) < END_DISTANCE_MARGIN
					&& Math::RadiansToDegrees(MoveComp.GetNonLockedMovementInput().AngularDistance(-PerchComp.Data.ActiveSpline.Spline.GetWorldTangentAtSplineDistance(PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation)))) < 90.0)
			{
				PerchComp.AnimData.bReachedEndOfSpline	= true;
			}
			else if (!PerchComp.Data.ActiveSpline.EndZoneSettings.bAllowRunningOffEdge
						&& PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) >= (PerchComp.Data.ActiveSpline.Spline.SplineLength - END_DISTANCE_MARGIN)
							&& Math::RadiansToDegrees(MoveComp.GetNonLockedMovementInput().AngularDistance(PerchComp.Data.ActiveSpline.Spline.GetWorldTangentAtSplineDistance(PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation)))) < 90.0)
			{
				PerchComp.AnimData.bReachedEndOfSpline = true;
			}
			else
				PerchComp.AnimData.bReachedEndOfSpline = false;
		}

		// When we start landing on the spline we need to do some extra lerping on the mesh.
		// We can't use the offset component for this lerping as a smooth teleport, because we want to
		// treat the vertical and the horizontal components separately:
		// Horizontal offset lerps out as a smooth teleport, vertical offset follows gravity.
		if (PerchComp.bIsLandingOnSpline)
		{
			// Lerp the offset to the real actor location
			FVector Offset = PerchComp.SplineLandStartOffset;
			// if (PerchComp.bSplineLandWasAirbone)
			// 	Offset += PerchComp.SplineLandStartVelocity * ActiveDuration;

			float Alpha = ActiveDuration / 0.3;
			FVector LerpedOffset = Math::Lerp(Offset, FVector::ZeroVector, Math::Saturate(Alpha));
			FVector MeshLocation = Player.ActorLocation + LerpedOffset;

			if (Alpha >= 1.0 || Player.ActorLocation.Equals(MeshLocation, 1.0))
			{
				Player.RootOffsetComponent.ClearOffset(this);
				PerchComp.bIsLandingOnSpline = false;
			}
			else
			{
				Player.RootOffsetComponent.SnapToLocation(this, MeshLocation);
			}
		}

		if (!bBlockedAirMoves && !PerchComp.bIsLandingOnSpline && !bFakeAirborne)
		{
			Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
			Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
			bBlockedAirMoves = true;

			//Reset Movement uses
			Player.ResetAirJumpUsage();
			Player.ResetAirDashUsage();
			Player.ResetWallScrambleUsage();
			Player.ResetPlayerWallRunUsage();
		}
	}

	//Enforces a deadzone and limits the max speed when inputting away from the given forward angular margin (based on the angular delta)
	void EnforceInputZones(FVector NonLockedMovementInput, float& InputSize, FVector& MoveInput, float& MaxSpeedMultiplier) const
	{
		if(!IsValid(PerchComp.Data.ActiveSpline))
			return;

		/**
		 * Thought:
		 * 	- Having the option to disable this deadzone behavior completely on the splines themselves?
		 */

		UHazeSplineComponent Spline = PerchComp.Data.ActiveSpline.Spline;
		FVector SplineTangent = Spline.GetWorldForwardVectorAtSplineDistance(Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation));
		const float SplineAlignedAngularDelta = NonLockedMovementInput.GetAngleDegreesTo(SplineTangent.GetSafeNormal());

		//Only check deadzones if we are actually "grounded" on the spline
		if (MoveComp.HasCustomMovementStatus(n"Perching") && (SplineAlignedAngularDelta > PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE && SplineAlignedAngularDelta < (180 - PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE)))
		{
			InputSize = 0;
			MoveInput.X = 0;
			MoveInput.Y = 0;
		}

		//Only clamp our max speed if we are "grounded" on the spline
		if(MoveComp.HasCustomMovementStatus(n"Perching"))
		{
			if (SplineAlignedAngularDelta <= PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE && SplineAlignedAngularDelta > PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE)
			{
				MaxSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE, PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE), FVector2D(1, 0), SplineAlignedAngularDelta);
			}
			else if (SplineAlignedAngularDelta >= 180 - PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE && SplineAlignedAngularDelta < (180 - PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE))
			{
				MaxSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE, 0), FVector2D(1, 0), (SplineAlignedAngularDelta - (180 - PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE)));
			}
		}
		else
			MaxSpeedMultiplier = 1;
		
#if EDITOR
		if(IsDebugActive())
		{
			/**
			 * NOTE:
			 * Debugging is only calibrated for the current values in Perch Settings, there is probably a formula to calculate the angles dynamically but ¯\_(ツ)_/¯
			 */

			Debug::DrawDebugArc(PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE * 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal(), FLinearColor::Green, 2, MoveComp.WorldUp);
			Debug::DrawDebugArc(PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE * 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal() * -1, FLinearColor::Green, 2, MoveComp.WorldUp);
			Debug::DrawDebugArc((PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE) - 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal().RotateAngleAxis(-(PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - (PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE / 2)), MoveComp.WorldUp), FLinearColor::Yellow, 1, MoveComp.WorldUp);
			Debug::DrawDebugArc((PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE) - 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal().RotateAngleAxis((PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - (PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE / 2)), MoveComp.WorldUp), FLinearColor::Yellow, 1, MoveComp.WorldUp);
			Debug::DrawDebugArc((PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE) - 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal().RotateAngleAxis(-(PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE + PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE), MoveComp.WorldUp), FLinearColor::Yellow, 1, MoveComp.WorldUp);
			Debug::DrawDebugArc((PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE - PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE) - 2, Player.ActorLocation, 150,  SplineTangent.GetSafeNormal().RotateAngleAxis(PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE + PerchComp.Settings.PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE, MoveComp.WorldUp), FLinearColor::Yellow, 1, MoveComp.WorldUp);
			Debug::DrawDebugArc(180 - PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE * 2, Player.ActorLocation, 150,  MoveComp.WorldUp.CrossProduct(SplineTangent.GetSafeNormal()), FLinearColor::Red, 1, MoveComp.WorldUp);
			Debug::DrawDebugArc(180 - PerchComp.Settings.PERCH_MOVEMENT_DEADZONE_ANGLE * 2, Player.ActorLocation, 150,  MoveComp.WorldUp.CrossProduct(SplineTangent.GetSafeNormal()) * -1, FLinearColor::Red, 1, MoveComp.WorldUp);
			Debug::DrawDebugDirectionArrow(Player.ActorLocation, MoveComp.GetNonLockedMovementInput().GetSafeNormal(), 150, LineColor = FLinearColor::Black);
		}
#endif
	}

	void CalculateAdditiveLeanAndSlopeAngle(float DeltaTime)
	{
		if(!IsValid(PerchComp.Data.ActiveSpline))
			return;

		//NOTES:
		//Might want to add this for spline dash aswell?
		// Instead of animating head / lerping out the alpha for lookat camera direction we could just add another lookat towards the spline position we are polling for our tangent

		FVector AheadPointLocation;
		UHazeSplineComponent Spline = PerchComp.Data.ActiveSpline.Spline;
		bool bReversingOnSpline = (MoveComp.HorizontalVelocity.Size() > KINDA_SMALL_NUMBER ? MoveComp.HorizontalVelocity.GetSafeNormal() : Player.ActorForwardVector).DotProduct(Spline.GetWorldForwardVectorAtSplineDistance(Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation))) >= 0;

		PerchComp.AnimData.LeanAlpha = MoveComp.HorizontalVelocity.Size() / ((SprintComp.IsSprintToggled() ? PerchComp.Settings.MaxSprintSpeed : PerchComp.Settings.MaxSpeed));

		//Look ahead polling point modulated by our Velocity
		const float PollPointDelta = 100 + (100 * PerchComp.AnimData.LeanAlpha);
		
		//Calculate our horizontal Angular delta
		AheadPointLocation = Spline.GetWorldLocationAtSplineDistance(Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) + (bReversingOnSpline ? PollPointDelta : -PollPointDelta));
		FVector AheadPointTangent = Spline.GetWorldTangentAtSplineDistance((Spline.GetClosestSplineDistanceToWorldLocation(AheadPointLocation))) * (bReversingOnSpline ? 1 : -1);
		FVector HorizontalAheadTangent = AheadPointTangent.ConstrainToPlane(MoveComp.WorldUp);
		float HorizontalAngularDelta = Math::RadiansToDegrees(Player.ActorForwardVector.AngularDistanceForNormals(HorizontalAheadTangent.GetSafeNormal()));
		HorizontalAngularDelta = HorizontalAngularDelta * (Player.ActorRightVector.DotProduct(HorizontalAheadTangent) >= 0 ? 1 : -1);

		//Set our animation values for lean
		float TargetLeanValue = Math::GetMappedRangeValueClamped(FVector2D(-45, 45), FVector2D(-0.8, .8), HorizontalAngularDelta);
		PerchComp.AnimData.AdditiveLean = Math::FInterpConstantTo(PerchComp.AnimData.AdditiveLean, TargetLeanValue, DeltaTime, 20); 

		//Calculate our vertical Angular delta
		FVector SplinePlayerLocationTangent = Spline.GetWorldTangentAtSplineDistance(Spline.GetClosestSplineDistanceToRelativeLocation(Player.ActorLocation)).GetSafeNormal() * (bReversingOnSpline ? 1 : -1);
		FVector ConstrainedPlayerLocationTangent = SplinePlayerLocationTangent.ConstrainToPlane(SplinePlayerLocationTangent.CrossProduct(MoveComp.WorldUp)).GetSafeNormal();
		float VerticalAngularDelta = Math::RadiansToDegrees(SplinePlayerLocationTangent.ConstrainToPlane(MoveComp.WorldUp).ConstrainToPlane(SplinePlayerLocationTangent.CrossProduct(MoveComp.WorldUp)).GetSafeNormal().AngularDistanceForNormals(ConstrainedPlayerLocationTangent));
		VerticalAngularDelta = VerticalAngularDelta * (MoveComp.WorldUp.DotProduct(ConstrainedPlayerLocationTangent) >= 0 ? 1 : -1);

		//Set our animation value for vertical slope
		PerchComp.AnimData.VerticalSlopeAngle = VerticalAngularDelta;

#if EDITOR
		if (IsDebugActive())
		{
			Debug::DrawDebugSphere(AheadPointLocation, 10, Thickness = 1, LineColor = FLinearColor::LucBlue);
			Debug::DrawDebugString(AheadPointLocation + MoveComp.WorldUp * 15, "Lean: " + PerchComp.AnimData.AdditiveLean, Color = FLinearColor::Yellow, Alignment = FVector2D(0.5, 1));
		}
#endif
	}
}
