class USanctuaryCompanionAviationSidewaySwingMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;

	float ActualStrafeTargetMoveInput = 0.0;
	float RawVerticalOffset = 0.0;

	FVector FutureSplineLocation;
	FQuat FutureSplineQuat;
	float SplineDistance = 0.0;
	float SplineTraversedPercent = 0.0;

	float StrafeAlpha = 0.0;
	float CurrentStrafeOffset;
	float RawStrafeOffset;
	float TargetVerticalOffset;

	float UsedStrafeAlpha = 0.0;
	float UsedVerticalAlpha = 0.0;

	FHazeAcceleratedRotator AccRotator;
	FVector MoveDirection;

	FHazeAcceleratedVector AccForwardDirection;
	FHazeAcceleratedVector AccTargetLocation;
	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedFloat AccStrafeSpeed;
	FHazeAcceleratedFloat AccStrafing;
	FHazeAcceleratedFloat AccVertical;
	FHazeAcceleratedFloat AccArcadeyTargetStrafeAlpha;

	bool bDebug = false;

	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorMio;
	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorZoe;
	bool bTutorial = false;
	FHazeAcceleratedFloat AccFreeDuration;

	EAviationState LastState = EAviationState::None;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		AviationDevToggles::DrawPath.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (!IsInHandledState())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.HasDestination())
			return true;

		if (!IsInHandledState())
			return true;

		return false;
	}


	bool IsInHandledState() const
	{
		if (AviationComp.AviationState == EAviationState::ToAttack)
			return true;
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineDistance = 0.0;
		AccFreeDuration.SnapTo(0.5);
        SpeedEffect::RequestSpeedEffect(Player, AviationComp.Settings.SpeedEffectIntensity, this, EInstigatePriority::Normal);
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		Owner.BlockCapabilities(AviationCapabilityTags::AviationPrepareCameraFocus, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		AviationComp.SyncedFlyingOffsetValue.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		AviationComp.SyncedFlyingMinMaxAlphaValue.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

        if (!HasControl())
            return;

		StrafeAlpha = 0.0;
		MoveDirection = Owner.ActorForwardVector;
		AccForwardDirection.SnapTo(Owner.ActorForwardVector);
		AccRotator.SnapTo(Owner.ActorRotation);
		if (AviationComp.AviationState != EAviationState::InitAttack)
		{
			AccSpeed.SnapTo(MoveComp.Velocity.Size());
			RawVerticalOffset = 0.0;
			RawStrafeOffset = 0.0;
		}
		if (ToAttackFocusActorMio == nullptr || ToAttackFocusActorZoe == nullptr)
		{
			TListedActors<ASanctuaryBossArenaManager> HydraManagers;
			if (HydraManagers.Num() > 0) // We dont have a hydra in the tutorial :)
			{
				ToAttackFocusActorMio = HydraManagers.Single.ToAttackFocusActorMio;
				ToAttackFocusActorZoe = HydraManagers.Single.ToAttackFocusActorZoe;
			}
			else
				bTutorial = true;
		}
		AccTargetLocation.SnapTo(Owner.ActorLocation);
		AccTargetLocation.Velocity = MoveComp.Velocity;
		AviationComp.ResetEndOfMovementSpline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
        SpeedEffect::ClearSpeedEffect(Player, this);
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		Owner.UnblockCapabilities(AviationCapabilityTags::AviationPrepareCameraFocus, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		if (HasControl())
			AviationComp.ResetEndOfMovementSpline();

		AviationComp.SyncedFlyingOffsetValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		AviationComp.SyncedFlyingMinMaxAlphaValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				bDebug = AviationDevToggles::DrawPath.IsEnabled();

				if (AviationComp.AviationState != LastState)
				{
					AccFreeDuration.SnapTo(0.5);
					SplineDistance = 0.0;
				}
				LastState = AviationComp.AviationState;

				float TargetSpeed = GetCurrentSpeed();
				// if (!bTutorial && AviationComp.AviationState != EAviationState::InitAttack && SplineDistance > SpeedUpHackyDistance)
				// 	TargetSpeed *= 3.0;
				AccSpeed.AccelerateTo(TargetSpeed, AviationComp.Settings.SidewaysSpeedInterpolationDuration, DeltaTime);
				SplineDistance += AccSpeed.Value * DeltaTime;

				UpdateDataFromSpline(DeltaTime);
				if (AviationDevToggles::StrafeArcadey.IsEnabled())
				{
					ArcadeyUpdateStrafing(DeltaTime);
					AccTargetLocation.AccelerateTo(ArcadeyGetStrafeTargetLocation(DeltaTime), AviationComp.Settings.SidewaysPositionInterpolationDuration, DeltaTime);
				}
				else if (AviationDevToggles::FreeDelta.IsEnabled() || AviationDevToggles::FreeAbsolute.IsEnabled() || AviationDevToggles::FreeStrafeOnly.IsEnabled())
				{
					FreeUpdateStrafing(DeltaTime);
					FreeUpdateVertical(DeltaTime);
					
					FVector2D SyncedFlyingValue = FVector2D(UsedStrafeAlpha, UsedVerticalAlpha);
					AviationComp.SyncedFlyingOffsetValue.SetValue(SyncedFlyingValue);

					FVector TargetLocation = FreeGetStrafeTargetLocation(DeltaTime);
					AccFreeDuration.AccelerateTo(0.0, 0.5, DeltaTime);
					if (AccFreeDuration.Value < KINDA_SMALL_NUMBER)
						AccTargetLocation.SnapTo(TargetLocation);
					else
						AccTargetLocation.AccelerateTo(TargetLocation, AccFreeDuration.Value, DeltaTime);
				}

				if (bDebug)
				{
					Debug::DrawDebugSphere(FutureSplineLocation + FutureSplineQuat.RightVector * ActualStrafeTargetMoveInput * AviationComp.Settings.SidewaysMovementDistanceMax, 50.0, 12, ColorDebug::Lavender, 5.0, 0.0, true);
					Debug::DrawDebugSphere(FutureSplineLocation +  FutureSplineQuat.RightVector * Math::Sign(CurrentStrafeOffset) * StrafeAlpha * AviationComp.Settings.SidewaysMovementDistanceMax, 50.0, 12, ColorDebug::Bubblegum, 5.0, 0.0, true);
				}
				
				FVector UsedVelocity = AccTargetLocation.Velocity.Size() > KINDA_SMALL_NUMBER ? AccTargetLocation.Velocity : FutureSplineQuat.ForwardVector; 
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(AccTargetLocation.Value, UsedVelocity);
				Movement.AddDelta(FutureSplineQuat.ForwardVector * AccSpeed.Value * DeltaTime);

				AccForwardDirection.AccelerateTo(FutureSplineQuat.ForwardVector, AviationComp.Settings.SidewaysDirectionInterpolationDuration, DeltaTime);
				FRotator TargetRot = FRotator::MakeFromXZ(AccForwardDirection.Value.GetSafeNormal(), FVector::UpVector);
				TargetRot.Roll = UsedStrafeAlpha * AviationComp.Settings.SidewaysMovementRoll * -1.0; // roll "inwards"
				AccRotator.AccelerateTo(TargetRot, GetRotationAccelerationDuration(), DeltaTime);

				if (bDebug)
				{
					Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + TargetRot.UpVector * 300.0, ColorDebug::Cyan, 5.0, 0.0, true);
					Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + AccForwardDirection.Value.GetSafeNormal() * AccSpeed.Value, ColorDebug::Red, 5.0, 0.0, true);
				}

				Movement.SetRotation(AccRotator.Value);

				if (!bTutorial)
				{
					// Camera focus
					FVector FocusPoint = FutureSplineLocation;
					if (Player.IsMio() && ToAttackFocusActorMio != nullptr)
						ToAttackFocusActorMio.SetControlDesiredLocation(FocusPoint);
					else if (ToAttackFocusActorZoe != nullptr)
						ToAttackFocusActorZoe.SetControlDesiredLocation(FocusPoint);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	FVector FreeGetStrafeTargetLocation(float DeltaTime)
	{
		StrafeAlpha = Math::Abs(UsedStrafeAlpha) / AviationComp.Settings.SidewaysMovementDistanceMax;
		// if (AviationDevToggles::StrafeLerpedSpeeds.IsEnabled())
		// StrafeLerpedSpeeds();
		// else
		{
			CurrentStrafeOffset = UsedStrafeAlpha * GetCurrentMovementSidewaysDistance();
		}

		// ARC
		float ArcAlpha = Math::EaseIn(0.0, 1.0, Math::Abs(StrafeAlpha), 3.0);
		FVector StrafeArcOffset = FVector::UpVector * ArcAlpha * AviationComp.Settings.SidewaysArcHeight; // Add height on ends to give impression of "arc" on sides. Like a waterslide :)

		FVector StrafeOffset = FutureSplineQuat.RightVector * CurrentStrafeOffset;
		FVector VerticalOffset = FVector();
		float MaxVertical = GetCurrentMovementVerticalDistance();
		if (!AviationDevToggles::FreeStrafeOnly.IsEnabled())
		{
			VerticalOffset = FutureSplineQuat.UpVector * UsedVerticalAlpha * MaxVertical;
		}

		if (AviationDevToggles::DrawPath.IsEnabled())
		{
			float MaxHorizontal = GetCurrentMovementSidewaysDistance();
			Debug::DrawDebugEllipse(FutureSplineLocation, FVector2D(MaxVertical, MaxHorizontal), ColorDebug::Pumpkin, 5.0, Player.ActorForwardVector, FVector::UpVector, 48);
			Debug::DrawDebugSphere(FutureSplineLocation, 50.0, 12, ColorDebug::Pumpkin, 3.0, 0.0, true);
		}

		FVector StrafeTargetLocation = FutureSplineLocation + StrafeArcOffset + StrafeOffset + VerticalOffset;
		return StrafeTargetLocation;
	}

	private void StrafeLerpedSpeeds()
	{
		// {
		// 	if (!Math::IsNearlyEqual(UsedStrafeAlpha, RawStrafeOffset))
		// 	{
		// 		CurrentStrafeOffset = UsedStrafeAlpha * GetCurrentMovementSidewaysDistance();
				
		// 		bool bCurrentPositiveSign = UsedStrafeAlpha > 0.0;
		// 		bool bTargetPositiveSign = RawStrafeOffset > 0.0;
		// 		bool bGoingOutwards = bCurrentPositiveSign == bTargetPositiveSign && Math::Abs(RawStrafeOffset) > Math::Abs(CurrentStrafeOffset);

		// 		float Speed = AviationComp.Settings.SidewaysStrafeSpeed;
		// 		// going outwards?
		// 		if (bGoingOutwards)
		// 			Speed = Math::Lerp(AviationComp.Settings.SidewaysStrafeSpeed, 0.0, StrafeAlpha);//, 3.0); 
		// 		// going slowly towards middle
		// 		if (Math::IsNearlyEqual(ActualStrafeTargetMoveInput, 0.0))
		// 			Speed = Math::Lerp(0.0, AviationComp.Settings.SidewaysStrafeSpeed, StrafeAlpha);

		// 		if (bDebug)
		// 		{
		// 			Debug::DrawDebugString(Owner.ActorLocation, "Target " + RawStrafeOffset, ColorDebug::Cornflower, 0.0, 2.0);
		// 			Debug::DrawDebugString(Owner.ActorLocation, "\n\nStrafed%  " + StrafeAlpha, ColorDebug::Cornflower, 0.0, 2.0);
		// 			Debug::DrawDebugString(Owner.ActorLocation, "\n\n\n\nStrafe Speed " + Speed, ColorDebug::Cornflower, 0.0, 2.0);
		// 		}

		// 		float TotalDelta = RawStrafeOffset - CurrentStrafeOffset;
		// 		AccStrafeSpeed.AccelerateTo(Math::Sign(TotalDelta) * Speed, 0.1, DeltaTime);

		// 		float FrameDelta = AccStrafeSpeed.Value * DeltaTime;
		// 		if (Math::Abs(FrameDelta) > Math::Abs(TotalDelta))
		// 			FrameDelta = TotalDelta;
		// 		CurrentStrafeOffset += FrameDelta;
		// 	}
		// }
	}

	// -------------------

	private void FreeUpdateStrafing(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput.GetSafeNormal();
		if (AviationDevToggles::FreeAbsolute.IsEnabled())
		{
			RawStrafeOffset = MoveInput.Y;
			AccStrafing.AccelerateTo(RawStrafeOffset, GetHorizontalInputDuration(), DeltaTime);
			UsedStrafeAlpha = AccStrafing.Value;
		}
		if (AviationDevToggles::FreeDelta.IsEnabled())
		{
			if (Math::Abs(MoveInput.Y) > 0.2)
			{
				float Speed = AviationComp.Settings.SidewaysDeltaMoveSpeed;
				RawStrafeOffset += Math::Sign(MoveInput.Y) * Speed * DeltaTime;
				float MaxY = Math::Abs( MoveInput.Y);
				RawStrafeOffset = Math::Clamp(RawStrafeOffset, -MaxY, MaxY);
			}
			AccStrafing.AccelerateTo(RawStrafeOffset, AviationComp.Settings.SidewaysDeltaMoveDuration, DeltaTime);
			UsedStrafeAlpha = AccStrafing.Value;
		}
	}

	float GetHorizontalInputDuration()
	{
		return bTutorial ? AviationComp.Settings.TutorialSidewaysHorizontalInputDuration : AviationComp.Settings.SidewaysHorizontalInputDuration;
	}

	private void FreeUpdateVertical(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput.GetSafeNormal();

		if (AviationDevToggles::FreeAbsolute.IsEnabled())
		{
			RawVerticalOffset = MoveInput.X;
			UsedVerticalAlpha = AccVertical.Value;
			AccVertical.AccelerateTo(RawVerticalOffset, GetVerticalInputDuration(), DeltaTime);
			UsedVerticalAlpha = AccVertical.Value;
		}
		if (AviationDevToggles::FreeDelta.IsEnabled())
		{
			if (Math::Abs(MoveInput.X) > 0.2)
			{
				float Speed = AviationComp.Settings.SidewaysDeltaMoveSpeed;
				RawVerticalOffset += Math::Sign(MoveInput.X) * Speed * DeltaTime;
				float MaxX = Math::Abs(MoveInput.X);
				RawVerticalOffset = Math::Clamp(RawVerticalOffset, -MaxX, MaxX);
			}
			AccVertical.AccelerateTo(RawVerticalOffset, AviationComp.Settings.SidewaysDeltaMoveDuration, DeltaTime);
			UsedVerticalAlpha = AccVertical.Value;
		}
	}

	float GetVerticalInputDuration()
	{
		return bTutorial ? AviationComp.Settings.TutorialSidewaysVerticalInputDuration : AviationComp.Settings.SidewaysVerticalInputDuration;
	}

// -------------------

	FVector ArcadeyGetStrafeTargetLocation(float DeltaTime)
	{
		StrafeAlpha = Math::Abs(CurrentStrafeOffset) / AviationComp.Settings.SidewaysMovementDistanceMax;
		if (!Math::IsNearlyEqual(CurrentStrafeOffset, RawStrafeOffset))
		{
			float TotalDelta = RawStrafeOffset - CurrentStrafeOffset;
			float FrameDelta = Math::Sign(TotalDelta) * AviationComp.Settings.SidewaysStrafeSpeed * DeltaTime;
			if (Math::Abs(FrameDelta) > Math::Abs(TotalDelta))
				FrameDelta = TotalDelta;
			CurrentStrafeOffset += FrameDelta;
		}

		float ArcAlpha = Math::EaseIn(0.0, 1.0, Math::Abs(StrafeAlpha), 3.0);
		FVector StrafeArcOffset = FVector::UpVector * ArcAlpha * AviationComp.Settings.SidewaysArcHeight; // Add height on ends to give impression of "arc" on sides. Like a waterslide :)
		FVector StrafeOffset = FutureSplineQuat.RightVector * CurrentStrafeOffset;
		FVector StrafeTargetLocation = FutureSplineLocation + StrafeOffset + StrafeArcOffset;
		return StrafeTargetLocation;
	}

	// -------------------

	private void ArcadeyUpdateStrafing(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput.GetSafeNormal();
		AccArcadeyTargetStrafeAlpha.AccelerateTo(MoveInput.Y, 1.337, DeltaTime);
		RawStrafeOffset = AccArcadeyTargetStrafeAlpha.Value * AviationComp.Settings.SidewaysMovementDistanceMax; // goes from -SidewaysMovementDistance to SidewaysMovementDistance
	}

// -------------------

	private void UpdateDataFromSpline(float DeltaTime)
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (DestinationData.HasRuntimeSpline())
		{
			if (bDebug)
				DestinationData.RuntimeSpline.DrawDebugSpline();

			if (SplineDistance >= DestinationData.RuntimeSpline.Length)
			{
				SplineDistance = DestinationData.RuntimeSpline.Length;
				AviationComp.SetEndOfMovementSpline();
			}
			
			SplineTraversedPercent = Math::Clamp(SplineDistance / DestinationData.RuntimeSpline.Length, 0.0, 1.0);
			AviationComp.SyncedFlyingMinMaxAlphaValue.SetValue(GetSyncedFlyingMinMaxAlphaValue());

			if (DestinationData.RuntimeSpline.Points.Num() == 2)
			{
				FVector StartLocation = DestinationData.RuntimeSpline.Points[0];
				FVector EndLocation = DestinationData.RuntimeSpline.Points[1];
				FVector Direction = (EndLocation - StartLocation).GetSafeNormal();
				FutureSplineQuat = FRotator::MakeFromXZ(Direction, FVector::UpVector).Quaternion();
				FutureSplineLocation = StartLocation + Direction * SplineDistance;
			}
			else
				DestinationData.RuntimeSpline.GetLocationAndQuatAtDistance(SplineDistance, FutureSplineLocation, FutureSplineQuat);
			
			if (bDebug)
			{
				Debug::DrawDebugSphere(FutureSplineLocation);
				Debug::DrawDebugCoordinateSystem(FutureSplineLocation, FutureSplineQuat.Rotator(), 300.0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("SplineDistance", SplineDistance);

		if (AviationComp.HasDestination())
		{
			const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
			if (DestinationData.HasRuntimeSpline())
			{
				TemporalLog.Value("SplineLength", DestinationData.RuntimeSpline.Length);
				TemporalLog.RuntimeSpline("DestinationSpline", DestinationData.RuntimeSpline);
			}
		}
	}

	private float GetSyncedFlyingMinMaxAlphaValue()
	{
		if (bTutorial)
			return 1.0;
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return 0.0;
		return SplineTraversedPercent;
	}

	private float GetCurrentMovementVerticalDistance()
	{
		if (bTutorial)
			return AviationComp.Settings.VerticalMovementDistanceMax;
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return AviationComp.Settings.VerticalMovementDistanceMin;
		return Math::Lerp(AviationComp.Settings.VerticalMovementDistanceMax, AviationComp.Settings.VerticalMovementDistanceMin, SplineTraversedPercent);
	}

	private float GetCurrentMovementSidewaysDistance()
	{
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return AviationComp.Settings.SidewaysMovementDistanceMin;
		float Percent = 1.0 - AviationComp.MovementCurve.GetFloatValue(SplineTraversedPercent);
		if (bTutorial)
			return AviationComp.Settings.SidewaysMovementDistanceMax * SanctuaryAviationTutorialFlyingSidewaysAllowedCurve.GetFloatValue(Percent);
		return Math::Lerp(AviationComp.Settings.SidewaysMovementDistanceMax, AviationComp.Settings.SidewaysMovementDistanceMin, Percent);
	}

	private float GetCurrentSpeed()
	{
		if (AviationComp.AviationState == EAviationState::InitAttack)
			return AviationComp.Settings.InitiateAttackSpeed;
		return bTutorial ? AviationComp.Settings.TutorialSpeed : AviationComp.Settings.SidewaysForwardSpeed;
	}

	private FVector ClampYawToDegreesAngle(FVector InVector, float AngleDegrees)
	{
		FVector ClampedYaw;
		FVector2D MaxYawDelta = Math::AngleDegreesToDirection(AngleDegrees);
		ClampedYaw.X = Math::Clamp(InVector.X, -MaxYawDelta.X, MaxYawDelta.X);
		ClampedYaw.Y = Math::Clamp(InVector.Y, -MaxYawDelta.Y, MaxYawDelta.Y);
		return ClampedYaw;
	}

	private FVector ClampPitchToDegreesAngle(FVector InVector, float AngleDegrees)
	{
		FVector ClampedYaw;
		FVector2D MaxYawDelta = Math::AngleDegreesToDirection(AngleDegrees);
		ClampedYaw.X = Math::Clamp(InVector.X, -MaxYawDelta.X, MaxYawDelta.X);
		ClampedYaw.Z = Math::Clamp(InVector.Z, -MaxYawDelta.Y, MaxYawDelta.Y);
		return ClampedYaw;
	}

	private float GetRotationAccelerationDuration()
	{
		const float Multiplier = 1.0;
		float SoftLerp = Math::Clamp(ActiveDuration * Multiplier, 0.0, 1.0);
		return Math::Lerp(1.0, 0.01, SoftLerp);
	}
}