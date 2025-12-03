class UPlayerFairyMoveSplineMovementCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 2;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairyComponent FairyComp;
	UTeleportingMovementData Movement;
	UTundraPlayerFairySettings Settings;
	UTundraFairyMoveSplineContainer MoveSplineContainer;
	UCameraUserComponent CameraUser;
	UHazeCrumbSyncedVectorComponent SyncedWorldPivotOffset;

	UHazeSplineComponent Spline;
	ATundraFairyMoveSpline CurrentMoveSpline;
	float CurrentSpeed = 0.0;
	bool bIsMagnetizing = false;
	float MagnetizingSpeed = 0.0;

	// Current torque is in degrees
	float CurrentTorque = 0.0;
	bool bReachedEnd = false;
	bool bFlipTravelDirection = false;
	bool bClockwiseTorque = true;
	FTransform PreviousTransform;
	float CurrentAngle;

	// Additional torque will be applied to make sure the angle of the player when exiting the spline will always result in a upwards inherited velocity
	float AdditionalTorqueInRadians;

	UCameraPointOfInterest POI;
	bool bPoiActive = false;
	FVector InterpedCameraInputVector = FVector();
	bool bCameraApplied = false;

	const float CameraBlendInDuration = 0.5;

	// Purely debug stuff
	TArray<FVector> SpiralLocationDebugLog;
	float TimeOfLastLog = -100.0;
	const float DebugLogDelay = 0.03;
	bool bCameraControlBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		MoveSplineContainer = UTundraFairyMoveSplineContainer::GetOrCreate(Game::Zoe);
		CameraUser = UCameraUserComponent::Get(Player);

		SyncedWorldPivotOffset = UHazeCrumbSyncedVectorComponent::Create(Player, n"FairyMoveSplineMovementCapability_SyncedWorldPivotOffset");
		SyncedWorldPivotOffset.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraFairyMoveSplineMovementActivatedParams& Params) const
	{
		if(!FairyComp.bIsActive)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveSplineContainer == nullptr)
			return false;

		for(auto Current : MoveSplineContainer.MoveSplines)
		{
			FVector ClosestPoint;
			float SplineDistance;
			if(Current.IsLocationWithinSnapToRange(Player.ActorCenterLocation, ClosestPoint, SplineDistance))
			{
				FTransform CurrentTransform = Current.Spline.GetWorldTransformAtSplineDistance(SplineDistance);

				if(Current == CurrentMoveSpline && DeactiveDuration < 0.5)
					return false;

				float InitialProjectedSpeed = MoveComp.Velocity.DotProduct(CurrentTransform.Rotation.ForwardVector);
				Params.bFlipTravelDirection = Current.bTwoWay && InitialProjectedSpeed < 0.0;
				Params.MoveSpline = Current;

				if(Current.bInheritVelocity)
					Params.InitialSpeed = Current.bTwoWay ? Math::Abs(InitialProjectedSpeed) : InitialProjectedSpeed;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsActive)
			return true;

		if(bReachedEnd)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveSplineContainer == nullptr)
			return true;

		if(CurrentMoveSpline == nullptr)
			return true;

		if(!CurrentMoveSpline.IsLocationWithinSnapToRange(Player.ActorCenterLocation))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraFairyMoveSplineMovementActivatedParams Params)
	{
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.PlayCameraShake(FairyComp.LoopingMoveSplineCameraShake, this);
		Player.PlayForceFeedback(FairyComp.LoopingMoveSplineForceFeedback, true, false, this);

		Spline = Params.MoveSpline.Spline;
		CurrentMoveSpline = Params.MoveSpline;
		bFlipTravelDirection = Params.bFlipTravelDirection;
		bIsMagnetizing = true;
		bClockwiseTorque = CurrentMoveSpline.bClockwiseTorque;
		bReachedEnd = false;
		MagnetizingSpeed = CurrentMoveSpline.MagneticSnapToStartSpeed;
		InterpedCameraInputVector = FVector();

		if(ShouldApplyCamera())
			ApplyCamera();

		// Force player out of leap
		Player.BlockCapabilities(TundraShapeshiftingTags::TundraLeap, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::TundraLeap, this);

		FairyComp.ResetLeap();

		FairyComp.bIsOnMoveSpline = true;
		FairyComp.CurrentMoveSpline = CurrentMoveSpline;

		PreviousTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
		FVector RelativePlayerLocation = PreviousTransform.InverseTransformPosition(Player.ActorCenterLocation);

		CurrentAngle = Math::DirectionToAngleRadians(FVector2D(RelativePlayerLocation.Z, RelativePlayerLocation.Y));

		CurrentSpeed = Math::Max(Params.InitialSpeed, CurrentMoveSpline.StartingImpulse);
		CurrentSpeed = Math::Min(CurrentSpeed, CurrentMoveSpline.MaxSpeed);

		float SpeedProjectedOnRight = PreviousTransform.Rotation.RightVector.DotProduct(MoveComp.Velocity);

		if(!CurrentMoveSpline.bUseStaticStartTorque)
		{
			FVector NextPlayerLocation = Player.ActorCenterLocation + MoveComp.Velocity;
			FVector RelativeNextPlayerLocation = PreviousTransform.InverseTransformPosition(NextPlayerLocation);
			float NextPlayerAngle = Math::DirectionToAngleRadians(FVector2D(RelativeNextPlayerLocation.Z, RelativeNextPlayerLocation.Y));
			float DeltaAngleDeg = Math::RadiansToDegrees(Math::FindDeltaAngleRadians(CurrentAngle, NextPlayerAngle));
			CurrentTorque = Math::Abs(DeltaAngleDeg);
		}
		else
		{
			CurrentTorque = CurrentMoveSpline.StartTorque;
		}

		if((RelativePlayerLocation.Z > 0.0 && SpeedProjectedOnRight < 0.0) || (RelativePlayerLocation.Z < 0.0 && SpeedProjectedOnRight > 0.0))
			bClockwiseTorque = false;

		CurrentTorque = Math::Min(CurrentTorque, CurrentMoveSpline.SpiralMaxTorque);

		if(FairyComp.CameraSettingsInMoveSpline != nullptr)
		{
			Player.ApplyCameraSettings(FairyComp.CameraSettingsInMoveSpline, 2, this, SubPriority = 62);
		}

		UTundraPlayerFairyEffectHandler::Trigger_OnEnterMoveSpline(FairyComp.FairyActor, FTundraPlayerFairyMoveSplineEnterParams(Params.MoveSpline));
		UPlayerFairyMoveSplineEffectHandler::Trigger_OnFairyEnter(CurrentMoveSpline);

		CurrentMoveSpline.OnFairyEnter();

		CalculateAdditionalTorque();

		TimeOfLastLog = -100.0;
		SpiralLocationDebugLog.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		
		Player.StopCameraShakeByInstigator(this);
		Player.StopForceFeedback(this);
		Player.PlayCameraShake(FairyComp.ExitMoveSplineCameraShake, this);
		Player.PlayForceFeedback(FairyComp.ExitMoveSplineForceFeedback, false, false, this);

		CameraUser.CameraSettings.WorldPivotOffset.Clear(this, CameraBlendInDuration);

		if(!FairyComp.bSwitchingSpline)
			Player.ClearCameraSettingsByInstigator(this);
		
		UTundraPlayerFairyEffectHandler::Trigger_OnExitMoveSpline(FairyComp.FairyActor);
		UPlayerFairyMoveSplineEffectHandler::Trigger_OnFairyExit(CurrentMoveSpline);

		CurrentMoveSpline.OnFairyExit();

		if(bCameraApplied)
			ClearCamera();

		FairyComp.bIsOnMoveSpline = false;
		FairyComp.CurrentMoveSpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldApplyCamera() && !bCameraApplied)
			ApplyCamera();
		else if(!ShouldApplyCamera() && bCameraApplied)
			ClearCamera();

		if(bCameraApplied)
			UpdateCamera(DeltaTime);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				CurrentSpeed += CurrentMoveSpline.Acceleration * DeltaTime;
				CurrentSpeed = Math::Min(CurrentSpeed, CurrentMoveSpline.MaxSpeed);

				float CurrentMoveDelta = CurrentSpeed * DeltaTime;
				float TotalSplineLength = Spline.GetSplineLength();

				float CurrentSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
				FTransform CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
				FVector CurrentSplineLocation = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * CurrentMoveSpline.HeightOffset;
				PreviousTransform = CurrentSplineTransform;

				float TargetSplineDistance = CurrentSplineDistance + CurrentMoveDelta * (bFlipTravelDirection ? -1 : 1);
				FTransform TargetSplineTransform = Spline.GetWorldTransformAtSplineDistance(TargetSplineDistance);
				FVector TargetSplineLocation = TargetSplineTransform.Location + TargetSplineTransform.Rotation.UpVector * CurrentMoveSpline.HeightOffset;
				FairyComp.CurrentSplineLocation = TargetSplineLocation;
				FairyComp.CurrentSplineDistance = TargetSplineDistance;

				if(HasReachedEndOfSpline(DeltaTime, TargetSplineDistance, TotalSplineLength))
				{
					if(bFlipTravelDirection)
						TargetSplineTransform = FTransform(FRotator::MakeFromXZ(-TargetSplineTransform.Rotation.ForwardVector, TargetSplineTransform.Rotation.UpVector), TargetSplineTransform.Location, TargetSplineTransform.Scale3D);

					Movement.AddVelocity(TargetSplineTransform.TransformVector(CurrentMoveSpline.JumpOffLocalImpulse + FVector::ForwardVector * Math::Max(0.0, CurrentSpeed)));
					bReachedEnd = true;

					if(IsDebugActive())
					{
						Print(f"Actual final angle: {Math::RadiansToDegrees(CurrentAngle)}");
						Print(f"Actual spline time: {ActiveDuration}");
					}
				}
				else
					Movement.AddDelta(TargetSplineLocation - CurrentSplineLocation);

				if(!bReachedEnd)
				{
					FVector RelPlayerLocation = CurrentSplineTransform.InverseTransformPosition(Player.ActorCenterLocation);

					// This is the spline transform, but if we are at the beginning or the end of the move spline we aren't actually on the spline yet so this will be offset accordingly.
					FTransform CorrectedCurrentSplineTransform = FTransform(CurrentSplineTransform.Rotation, CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.ForwardVector * RelPlayerLocation.X, CurrentSplineTransform.Scale3D);

					// Rotate the player to follow the spline
					if(!Math::IsNearlyEqual(CurrentSplineTransform.Rotation.ForwardVector.Z, 1.0))
						Movement.InterpRotationTo((CurrentSplineTransform.Rotation.ForwardVector * (bFlipTravelDirection ? -1 : 1)).ToOrientationQuat(), Settings.FairyRotationInterpSpeed);

					if(CurrentMoveSpline.bUseSpiralMovement && CurrentSplineDistance < TotalSplineLength)
					{
						HandleSpiralMovement(DeltaTime, CurrentMoveDelta, CurrentSplineDistance, TargetSplineDistance, CorrectedCurrentSplineTransform);
					}
					else if(bIsMagnetizing)
					{
						FVector MagneticTargetLocation = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * CurrentMoveSpline.HeightOffset;
						float MagneticMaxDelta = (MagneticTargetLocation - Player.ActorCenterLocation).Size();
						MagnetizingSpeed += CurrentMoveSpline.MagneticSnapToAcceleration * DeltaTime;

						float CurrentMagneticDelta = MagnetizingSpeed * DeltaTime;
						if(CurrentMagneticDelta > MagneticMaxDelta)
						{
							CurrentMagneticDelta = MagneticMaxDelta;
							bIsMagnetizing = false;
						}
						Movement.AddDelta((MagneticTargetLocation - Player.ActorCenterLocation).GetSafeNormal() * CurrentMagneticDelta);
					}
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"FairyWindTunnel");

			if(HasControl())
			{
				FTransform CurrentSplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
				FVector RelPlayerLocation = CurrentSplineTransform.InverseTransformPosition(Player.ActorCenterLocation);
				FTransform CorrectedCurrentSplineTransform = FTransform(CurrentSplineTransform.Rotation, CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.ForwardVector * RelPlayerLocation.X, CurrentSplineTransform.Scale3D);
				SyncedWorldPivotOffset.Value = (CorrectedCurrentSplineTransform.Location - Player.ActorLocation) * Math::Min(ActiveDuration / CameraBlendInDuration, 1.0);
			}

			CameraUser.CameraSettings.WorldPivotOffset.ApplyAsAdditive(SyncedWorldPivotOffset.Value, this);
		}
	}

	void ApplyCamera()
	{
		if(!bCameraControlBlocked && CurrentMoveSpline.CameraMode != ETundraFairyMoveSplineCameraMode::FreeButFollowsTurns)
		{
			Player.BlockCapabilities(CameraTags::CameraControl, this);
			bCameraControlBlocked = true;
		}

		if(CurrentMoveSpline.CameraMode == ETundraFairyMoveSplineCameraMode::PointOfInterest ||
			CurrentMoveSpline.CameraMode == ETundraFairyMoveSplineCameraMode::PointOfInterestWithStick)
		{
			POI = Player.CreatePointOfInterest();
			POI.Settings.TurnScaling = FRotator(Settings.PointOfInterestSpeedMultiplier, Settings.PointOfInterestSpeedMultiplier, Settings.PointOfInterestSpeedMultiplier);
			POI.FocusTarget.SetFocusToComponent(CurrentMoveSpline.SwitchTargetableActor.Targetable);
			POI.Apply(this, CurrentMoveSpline.CameraBlendInDuration);
			bPoiActive = true;
		}

		bCameraApplied = true;
	}

	void ClearCamera()
	{
		if(bCameraControlBlocked && !FairyComp.bSwitchingSpline)
		{
			Player.UnblockCapabilities(CameraTags::CameraControl, this);
			bCameraControlBlocked = false;
		}

		if(bPoiActive)
		{
			POI.Clear();
			bPoiActive = false;
		}

		bCameraApplied = false;
	}

	bool HasReachedEndOfSpline(float DeltaTime, float TargetSplineDistance, float TotalSplineLength)
	{
		return (!bFlipTravelDirection && TargetSplineDistance > TotalSplineLength) || (bFlipTravelDirection && TargetSplineDistance <= 0.0);
	}

	void HandleSpiralMovement(float DeltaTime, float CurrentMoveDelta, float CurrentSplineDistance, float TargetSplineDistance, FTransform CorrectedCurrentSplineTransform)
	{
		HandleSpiralDebug();

		float TargetRadius = Math::Lerp(CurrentMoveSpline.StartSpiralRadius, CurrentMoveSpline.EndSpiralRadius, Math::Min(ActiveDuration / CurrentMoveSpline.SpiralRadiusLerpDuration, 1.0));
		float CurrentRadius = CorrectedCurrentSplineTransform.Location.Distance(Player.ActorCenterLocation);

		if(IsDebugActive())
			PrintToScreen(f"{CurrentRadius=}");

		if(bIsMagnetizing)
		{
			MagnetizingSpeed += CurrentMoveSpline.MagneticSnapToAcceleration * DeltaTime;
			if(CurrentRadius > TargetRadius)
			{
				CurrentRadius -= MagnetizingSpeed * DeltaTime;
				if(CurrentRadius < TargetRadius)
				{
					CurrentRadius = TargetRadius;
					bIsMagnetizing = false;
				}
			}
			else
			{
				CurrentRadius += MagnetizingSpeed * DeltaTime;
				if(CurrentRadius > TargetRadius)
				{
					CurrentRadius = TargetRadius;
					bIsMagnetizing = false;
				}
			}
		}
		else
		{
			CurrentRadius = TargetRadius;
		}

		// How many percent of the move is allowed before reaching end of spline
		float TorqueApplicationMultiplier = 1.0;
		if(TargetSplineDistance > Spline.SplineLength)
			TorqueApplicationMultiplier = (Spline.SplineLength - CurrentSplineDistance) / CurrentMoveDelta;

		if(!CurrentMoveSpline.bStartAcceleratingTorqueWhenReachingTargetRadius || !bIsMagnetizing)
		{
			CurrentTorque += CurrentMoveSpline.SpiralTorqueAcceleration * DeltaTime;
			CurrentTorque = Math::Min(CurrentTorque, CurrentMoveSpline.SpiralMaxTorque);
		}
		
		CurrentAngle += Math::DegreesToRadians(CurrentTorque) * DeltaTime * (bClockwiseTorque ? 1 : -1) * TorqueApplicationMultiplier;
		CurrentAngle += AdditionalTorqueInRadians * DeltaTime * (bClockwiseTorque ? 1 : -1) * TorqueApplicationMultiplier;
		CurrentAngle = Math::UnwindRadians(CurrentAngle);

		FVector2D AngleVec = Math::AngleRadiansToDirection(CurrentAngle);
		FVector Direction = CorrectedCurrentSplineTransform.TransformVector(FVector(0.0, AngleVec.Y, AngleVec.X));
		FVector SpiralTargetLocation = CorrectedCurrentSplineTransform.Location + Direction * CurrentRadius;

		FVector Delta = SpiralTargetLocation - Player.ActorCenterLocation;
		FVector ClosestPoint;
		float SplineDistance;
		if(!CurrentMoveSpline.IsLocationWithinSnapToRange(SpiralTargetLocation, ClosestPoint, SplineDistance))
		{
			float Dist = ClosestPoint.Distance(SpiralTargetLocation);
			if(Dist > CurrentMoveSpline.MagneticSnapToRange)
			{
				float CorrectionalDistance = Dist - CurrentMoveSpline.MagneticSnapToRange + KINDA_SMALL_NUMBER;
				Delta += (ClosestPoint - SpiralTargetLocation).GetSafeNormal() * CorrectionalDistance;
			}
		}
		Movement.AddDeltaWithCustomVelocity(Delta, (Delta / DeltaTime) * CurrentMoveSpline.InheritedTorqueVelocityMultiplier);
	}

	void HandleSpiralDebug()
	{
		if(!IsDebugActive())
			return;

		const float Time = Time::GetGameTimeSeconds();

		if(Time - TimeOfLastLog > DebugLogDelay)
		{
			SpiralLocationDebugLog.Add(Player.ActorLocation);
			TimeOfLastLog = Time;
		}

		if(SpiralLocationDebugLog.Num() < 2)
			return;

		for(int i = 0; i < SpiralLocationDebugLog.Num() - 1; i++)
		{
			Debug::DrawDebugLine(SpiralLocationDebugLog[i], SpiralLocationDebugLog[i + 1], FLinearColor::Red);
		}
	}

	void UpdateCamera(float DeltaTime)
	{
		float CurrentSplineDistance = CurrentMoveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
		FTransform CurrentSplineTransform = CurrentMoveSpline.Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
		FVector RelativePlayerLocation = CurrentSplineTransform.InverseTransformPosition(Player.ActorCenterLocation);

		if(CurrentMoveSpline.CameraMode == ETundraFairyMoveSplineCameraMode::FreeButFollowsTurns)
		{
			// Make the camera's rotation follow the move spline when turning (but ignore pitch)
			FRotator DeltaRotation = PreviousTransform.InverseTransformRotation(CurrentSplineTransform.Rotation).Rotator();
			DeltaRotation.Pitch = 0.0;

			CameraUser.AddDesiredRotation(DeltaRotation, this);
		}
		else
		{
			float TargetSplineDistance = CurrentSplineDistance + (Settings.PointOfInterestOffset + CurrentSpeed * DeltaTime + RelativePlayerLocation.X) * (bFlipTravelDirection ? -1 : 1);
			FTransform TargetTransform = CurrentMoveSpline.Spline.GetWorldTransformAtSplineDistance(TargetSplineDistance);

			float AdditionalDistance = 0.0;
			if(TargetSplineDistance < 0.0)
				AdditionalDistance = TargetSplineDistance;
			else if(TargetSplineDistance > CurrentMoveSpline.Spline.SplineLength)
				AdditionalDistance = TargetSplineDistance - CurrentMoveSpline.Spline.SplineLength;

			FVector FinalSplineLocation = TargetTransform.Location + TargetTransform.Rotation.ForwardVector * AdditionalDistance;
			FVector CurrentWorldOffset;

			if(CurrentMoveSpline.CameraMode == ETundraFairyMoveSplineCameraMode::PointOfInterestWithStick)
			{
				// Handle turn offset
				FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
				FVector CameraInput3D = FVector(0.0, CameraInput.X, CameraInput.Y);
				InterpedCameraInputVector = Math::VInterpTo(InterpedCameraInputVector, CameraInput3D, DeltaTime, Settings.PointOfInterestTurnOffsetInterpSpeed);

				float RadiansToOffset = Math::DegreesToRadians(InterpedCameraInputVector.Size() * Settings.PointOfInterestMaxTurnOffsetInDegrees);
				float DistanceOffset = Math::Tan(RadiansToOffset) * Player.ActorCenterLocation.Distance(FinalSplineLocation);

				// The current local offset of the poi in the players local space
				FVector CurrentLocalOffset = InterpedCameraInputVector * DistanceOffset;
				CurrentWorldOffset = FTransform::MakeFromXZ((FinalSplineLocation - Player.ActorCenterLocation).GetSafeNormal(), FVector::UpVector).TransformVector(CurrentLocalOffset);
			}

			CurrentMoveSpline.SwitchTargetableActor.SetActorLocation(FinalSplineLocation + CurrentWorldOffset);
		}
	}

	// Additional torque will be applied to make sure the angle of the player when exiting the spline will always result in a upwards inherited velocity
	void CalculateAdditionalTorque()
	{
		AdditionalTorqueInRadians = 0.0;
		FVector RelPlayerLocation = PreviousTransform.InverseTransformPosition(Player.ActorCenterLocation);
		if(RelPlayerLocation.X > KINDA_SMALL_NUMBER)
			return;

		// Calculate distance traveled over acceleration with this formula (distance = initialVelocity * time + 0.5 * acceleration * sq(t))
		float TimeToReachEnd = CalculateTimeToReachEndOfSpline();

		float TimeToReachMaxTorque = (CurrentMoveSpline.SpiralMaxTorque - CurrentTorque) / CurrentMoveSpline.SpiralTorqueAcceleration;
		float TimeAtMaxTorque = TimeToReachEnd - TimeToReachMaxTorque;
		float DegreeGainOverSplineDistance = CurrentTorque * Math::Min(TimeToReachMaxTorque, TimeToReachEnd) + 0.5 * CurrentMoveSpline.SpiralTorqueAcceleration * Math::Square(Math::Min(TimeToReachMaxTorque, TimeToReachEnd));

		if(TimeAtMaxTorque > 0.0)
			DegreeGainOverSplineDistance += TimeAtMaxTorque * CurrentMoveSpline.SpiralMaxTorque;

		float ExpectedFinalAngleRadians = (CurrentAngle + Math::DegreesToRadians(DegreeGainOverSplineDistance * (bClockwiseTorque ? 1 : -1)));
		ExpectedFinalAngleRadians = Math::UnwindRadians(ExpectedFinalAngleRadians);

		const float TargetAngle = Math::UnwindRadians(PI + (PI / 4 * (bClockwiseTorque ? 1 : -1)));
		
		float DeltaAngle = Math::FindDeltaAngleRadians(ExpectedFinalAngleRadians, TargetAngle);
		AdditionalTorqueInRadians = DeltaAngle / TimeToReachEnd;

		if(IsDebugActive())
		{
			Print(f"Expected time to reach end: {TimeToReachEnd}");
			Print(f"Expected final angle: {Math::RadiansToDegrees(ExpectedFinalAngleRadians)}");
			Print(f"Target angle: {Math::RadiansToDegrees(TargetAngle)}");
			Print(f"Delta from expected angle to target angle: {Math::RadiansToDegrees(DeltaAngle)}");
			Print(f"Additional torque to add: {Math::RadiansToDegrees(AdditionalTorqueInRadians)}");
		}
	}

	float CalculateTimeToReachEndOfSpline()
	{
		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorCenterLocation);
		float TotalDistance = Spline.SplineLength - SplineDistance;

		float AccelerationDuration = (CurrentMoveSpline.MaxSpeed - CurrentSpeed) / CurrentMoveSpline.Acceleration;

		// Calculate distance traveled over acceleration with this formula (distance = initialVelocity * time + 0.5 * acceleration * sq(t))
		float DistanceDuringAcceleration = CurrentSpeed * AccelerationDuration + 0.5 * CurrentMoveSpline.Acceleration * Math::Square(AccelerationDuration);

		float TimeToReachEnd;

		// Reaches end during acceleration
		if(DistanceDuringAcceleration > TotalDistance)
		{
			// Rearrange formula to solve for time (time = (sqrt(2 * acceleration * distance + sq(initialVelocity)) - initialVelocity) / acceleration)
			TimeToReachEnd = (Math::Sqrt(2 * CurrentMoveSpline.Acceleration * TotalDistance * Math::Square(CurrentSpeed)) - CurrentSpeed) / CurrentMoveSpline.Acceleration;
		}
		else
		{
			float DistanceLeft = TotalDistance - DistanceDuringAcceleration;
			TimeToReachEnd = AccelerationDuration + DistanceLeft / CurrentMoveSpline.MaxSpeed;
		}
		return TimeToReachEnd;
	}

	bool ShouldApplyCamera() const
	{
		if(Player.IsPendingFullscreen())
			return false;

		if(Player.IsPlayerMovementLockedToSpline())
			return false;

		return true;
	}
}

struct FTundraFairyMoveSplineMovementActivatedParams
{
	ATundraFairyMoveSpline MoveSpline;
	bool bFlipTravelDirection = false;
	float InitialSpeed = 0.0;
}