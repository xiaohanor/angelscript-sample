class UWingSuitMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Wingsuit");
	default CapabilityTags.Add(n"WingsuitMovement");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = n"Wingsuit";
	
	UPlayerMovementComponent MoveComp;
	UWingSuitPlayerComponent WingSuitComp;
	USweepingMovementData Movement;
	UWingSuitSettings Settings;

	// Synced for animation
	UHazeCrumbSyncedFloatComponent SyncedAnimYawTurnSpeedDegrees;

	FHazeAcceleratedFloat CurrentHorizontalMoveSpeed;
	FHazeAcceleratedFloat CurrentVerticalMoveSpeed;
	FVector2D TargetMoveSpeed = FVector2D::ZeroVector;
	
	float OrientationChangeAmount = 0;
	FVector LastInput = FVector::ZeroVector;
	float GroundRumbleStrength = 0.0;
	float GroundCameraShakeScale = 0.0;
	float RotationChangeMultiplier = 1;
	FWingSuitRubberBandData RubberbandSettings;
	
	float BarrelRollTimeLeft = 0;
	FHazeAcceleratedFloat LockedYawSidewaysAcceleratedSpeed;
	uint StopBarrelRollFrame;
	FVector BarrelRollInterpedInput;

	UCameraShakeBase GroundDistanceCameraShake;
	UCameraShakeBase PitchDownCameraShake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UWingSuitSettings::GetSettings(Player);

		SyncedAnimYawTurnSpeedDegrees = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"SyncedWingSuitAnimYawTurnSpeed");
		SyncedAnimYawTurnSpeedDegrees.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!WingSuitComp.bWingsuitActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!WingSuitComp.bWingsuitActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMovementGravitySettings::SetTerminalVelocity(Player, -1.0, this);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		LockedYawSidewaysAcceleratedSpeed.SnapTo(0.0);

		FVector HorizontalMovementDirection = MoveComp.GetVelocity().VectorPlaneProject(FVector::UpVector);
		if(HorizontalMovementDirection.IsNearlyZero())
			HorizontalMovementDirection = Player.ActorForwardVector;
	
		// If yaw rotation is locked, we don't want to update movement orientation, otherwise it might change when
		// transitioning out of a wingsuit grapple for instance and since it's locked, the player can't change it later
		if(!Settings.bLockYawRotation)
		{
			WingSuitComp.SyncedHorizontalMovementOrientation.Value = HorizontalMovementDirection.ToOrientationRotator();
			WingSuitComp.SyncedHorizontalMovementOrientation.SnapRemote();
		}

		InheritMoveCompVelocity();
		OrientationChangeAmount = 0;
		LastInput = FVector::ZeroVector;

		// We start with a little bit off so we lerp into the correct values
		WingSuitComp.InterpedRotation = WingSuitComp.SyncedInternalRotation.Value;

		if(WingSuitComp.bActivatedFromCutscene)
		{
			FVector Velocity = Player.GetRawLastFrameTranslationVelocity();
			FVector Horizontal = Velocity.VectorPlaneProject(FVector::UpVector);
			FVector Vertical = Velocity - Horizontal;
			CurrentHorizontalMoveSpeed.SnapTo(Horizontal.Size());
			CurrentVerticalMoveSpeed.SnapTo(Vertical.Size() * Math::Sign(Vertical.Z));
		}
		else
		{
			CurrentHorizontalMoveSpeed.SnapTo(Settings.IdleTargetMoveSpeed.X);
			CurrentVerticalMoveSpeed.SnapTo(Settings.IdleTargetMoveSpeed.Y);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearTerminalVelocity(Player, this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		Player.StopForceFeedback(this);
		Player.Mesh.RelativeRotation = FRotator::ZeroRotator;
		WingSuitComp.SyncedInternalRotation.Value = FRotator::ZeroRotator;
		WingSuitComp.SyncedInternalRotation.SnapRemote();
		WingSuitComp.InterpedRotation = FRotator::ZeroRotator;
		WingSuitComp.SyncedHorizontalMovementOrientation.Value = FRotator::ZeroRotator;
		WingSuitComp.SyncedHorizontalMovementOrientation.SnapRemote();
		BarrelRollTimeLeft = 0;
		WingSuitComp.CrumbSetActiveBarrelRollDirection(0);
		WingSuitComp.RubberBandSpeedBonus = 0;
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this);
		GroundDistanceCameraShake = nullptr;
		PitchDownCameraShake = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// I hate this, but it is too late to make this right since the pivot of the mesh would change which might require animation changes.
		if(WingSuitComp.bLerpMesh)
		{
			WingSuitComp.AccMeshOffset.AccelerateTo(-100.0, 1.0, DeltaTime);
			if(Math::IsNearlyEqual(WingSuitComp.AccMeshOffset.Value, -100.0))
			{
				WingSuitComp.AccMeshOffset.SnapTo(-100.0);
				WingSuitComp.bLerpMesh = false;
				Player.MeshOffsetComponent.SnapToRelativeTransform(WingSuitComp, Player.RootOffsetComponent, FTransform(FRotator(), FVector(0.0, 0.0, -100.0)));
				Player.Mesh.RelativeLocation = FVector::ZeroVector;
				return;
			}

			Player.Mesh.RelativeLocation = FVector::UpVector * WingSuitComp.AccMeshOffset.Value;
		}

		float SpeedEffectValue = Math::GetMappedRangeValueClamped(FVector2D(3800.0, 6000.0), FVector2D(0.0, 1.0), FVector2D(CurrentHorizontalMoveSpeed.Value, CurrentVerticalMoveSpeed.Value).Size());
		SpeedEffect::RequestSpeedEffect(Player, SpeedEffectValue, this, EInstigatePriority::High);

		if(HasControl())
		{
			// Rubber banding
			FSplinePosition SplinePosition = WingSuitComp.Manager.GetClosestSplineRespawnPosition(Player.ActorLocation);
			UpdateRubberband(DeltaTime);

			// Update auto steering
			FVector MovementInput = MoveComp.GetMovementInput();
			if(!MovementInput.IsNearlyZero(0.2) && ActiveDuration > 1.0)
			{
				WingSuitComp.AutoSteeringTimeLeft = 0;
			}

			SplinePosition.Move(500);

			FVector AutoSteerMovementInput;
			FVector DirToPosition = (SplinePosition.WorldLocation - Player.ActorLocation).GetSafeNormal();
			AutoSteerMovementInput.Z = DirToPosition.DotProduct(FVector::UpVector);
			AutoSteerMovementInput.Y = DirToPosition.DotProduct(Player.ActorRightVector);
			
			// Update auto steering
			if(WingSuitComp.AutoSteeringTimeLeft > 0
			// || WingSuit.PlayerOwner.IsMio()// DEBUG
			)
			{
				WingSuitComp.AutoSteeringTimeLeft -= DeltaTime;

				// Auto steer a little bit ahead
				MovementInput = AutoSteerMovementInput;
				RotationChangeMultiplier = 3;
			}
			else
			{
				// Do boundary spline horizontal steerback.
				float BoundaryHorizontalAlpha = WingSuitComp.GetWingSuitHorizontalSteerbackAlpha();
				
				MovementInput.Y = Math::Lerp(MovementInput.Y, AutoSteerMovementInput.Y, BoundaryHorizontalAlpha);
				RotationChangeMultiplier = 1;
			}

			LastInput = MovementInput;


			WingSuitComp.CurrentPitchOffset = Math::FInterpTo(WingSuitComp.CurrentPitchOffset, Settings.TargetPitchOffset, DeltaTime, Settings.PitchOffsetInterpSpeed);
			FVector CurrentUpVector = FVector::UpVector;
			const FVector AxisToRotateAround = WingSuitComp.SyncedHorizontalMovementOrientation.Value.RightVector;
			CurrentUpVector = CurrentUpVector.RotateAngleAxis(WingSuitComp.CurrentPitchOffset, AxisToRotateAround);
			if(MoveComp.PrepareMove(Movement, CurrentUpVector))
			{	
				UpdateControlMovement(DeltaTime, MovementInput);
			}
		}	
		else
		{
			if(MoveComp.PrepareMove(Movement))
			{
				UpdateRemoteMovement(DeltaTime);
			}
		}

#if !RELEASE
		float Pitch = Math::UnwindDegrees(WingSuitComp.SyncedInternalRotation.Value.Pitch);
		float TargetY = -Pitch / 45.0;
		TEMPORAL_LOG(this)
			.Value("SyncedInternalRotation", WingSuitComp.SyncedInternalRotation.Value)
			.Value("TargetY (used in FeatureAnimInstance)", TargetY)
		;
#endif

		WingSuitComp.AnimData.YawTurnSpeedDegrees = SyncedAnimYawTurnSpeedDegrees.Value;
	}

	void UpdateRubberband(float DeltaTime)
	{
		TPerPlayer<FSplinePosition> SplinePositions = WingSuitComp.Manager.SplinePositions;
		RubberbandSettings = WingSuitComp.Manager.GetRubberBandSettings(Player);
		const UWingSuitPlayerComponent OtherWingsSuitComp = UWingSuitPlayerComponent::Get(Player.OtherPlayer);
		
		// The other player is dead
		if(!OtherWingsSuitComp.bWingsuitActive || WingSuitComp.IsWingSuitRubberbandBlocked())
		{
			WingSuitComp.RubberBandSpeedBonus = 0;
			return;
		}

		float TargetSpeed;
		// We are actually ahead and should try to apply that
		if(WingSuitComp.Manager.IsHead(Player))
		{	
			TargetSpeed = RubberbandSettings.BonusSpeedWhenAhead;
		}
		// We are behind and should try to apply that
		else
		{
			TargetSpeed = RubberbandSettings.BonusSpeedWhenBehind;
		}

		const float DistanceDiff = Math::Abs(SplinePositions[EHazePlayer::Mio].CurrentSplineDistance - SplinePositions[EHazePlayer::Zoe].CurrentSplineDistance);

		float DistanceAlpha = 1.0;
		if(RubberbandSettings.BonusSpeedLerpDownAdditionalDistance > 0.0)
			DistanceAlpha = Math::Saturate((DistanceDiff - RubberbandSettings.BonusSpeedTolerance) / RubberbandSettings.BonusSpeedLerpDownAdditionalDistance);

		TargetSpeed = Math::Lerp(0.0, TargetSpeed, DistanceAlpha);

		WingSuitComp.RubberBandSpeedBonus = Math::FInterpTo(WingSuitComp.RubberBandSpeedBonus, TargetSpeed, DeltaTime, RubberbandSettings.BonusSpeedApplySpeed);
	}

	void UpdateControlMovement(float DeltaTime, FVector MovementInput)
	{
		// Update the barrel roll
		if(WingSuitComp.WantedBarrelRollDirection != 0 && BarrelRollTimeLeft < KINDA_SMALL_NUMBER)
		{
			BarrelRollTimeLeft = Settings.BarrelRollActionTime;
			WingSuitComp.CrumbSetActiveBarrelRollDirection(WingSuitComp.WantedBarrelRollDirection);
			BarrelRollInterpedInput = MoveComp.MovementInput;
		}

		// Update the movement forward direction
		if(!Settings.bLockYawRotation)
		{
			float SidewaysInput = MovementInput.Y;

			FSplinePosition SplinePos = WingSuitComp.Manager.GetClosestSplineRespawnPosition(Player.ActorLocation);
			float Angle = WingSuitComp.SyncedHorizontalMovementOrientation.Value.ForwardVector.GetAngleDegreesTo(SplinePos.WorldForwardVector);
			if(Angle > 70.0)
			{
				float Sign = WingSuitComp.SyncedHorizontalMovementOrientation.Value.ForwardVector.DotProduct(SplinePos.WorldRightVector);
				Sign = Math::Sign(Sign);
				float SignedAngle = Angle * Sign;
				float Min = Math::GetMappedRangeValueClamped(FVector2D(-70.0, -90.0), FVector2D(-1.0, 0.0), SignedAngle);
				float Max = Math::GetMappedRangeValueClamped(FVector2D(70.0, 90.0), FVector2D(1.0, 0.0), SignedAngle);
				SidewaysInput = Math::Clamp(MovementInput.Y, Min, Max);
			}
			
			const float TargetOrientationChange = SidewaysInput * Settings.MaxRotationSpeed * RotationChangeMultiplier;	
			if(TargetOrientationChange >= OrientationChangeAmount)
			{
				OrientationChangeAmount = Math::FInterpConstantTo(
					OrientationChangeAmount, TargetOrientationChange, 
					DeltaTime, 
					Settings.IncreaseToRotationMaxSpeedAcceleration * RotationChangeMultiplier);
			}
			else
			{
				OrientationChangeAmount = Math::FInterpConstantTo(
					OrientationChangeAmount, TargetOrientationChange, 
					DeltaTime, 
					Settings.DecreaseToRotationZeroSpeedAcceleration * RotationChangeMultiplier);
			}

			SyncedAnimYawTurnSpeedDegrees.Value = OrientationChangeAmount / RotationChangeMultiplier;
			FRotator Orientation = WingSuitComp.SyncedHorizontalMovementOrientation.Value;
			Orientation.Yaw += OrientationChangeAmount * DeltaTime;
			WingSuitComp.SyncedHorizontalMovementOrientation.Value = Orientation;
		}

		float TargetPitchAngle = WingSuitComp.GetWingSuitDefaultAngle();
		if(MovementInput.Z > 0)
			TargetPitchAngle = Math::Lerp(0, WingSuitComp.GetWingSuitMaxAngle(), MovementInput.Z);
		else if(MovementInput.Z < 0)
			TargetPitchAngle = Math::Lerp(0, WingSuitComp.GetWingSuitMinAngle(), Math::Abs(MovementInput.Z));

		FRotator Rot = WingSuitComp.SyncedInternalRotation.Value;
		float64& PitchAngle = Rot.Pitch;
		float64& RollAngle = Rot.Roll;

		// Update the pitch
		{			
			if(WingSuitComp.ActiveBarrelRollDirection == 0)
			{
				if(TargetPitchAngle > PitchAngle && Math::Abs(MovementInput.Z) > KINDA_SMALL_NUMBER)
				{
					PitchAngle = Math::FInterpTo(PitchAngle, TargetPitchAngle, DeltaTime, Settings.PitchUpAcceleration * RotationChangeMultiplier);
				}
				else if(TargetPitchAngle < PitchAngle && Math::Abs(MovementInput.Z) > KINDA_SMALL_NUMBER)
				{
					PitchAngle = Math::FInterpTo(PitchAngle, TargetPitchAngle, DeltaTime, Settings.PitchDownAcceleration * RotationChangeMultiplier);
				}
				else if(Math::Abs(MovementInput.Z) < KINDA_SMALL_NUMBER)
				{
					PitchAngle = Math::FInterpTo(PitchAngle, TargetPitchAngle, DeltaTime, Settings.PitchToIdleAcceleration * RotationChangeMultiplier);
				}
			}
		}

#if EDITOR
		const float LineLength = 500.0;

		FVector HorizontalForward = Player.ActorForwardVector.VectorPlaneProject(FVector::UpVector);

		FTemporalLog TemporalLog = TEMPORAL_LOG(WingSuitComp.WingSuit, "WingSuit");
		FString BoundaryCategory = f"10#Boundary Volume";
		TemporalLog.Line(f"{BoundaryCategory};Original Max Angle", Player.ActorLocation, Player.ActorLocation + FRotator(Settings.PitchUpMaxAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, 2.0, FLinearColor::Red);
		TemporalLog.Line(f"{BoundaryCategory};Target Pitch Angle", Player.ActorLocation, Player.ActorLocation + FRotator(TargetPitchAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, 2.0, FLinearColor::LucBlue);
		TemporalLog.Line(f"{BoundaryCategory};Current Pitch Angle", Player.ActorLocation, Player.ActorLocation + FRotator(TargetPitchAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, 2.0, FLinearColor::Purple);

		UWingSuitBoundarySplineComponent SplineBoundary = WingSuitComp.GetClosestWingSuitBoundarySplineComp();
		if(SplineBoundary != nullptr)
		{
			FTransform ClosestTransform = Spline::GetGameplaySpline(SplineBoundary.Owner).GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
			FVector NoSteerbackZoneExtent = FVector(SplineBoundary.SplineTransformLocalBox.Extent.X, SplineBoundary.SplineTransformLocalBox.Extent.Y * SplineBoundary.BoundaryWidthSteerbackPercentage, SplineBoundary.SplineTransformLocalBox.Extent.Z);
			TemporalLog
			.Box(f"{BoundaryCategory};Current Wingsuit Boundary Spline Component", ClosestTransform.TransformPosition(SplineBoundary.SplineTransformLocalBox.Center), SplineBoundary.SplineTransformLocalBox.Extent * ClosestTransform.Scale3D, ClosestTransform.Rotator(), FLinearColor::LucBlue, 50.0)
			.Box(f"{BoundaryCategory};Current Wingsuit Boundary Spline No Steerback Zone", ClosestTransform.TransformPosition(SplineBoundary.SplineTransformLocalBox.Center), NoSteerbackZoneExtent * ClosestTransform.Scale3D, ClosestTransform.Rotator(), FLinearColor::Red, 50.0)
			.Line(f"{BoundaryCategory};Boundary Min Max Angle", Player.ActorLocation, Player.ActorLocation + FRotator(SplineBoundary.PitchUpMinMaxAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, 2.0, FLinearColor::Green)
			.Line(f"{BoundaryCategory};Current Max Angle", Player.ActorLocation, Player.ActorLocation + FRotator(WingSuitComp.GetWingSuitMaxAngle(), 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, 2.0, FLinearColor::Yellow)
			.Value(f"{BoundaryCategory};Current Boundary Alpha", SplineBoundary.GetVolumeAlphaForLocation(Player.ActorLocation));
		}

		UWingSuitBoundarySplineComponent ClosestSplineBoundary = WingSuitComp.GetClosestWingSuitBoundarySplineComp(false);
		if(ClosestSplineBoundary != nullptr)
		{
			FTransform ClosestTransform = Spline::GetGameplaySpline(ClosestSplineBoundary.Owner).GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
			TemporalLog.Box(f"{BoundaryCategory};Closest Wingsuit Boundary Spline Component", ClosestTransform.TransformPosition(ClosestSplineBoundary.SplineTransformLocalBox.Center), ClosestSplineBoundary.SplineTransformLocalBox.Extent * ClosestTransform.Scale3D, ClosestTransform.Rotator(), FLinearColor::LucBlue, 50.0);
		}
#endif

		const float AngleBoarder = 0.01;

		float DebugAlphaValue = 0;
		// float DebugAlphaFinalValue = 0;
		bool bClearForceFeedBack = true;
		bool bClearCameraShake = true;

		// Update the target move speed
		{
			// Pitch down target move speed
			if(TargetPitchAngle < -AngleBoarder && PitchAngle < -AngleBoarder)
			{
				float PitchAlpha = (Math::Abs(PitchAngle) / Settings.PitchDownMaxAngle);
				const FVector2D TargetSpeed = Math::Lerp(Settings.IdleTargetMoveSpeed, Settings.PitchDownTargetMoveSpeed, PitchAlpha);
				DebugAlphaValue = PitchAlpha;
				TargetMoveSpeed = TargetSpeed;

				// PitchAlpha = Settings.PitchTargetMoveSpeedAcceleration.GetFloatValue(-PitchAlpha);
				// DebugAlphaFinalValue = PitchAlpha;

				// TargetMoveSpeed.X = Math::FInterpTo(TargetMoveSpeed.X, TargetSpeed.X, DeltaTime, PitchAlpha);
				// TargetMoveSpeed.Y = Math::FInterpTo(TargetMoveSpeed.Y, TargetSpeed.Y, DeltaTime, PitchAlpha);
			}

			// Pitch up target move speed
			else if(TargetPitchAngle > AngleBoarder && PitchAngle > AngleBoarder)
			{
				float PitchAlpha = PitchAngle / Settings.PitchUpMaxAngle;
				const FVector2D TargetSpeed = Math::Lerp(Settings.IdleTargetMoveSpeed, Settings.PitchUpTargetMoveSpeed, PitchAlpha);
				DebugAlphaValue = PitchAlpha;
				TargetMoveSpeed = TargetSpeed;

				// PitchAlpha = Settings.PitchTargetMoveSpeedAcceleration.GetFloatValue(PitchAlpha);
				// DebugAlphaFinalValue = PitchAlpha;

				// TargetMoveSpeed.X = Math::FInterpTo(TargetMoveSpeed.X, TargetSpeed.X, DeltaTime, PitchAlpha);
				// TargetMoveSpeed.Y = Math::FInterpTo(TargetMoveSpeed.Y, TargetSpeed.Y, DeltaTime, PitchAlpha);
			}

			// Idle target move speed
			else
			{
				if(PitchAngle < -AngleBoarder)
				{
					float PitchAlpha = (Math::Abs(PitchAngle) / Settings.PitchDownMaxAngle);
					const FVector2D TargetSpeed = Math::Lerp(Settings.IdleTargetMoveSpeed, TargetMoveSpeed, PitchAlpha);

					TargetMoveSpeed = TargetSpeed;
					// TargetMoveSpeed.X = Math::FInterpTo(TargetMoveSpeed.X, TargetSpeed.X, DeltaTime, 1);
					// TargetMoveSpeed.Y = Math::FInterpTo(TargetMoveSpeed.Y, TargetSpeed.Y, DeltaTime, 1);
				}
				else if(PitchAngle > AngleBoarder)
				{
					float PitchAlpha = PitchAngle / Settings.PitchUpMaxAngle;
					const FVector2D TargetSpeed = Math::Lerp(Settings.IdleTargetMoveSpeed, TargetMoveSpeed, PitchAlpha);

					TargetMoveSpeed = TargetSpeed;
					// TargetMoveSpeed.X = Math::FInterpTo(TargetMoveSpeed.X, TargetSpeed.X, DeltaTime, 1);
					// TargetMoveSpeed.Y = Math::FInterpTo(TargetMoveSpeed.Y, TargetSpeed.Y, DeltaTime, 1);
				}
				else
				{
					TargetMoveSpeed = Settings.IdleTargetMoveSpeed;
					// TargetMoveSpeed.X = Math::FInterpTo(TargetMoveSpeed.X, Settings.IdleTargetMoveSpeed.X, DeltaTime, 1.0);
					// TargetMoveSpeed.Y = Math::FInterpTo(TargetMoveSpeed.Y, Settings.IdleTargetMoveSpeed.Y, DeltaTime, 1.0);
				}
			}
		}

		float RubberBandTargetBonusSpeed = TargetMoveSpeed.X * WingSuitComp.RubberBandSpeedBonus;

		// Update the move speed
		{
			float HorizontalTargetSpeed = TargetMoveSpeed.X;
			HorizontalTargetSpeed += RubberBandTargetBonusSpeed;
		
			// Pitch up
			if(PitchAngle > AngleBoarder)
			{						
				if(TargetMoveSpeed.X >= CurrentHorizontalMoveSpeed.Value)
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.IncreaseToPitchUpMoveSpeedAccelerationDuration.X, DeltaTime);
				else
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.DecreaseToPitchUpMoveSpeedAccelerationDuration.X, DeltaTime);

				if(TargetMoveSpeed.Y >= CurrentVerticalMoveSpeed.Value)
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.IncreaseToPitchUpMoveSpeedAccelerationDuration.Y, DeltaTime);
				else
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.DecreaseToPitchUpMoveSpeedAccelerationDuration.Y, DeltaTime);
			}

			// Pitch down
			else if(PitchAngle < -AngleBoarder)
			{			
				if(TargetMoveSpeed.X >= CurrentHorizontalMoveSpeed.Value)
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.IncreaseToPitchDownMoveSpeedAccelerationDuration.X, DeltaTime);
				else
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.DecreaseToPitchDownMoveSpeedAccelerationDuration.X, DeltaTime);

				if(TargetMoveSpeed.Y >= CurrentVerticalMoveSpeed.Value)
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.IncreaseToPitchDownMoveSpeedAccelerationDuration.Y, DeltaTime);
				else
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.DecreaseToPitchDownMoveSpeedAccelerationDuration.Y, DeltaTime);

				// Rumble effect
				if(Settings.PitchDownMoveSpeedRumleEffect != nullptr || Settings.PitchDownCameraShake != nullptr)
				{	
					float MoveSpeedForRumble = FVector2D(CurrentHorizontalMoveSpeed.Value, CurrentVerticalMoveSpeed.Value).Size();
					float Strength = Math::Clamp(MoveSpeedForRumble / Settings.PitchDownTargetMoveSpeed.Size(), 0.0, 1.0);
					Strength *= (Math::Abs(PitchAngle) / Settings.PitchDownMaxAngle);

					if(Settings.PitchDownMoveSpeedRumleEffect != nullptr)
					{
						float ForceFeedbackStrength = Settings.PitchDownMoveSpeedRumleAmount.GetFloatValue(Strength);
					
						if(ForceFeedbackStrength > AngleBoarder)
						{
							Player.PlayForceFeedback(Settings.PitchDownMoveSpeedRumleEffect, true, true, this, ForceFeedbackStrength);
							bClearForceFeedBack = false;
						}
					}

					if(Settings.PitchDownCameraShake != nullptr)
					{
						float CameraShakeScale = Settings.PitchDownMoveSpeedCameraShakeScale.GetFloatValue(Strength);

						if(CameraShakeScale > AngleBoarder)
						{
							if(PitchDownCameraShake == nullptr)
								PitchDownCameraShake = Player.PlayCameraShake(Settings.PitchDownCameraShake, this, CameraShakeScale);
							else
								PitchDownCameraShake.ShakeScale = CameraShakeScale;
							bClearCameraShake = false;
						}
					}
				}
			}

			// Idle
			else
			{
				if(TargetMoveSpeed.X >= CurrentHorizontalMoveSpeed.Value)
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.IncreaseToIdleSpeedAccelerationDuration.X, DeltaTime);
				else
					CurrentHorizontalMoveSpeed.AccelerateTo(HorizontalTargetSpeed, Settings.DecreaseToIdleSpeedAccelerationDuration.X, DeltaTime);

				if(TargetMoveSpeed.Y >= CurrentVerticalMoveSpeed.Value)
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.IncreaseToIdleSpeedAccelerationDuration.Y, DeltaTime);
				else
					CurrentVerticalMoveSpeed.AccelerateTo(TargetMoveSpeed.Y, Settings.DecreaseToIdleSpeedAccelerationDuration.Y, DeltaTime);
			}
		}

		if((Settings.GroundDistanceRumbleEffect != nullptr || Settings.GroundDistanceCameraShake != nullptr) && Settings.StartRumbleGroundDistance > 0)
		{
			auto GroundTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			GroundTraceSettings.UseLine();
			// GroundTraceSettings.DebugDrawOneFrame();
		
			FVector TraceFrom = Player.ActorLocation;
			FVector TraceTo = TraceFrom;
			TraceTo -= FVector::UpVector * (MoveComp.GetCollisionShape().Shape.GetSphereRadius() + Settings.StartRumbleGroundDistance);
			auto GroundHit = GroundTraceSettings.QueryTraceSingle(TraceFrom, TraceTo);
			
			if(Settings.GroundDistanceRumbleEffect != nullptr)
			{
				if(GroundHit.bBlockingHit)
					GroundRumbleStrength = Settings.GroundDistanceRumble.GetFloatValue(1.0 - GroundHit.Time);	
				else
					GroundRumbleStrength = Math::FInterpConstantTo(GroundRumbleStrength, 0.0, DeltaTime, 0.2);

				if(GroundRumbleStrength > KINDA_SMALL_NUMBER)
				{
					Player.PlayForceFeedback(Settings.GroundDistanceRumbleEffect, true, true, this, GroundRumbleStrength);
					bClearForceFeedBack = false;
				}
			}
			
			if(Settings.GroundDistanceCameraShake != nullptr)
			{
				if(GroundHit.bBlockingHit)
					GroundCameraShakeScale = Settings.GroundDistanceCameraShakeCurve.GetFloatValue(1.0 - GroundHit.Time);	
				else
					GroundCameraShakeScale = Math::FInterpConstantTo(GroundCameraShakeScale, 0.0, DeltaTime, 0.2);

				if(GroundCameraShakeScale > KINDA_SMALL_NUMBER)
				{
					if(GroundDistanceCameraShake == nullptr)
						GroundDistanceCameraShake = Player.PlayCameraShake(Settings.GroundDistanceCameraShake, this, GroundCameraShakeScale);
					else
						GroundDistanceCameraShake.ShakeScale = GroundCameraShakeScale;
					
					bClearCameraShake = false;
				}
			}
		}

		if(bClearForceFeedBack)
		{
			Player.StopForceFeedback(this);
		}

		if(bClearCameraShake)
		{
			Player.StopCameraShakeByInstigator(this);
			GroundDistanceCameraShake = nullptr;
			PitchDownCameraShake = nullptr;
		}

		if(WingSuitComp.ActiveBarrelRollDirection != 0 && BarrelRollTimeLeft > KINDA_SMALL_NUMBER)
		{
			BarrelRollInterpedInput = Math::VInterpTo(BarrelRollInterpedInput, MoveComp.MovementInput, DeltaTime, 2.0);
			FVector RightVector = WingSuitComp.SyncedHorizontalMovementOrientation.Value.RightVector;
			RightVector = RightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			float BarrelRollAlpha = Math::Clamp(BarrelRollTimeLeft / Settings.BarrelRollActionTime, 0, 1);
			BarrelRollAlpha = Math::EaseInOut(0, 1, BarrelRollAlpha, 2);

			float BarrelRollSpeed = Settings.BarrelRollMovementSpeedBasedOnAlpha.GetFloatValue(BarrelRollAlpha);
			float SpeedMultiplier = Math::Abs(BarrelRollInterpedInput.DotProduct(RightVector));
			BarrelRollSpeed *= SpeedMultiplier;
			Movement.AddVelocity(RightVector * WingSuitComp.ActiveBarrelRollDirection * BarrelRollSpeed);
			
			const float RelativeRollAmount = Settings.BarrelRollRotationBasedOnAlpha.GetFloatValue(BarrelRollAlpha);
			RollAngle = RelativeRollAmount * -WingSuitComp.ActiveBarrelRollDirection;
	
			BarrelRollTimeLeft -= DeltaTime;
			if(BarrelRollTimeLeft <= KINDA_SMALL_NUMBER)
			{
				BarrelRollTimeLeft = 0;
				WingSuitComp.CrumbSetActiveBarrelRollDirection(0);
				StopBarrelRollFrame = Time::FrameNumber;
			}
		}

		const FVector AxisToRotateAround = WingSuitComp.SyncedHorizontalMovementOrientation.Value.RightVector;

		FVector CurrentHorizontalMoveDirection = WingSuitComp.SyncedHorizontalMovementOrientation.Value.ForwardVector;
		CurrentHorizontalMoveDirection = CurrentHorizontalMoveDirection.RotateAngleAxis(WingSuitComp.CurrentPitchOffset, AxisToRotateAround);

		FVector CurrentUpVector = FVector::UpVector;
		CurrentUpVector = CurrentUpVector.RotateAngleAxis(WingSuitComp.CurrentPitchOffset, AxisToRotateAround);

		if(Settings.bLockYawRotation)
		{
			float TargetSidewaysSpeed = (MovementInput.Y * Settings.LockedYawSidewaysMovementSpeed);
			LockedYawSidewaysAcceleratedSpeed.AccelerateTo(TargetSidewaysSpeed, Settings.LockedYawSidewaysAccelerationDuration, DeltaTime);
			Movement.AddVelocity(Player.ActorRightVector * LockedYawSidewaysAcceleratedSpeed.Value);
		}

		Movement.AddVelocity(CurrentHorizontalMoveDirection * CurrentHorizontalMoveSpeed.Value);
		Movement.AddVelocity(CurrentUpVector * CurrentVerticalMoveSpeed.Value);

		const FRotator PitchedDownRotator = FRotator(-WingSuitComp.CurrentPitchOffset, 0.0, 0.0);
		
		WingSuitComp.InterpedRotation = Math::RInterpTo(WingSuitComp.InterpedRotation, FRotator(PitchAngle, 0.0, RollAngle), DeltaTime, 10.0);
		Movement.SetRotation(WingSuitComp.SyncedHorizontalMovementOrientation.Value.Quaternion() * PitchedDownRotator.Quaternion());
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WingSuit");
		WingSuitComp.SyncedInternalRotation.Value = Rot;

		if(WingSuitComp.bHasEverBarrelRolled && Time::FrameNumber == StopBarrelRollFrame)
		{
			InheritMoveCompVelocity();
		}
	}

	void UpdateRemoteMovement(float DeltaTime)
	{
		Movement.ApplyCrumbSyncedAirMovement();
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WingSuit");
	}

	void InheritMoveCompVelocity()
	{
		float NewHorizontalVelocity = MoveComp.HorizontalVelocity.Size();
		// Commented out because it feels bad in beginning of moses tunnel to just clamp the velocity, a smooth lerp feels much better.
		//NewHorizontalVelocity = Math::Max(NewHorizontalVelocity, Settings.IdleTargetMoveSpeed.X);
		CurrentHorizontalMoveSpeed.SnapTo(NewHorizontalVelocity);

		float NewVerticalVelocity = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
		//NewVerticalVelocity = Math::Max(NewVerticalVelocity, Settings.IdleTargetMoveSpeed.Y);
		CurrentVerticalMoveSpeed.SnapTo(NewVerticalVelocity);

		TargetMoveSpeed = FVector2D(NewHorizontalVelocity, NewVerticalVelocity);
	}
}