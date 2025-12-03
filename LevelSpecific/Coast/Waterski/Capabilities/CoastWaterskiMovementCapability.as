class UCoastWaterskiMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 105;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UCoastWaterskiPlayerComponent WaterskiComp;
	UCoastWaterskiWaveCollisionContainerComponent WaveCollisionContainerComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UCoastWaterskiSettings Settings;

	float CurrentSteerSpeed;
	float CurrentWakeSpeed;
	bool bPreviousIsInWater;
	bool bPreviousAirborne;

	float CurrentOffset = 0.0;
	float CurrentOffsetSpeed = 0.0;
	float PreviousOffset = 0.0;
	bool bCurrentlyEasingOut = false;
	float EaseOutStartSpeed = 0.0;
	FHazeAcceleratedFloat AcceleratedBuoyancyAcceleration;
	FHazeAcceleratedFloat AcceleratedDistanceFromAttach;
	FHazeAcceleratedVector AcceleratedAttachPointOrigin;
	FHazeAcceleratedRotator AcceleratedAttachPointRotation;
	FVector EnterVelocity;
	FCoastWaterskiWaveData PreviousWaveData;
	bool bCameFromWingsuit;
	FVector StartLocation;
	float32 InitialFrameDeltaTime;
	bool bHittingGround = false;

	UCameraShakeBase CamShakeLooping;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		WaveCollisionContainerComp = UCoastWaterskiWaveCollisionContainerComponent::GetOrCreate(Game::Mio);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UCoastWaterskiSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WaterskiComp.IsWaterskiing())
			return false;

		if (OceanWaves::GetOceanWavePaint() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!WaterskiComp.IsWaterskiing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialFrameDeltaTime = GetCapabilityDeltaTime();
		bCameFromWingsuit = WaterskiComp.bLastEnterCameFromWingsuit;
		WaterskiComp.bLastEnterCameFromWingsuit = false;
		EnterVelocity = Player.GetRawLastFrameTranslationVelocity();
		StartLocation = Player.ActorLocation;
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 60.0, this);
		AcceleratedAttachPointOrigin.SnapTo(AttachPoint.WorldLocation);
		AcceleratedAttachPointRotation.SnapTo(AttachPoint.WorldRotation);

		AcceleratedDistanceFromAttach.SnapTo(Player.ActorLocation.DistXY(AcceleratedAttachPointOrigin.Value));
		FVector Dir = (Player.ActorLocation - AcceleratedAttachPointOrigin.Value).GetSafeNormal2D();
		CurrentWorldRadians = Direction3DToRadians(Dir);
		
		AcceleratedBuoyancyAcceleration.SnapTo(WaterskiComp.IsInWater() ? Settings.BuoyancyAccelerationSpeed : Settings.BuoyancyMinAccelerationSpeed);

		MoveComp.OverrideResolver(UCoastWaterskiMovementResolver, this);

		if(OceanWaves::GetOceanWavePaint().TargetLandscape != nullptr)
		{
			MoveComp.AddMovementIgnoresActor(this, OceanWaves::GetOceanWavePaint().TargetLandscape);
			WaterskiComp.WaterLandscape = OceanWaves::GetOceanWavePaint().TargetLandscape;
		}

		for(UCoastWaterskiWaveCollisionComponent Comp : WaveCollisionContainerComp.WaveCollisionComponents)
		{
			MoveComp.AddMovementIgnoresActor(this, Comp.Owner);
		}

		PreviousOffset = 0.0;
		PreviousWaveData = WaterskiComp.WaveData;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
		CurrentSteerSpeed = 0.0;
		CurrentWakeSpeed = 0.0;

		Player.StopCameraShakeByInstigator(this, true);
		CamShakeLooping = nullptr;

		MoveComp.ClearResolverOverride(UCoastWaterskiMovementResolver, this);

		MoveComp.RemoveMovementIgnoresActor(this);

		if(bHittingGround)
			TriggerLeaveGround();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FCoastWaterskiWaveData WaveData = WaterskiComp.WaveData;

				float EnterAlpha = Math::Saturate(ActiveDuration / Settings.EnterLerpDuration);
				EnterAlpha = Math::EaseInOut(0.0, 1.0, EnterAlpha, 2.0);
				if(!bCameFromWingsuit)
					EnterAlpha = 1.0;
				AcceleratedAttachPointOrigin.AccelerateTo(AttachPoint.WorldLocation, 1.0, DeltaTime);
				AcceleratedAttachPointRotation.AccelerateTo(AttachPoint.WorldRotation, 1.0, DeltaTime);
				DistanceFromAttach = AcceleratedDistanceFromAttach.AccelerateTo(WaterskiComp.GetTargetLineLength(), Settings.LineLengthAccelerationDuration, DeltaTime);
				
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(0));

#if !RELEASE
				FTemporalLog TemporalLog = TEMPORAL_LOG(this);
				TemporalLog.Value("DistanceFromAttach", DistanceFromAttach);
				TemporalLog.Value("EnterAlpha", EnterAlpha);
				TemporalLog.Value("Target Line Length", WaterskiComp.GetTargetLineLength());
#endif
	
				Movement.AddPendingImpulses();

				HandleBoostOffset(DeltaTime);
				FVector HorizontalPoint = GetWaterskiHorizontalTargetLocation(DeltaTime);
				FVector WingsuitPoint = StartLocation + EnterVelocity * (ActiveDuration + InitialFrameDeltaTime);
				FVector Point = Math::Lerp(WingsuitPoint, HorizontalPoint, EnterAlpha);
				FVector Delta = Point - Player.ActorLocation;
				Movement.AddDelta(Delta, EMovementDeltaType::HorizontalExclusive);
#if !RELEASE
				TemporalLog.Point("Horizontal Point", HorizontalPoint, 15.f);
				TemporalLog.Point("Wingsuit Point", WingsuitPoint, 15.f);
				TemporalLog.DirectionalArrow("Horizontal Delta", Player.ActorLocation, Delta, 5.0f);
#endif

				HandleRotation(DeltaTime);

				FHazeFrameForceFeedback ForceFeedback;
				float Size = Math::Lerp(0.008, 0.35, MoveComp.MovementInput.Size());

				if(WaterskiComp.IsAirborne())
				{
					Size = 0;
				}

				if(MoveComp.HasGroundContact())
				{
					Size = Math::Lerp(0.2, 0.2, MoveComp.MovementInput.Size());
				}

				ForceFeedback.RightMotor = Size;
				Player.SetFrameForceFeedback(ForceFeedback);

				// Size = Math::Lerp(0.0, 1, MoveComp.MovementInput.Size());
				
				if(WaterskiComp.IsAirborne())
				{
					Player.StopCameraShakeByInstigator(this, false);
					CamShakeLooping = nullptr;
				}
				else if(CamShakeLooping == nullptr)
				{
					CamShakeLooping = Player.PlayCameraShake(WaterskiComp.WaterSkiCamShakeLooping, this, 0.5);
				}

				// if(CamShakeLooping == nullptr)
				// {
				// 	CamShakeLooping = Player.PlayCameraShake(WaterskiComp.WaterSkiCamShakeLooping, this, Size);
				// }
				// else
				// {
				// 	CamShakeLooping.ShakeScale = Size;
				// }

				
				bool bUseNewBuoyancy = true;
				if(bUseNewBuoyancy)
				{
					NewHandleVerticalSpeed(WaveData, DeltaTime);
				}
				else
				{
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration(false);
					HandleBuoyancy(DeltaTime, WaveData);
				}

				TriggerEnterExitEffects();
				PreviousWaveData = WaveData;
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			TriggerImpactEffects();

			FName AnimTag = n"Waterski";
			if(WaterskiComp.IsAirborne() || (Time::GetGameTimeSince(WaterskiComp.TimeOfJump) < 0.5 && MoveComp.VerticalSpeed > 0.0))
				AnimTag = n"WaterskiAirMovement";
			else if(bPreviousAirborne)
				AnimTag = n"WaterskiLanding";

			// if(WaterskiComp.FrameOfStopTransitionFromWingsuit.IsSet() && Time::FrameNumber == WaterskiComp.FrameOfStopTransitionFromWingsuit.Value)
			// 	AnimTag = n"WaterskiLanding";

			bPreviousAirborne = WaterskiComp.IsAirborne();

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
			
			// if(!WaterskiComp.IsWaterskiRopeBlocked())
			// 	DrawTempSkiRope();
		}
	}

	void NewHandleVerticalSpeed(FCoastWaterskiWaveData WaveData, float DeltaTime)
	{
		float VerticalSpeed = MoveComp.Velocity.DotProduct(FVector::UpVector);
		const float WaveHeight = WaveData.PointOnWave.Z;
		const float WaterLineHeight = Player.ActorLocation.Z;

		if(!MoveComp.HasGroundContact() && WaveHeight > WaterLineHeight && !WaterskiComp.bCurrentlyJumping)
		{
			const float Diff = WaveHeight - WaterLineHeight;

			float BuoyancyFactor = Math::GetMappedRangeValueClamped(FVector2D(0, Player.CapsuleComponent.ScaledCapsuleHalfHeight * 0.25), FVector2D(0, 1), Diff);

			float BuoyancyAcceleration = BuoyancyFactor * 5;
			if(IsGoingUpWave(WaveData))
				BuoyancyAcceleration = BuoyancyFactor * 30;

			const float BuoyancySpeed = Math::Lerp(100, 1000, BuoyancyFactor);

			VerticalSpeed = Math::FInterpTo(VerticalSpeed, BuoyancySpeed, DeltaTime, BuoyancyAcceleration);

			// if(IsGoingUpWave(WaveData))
			// {
			// 	VerticalSpeed += (WaveData.PointOnWave.Z - PreviousWaveData.PointOnWave.Z) / DeltaTime;
			// }

#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("Buoyancy;Is Going Up Wave", IsGoingUpWave(WaveData));
			TemporalLog.Value("Buoyancy;Diff", Diff);
			TemporalLog.Value("Buoyancy;Buoyancy Force", BuoyancyFactor);
			TemporalLog.Value("Buoyancy;InterpSpeed", BuoyancyAcceleration);
			TemporalLog.Value("Buoyancy;VerticalSpeed", VerticalSpeed);
			TemporalLog.Value("Buoyancy;Max Speed", BuoyancySpeed);
#endif
		}
		else
		{
			// Gravity
			VerticalSpeed -= MoveComp.GravityForce * DeltaTime;
		}

		Movement.AddVelocity(FVector::UpVector * VerticalSpeed);
	}

	void HandleBoostOffset(float DeltaTime)
	{
		// Accelerate
		ACoastWaterskiBoostZone CurrentBoostZone = WaterskiComp.CurrentBoostZone;
		if(CurrentBoostZone != nullptr)
		{
			CurrentOffsetSpeed += CurrentBoostZone.AdditionalAcceleration * DeltaTime;
			CurrentOffsetSpeed = Math::Min(CurrentOffsetSpeed, CurrentBoostZone.AdditionalMaxSpeed);
			CurrentOffset += CurrentOffsetSpeed * DeltaTime;
			bCurrentlyEasingOut = false;
		}
		else if(CurrentOffset > 0.0) // Decelerate
		{
			if(!bCurrentlyEasingOut)
			{
				CurrentOffsetSpeed -= Settings.BoostZoneDecelerationSpeed * DeltaTime;
				CurrentOffsetSpeed = Math::Max(CurrentOffsetSpeed, Settings.BoostZoneMinSpeed);
			}
			else
			{
				float Alpha = CurrentOffset / Settings.BoostZoneEaseOutStartDistance;
				CurrentOffsetSpeed = Math::Lerp(0.0, EaseOutStartSpeed, Math::Saturate(Alpha));
			}

			CurrentOffset += CurrentOffsetSpeed * DeltaTime;

			if(!bCurrentlyEasingOut && CurrentOffsetSpeed < 0.0 && CurrentOffset <= Settings.BoostZoneEaseOutStartDistance)
			{
				bCurrentlyEasingOut = true;
				EaseOutStartSpeed = CurrentOffsetSpeed;
			}
			
			if(CurrentOffset <= 0.0)
			{
				CurrentOffset = 0.0;
				CurrentOffsetSpeed = 0.0;
				return;
			}
		}
	}

	void HandleRotation(float DeltaTime)
	{
		Movement.InterpRotationTo(FQuat::MakeFromXZ(AcceleratedAttachPointRotation.Value.ForwardVector, FVector::UpVector), 100.0);

		FCoastWaterskiWaveData WaveData = WaterskiComp.WaveData;

		FRotator TargetRotation = FRotator();
		float InterpSpeed = -1.0;

		// if(WaterskiComp.IsInWater())
		// {
		// 	// In water
		// 	TargetRotation = FRotator::MakeFromZX(WaveData.PointOnWaveNormal, Player.ActorForwardVector);
		// 	InterpSpeed = 5.0;
		// }
		// else if(MoveComp.HasGroundContact())
		// {
		// 	// Grounded
		// 	TargetRotation = FRotator::MakeFromZX(MoveComp.GroundContact.ImpactNormal, Player.ActorForwardVector);
		// 	InterpSpeed = 5.0;
		// }
		// else
		// {
		// 	// Airborne
		// 	TargetRotation = FRotator::MakeFromZX(FVector::UpVector, Player.ActorForwardVector);
		// 	InterpSpeed = 1.0;
		// }

		// if(InterpSpeed >= 0.0)
		// 	Player.MeshOffsetComponent.WorldRotation = Math::RInterpShortestPathTo(Player.MeshOffsetComponent.WorldRotation, TargetRotation, DeltaTime, InterpSpeed);
	}

	void TriggerEnterExitEffects()
	{
		bool bIsInWater = WaterskiComp.IsInWater();
		if(bIsInWater && !bPreviousIsInWater)
		{
			CrumbOnHitWaterSurface();
		}
		if(!bIsInWater && bPreviousIsInWater)
		{
			CrumbOnLeaveWaterSurface();
		}

		bPreviousIsInWater = bIsInWater;
	}

	void TriggerImpactEffects()
	{
		if(MoveComp.NewStateIsOnWalkableGround())
		{
			TriggerHitGround();
		}

		if(MoveComp.NewStateIsInAir())
		{
			TriggerLeaveGround();
		}

		bool bWall = MoveComp.HasImpactedWall() && !MoveComp.PreviousHadWallContact();
		bool bCeiling = MoveComp.HasImpactedCeiling() && !MoveComp.PreviousHadCeilingContact();
		if(bWall || bCeiling)
		{
			FCoastWaterskiOnCollidedParams Params;
			FHitResult Hit = bWall ? MoveComp.AllWallImpacts[0] : MoveComp.AllCeilingImpacts[0];
			Params.ImpactLocation = Hit.ImpactPoint;
			Params.Speed = Math::Abs(MoveComp.HorizontalVelocity.DotProduct(-Hit.Normal));
			Params.WaterskiComp = WaterskiComp;
			Params.WaterskiPlayer = Player;
			Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
			Params.RightWaterski = WaterskiComp.WaterskiActors[1];
			UCoastWaterskiEffectHandler::Trigger_OnCollided(Player, Params);
		}
	}

	void TriggerHitGround()
	{
		FCoastWaterskiOnHitGroundParams Params;
		Params.ImpactLocation = MoveComp.AllGroundImpacts[0].ImpactPoint;
		Params.Speed = MoveComp.VerticalSpeed;
		Params.WaterskiComp = WaterskiComp;
		Params.WaterskiPlayer = Player;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		UCoastWaterskiEffectHandler::Trigger_OnHitGround(Player, Params);
		Print(f"{Player.Name} HitGround", 5.f, FLinearColor::Green);
		bHittingGround = true;
	}

	void TriggerLeaveGround()
	{
		FCoastWaterskiOnLeaveGroundParams Params;
		Params.WaterskiComp = WaterskiComp;
		Params.WaterskiPlayer = Player;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		UCoastWaterskiEffectHandler::Trigger_OnLeaveGround(Player, Params);
		Print(f"{Player.Name} LeaveGround", 5.f, FLinearColor::Red);
		bHittingGround = false;
	}

	bool IsGoingUpWave(FCoastWaterskiWaveData WaveData, float AngleThreshold = 0) const
	{
		const float ForwardSpeedAlongWave = GetForwardSpeed(WaveData.PointOnWaveNormal);

		if(ForwardSpeedAlongWave < 500)
			return false;	// Going too slow

		const FVector WaveNormal = WaveData.PointOnWaveNormal;
		const FVector HorizontalVelocityDirection = MoveComp.HorizontalVelocity.GetSafeNormal();
		const float WaveAngle = WaveNormal.GetAngleDegreesTo(HorizontalVelocityDirection);

		// If the wave normal is pointing in the direction of travel, we are not going up a wave
		if(WaveAngle < 90 + AngleThreshold)
			return false;

		return true;
	}

	FVector GetHorizontalForward(FVector UpDir) const
	{
		return Player.ActorForwardVector.VectorPlaneProject(UpDir).GetSafeNormal();
	}

	float GetForwardSpeed(FVector UpDir) const
	{
		return MoveComp.Velocity.DotProduct(GetHorizontalForward(UpDir));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnHitWaterSurface()
	{
		FCoastWaterskiOnHitWaterSurfaceParams Params;
		Params.Speed = MoveComp.VerticalSpeed;
		Params.WaterskiComp = WaterskiComp;
		Params.WaterskiPlayer = Player;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		Params.SurfaceLocation = WaterskiComp.WaveData.PointOnWave;
		UCoastWaterskiEffectHandler::Trigger_OnHitWaterSurface(Player, Params);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnLeaveWaterSurface()
	{
		FCoastWaterskiGeneralParams Params;
		Params.WaterskiComp = WaterskiComp;
		Params.WaterskiPlayer = Player;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		Params.SurfaceLocation = WaterskiComp.WaveData.PointOnWave;
		UCoastWaterskiEffectHandler::Trigger_OnLeaveWaterSurface(Player, Params);
	}

	void HandleBuoyancy(float DeltaTime, FCoastWaterskiWaveData WaveData)
	{
		// Debug::DrawDebugSphere(WaveData.PointOnWave, 50.0, 12, FLinearColor::Red);

		const float VerticalSpeed = MoveComp.VerticalSpeed;
		const float VerticalDelta = VerticalSpeed * DeltaTime;

		AcceleratedBuoyancyAcceleration.AccelerateTo(WaterskiComp.IsInWater() ? Settings.BuoyancyAccelerationSpeed : Settings.BuoyancyMinAccelerationSpeed, Settings.BuoyancyAccelerationLerpDuration, DeltaTime);
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Current Buoyancy Acceleration", AcceleratedBuoyancyAcceleration.Value)
			.Value("Is In Water", WaterskiComp.IsInWater())
			.Point("Wave Point", WaveData.PointOnWave);
#endif

		if(Player.ActorLocation.Z > WaveData.PointOnWave.Z)
		{
			if((Player.ActorLocation.Z + VerticalDelta) < WaveData.PointOnWave.Z)
			{
				// Current move will result in the player being under a wave, place the player on top of the wave since the downwards speed is lower than threshold

				float SpeedToDeduct = -Settings.VerticalSpeedToDeductWhenHittingSurface;
				if(Math::Abs(VerticalSpeed) < Math::Abs(SpeedToDeduct))
				{
					SpeedToDeduct = VerticalSpeed;
				}

				if(Settings.VerticalSpeedPercentageToDeductWhenHittingSurface > 0.0)
				{
					SpeedToDeduct = (Settings.VerticalSpeedPercentageToDeductWhenHittingSurface * VerticalSpeed);
				}
				
				FVector VelocityToDeduct = FVector::UpVector * -SpeedToDeduct;
				Movement.AddVelocity(VelocityToDeduct);

				FVector Delta = (WaveData.PointOnWave - Player.ActorLocation) +
					FVector::UpVector * KINDA_SMALL_NUMBER;
				Movement.AddDeltaWithCustomVelocity(Delta, FVector::ZeroVector);

#if !RELEASE
				FTemporalLog TemporalLog = TEMPORAL_LOG(this);
				TemporalLog
				.DirectionalArrow("Buoyancy Delta", Player.ActorLocation, Delta, 5.0f)
				.DirectionalArrow("Buoyancy Velocity To Deduct", Player.ActorLocation, VelocityToDeduct, 5.0f);
#endif
			}
			return;
		}

		float Alpha = (WaveData.PointOnWave.Z - Player.ActorLocation.Z) / Settings.BuoyancyAlphaDistance;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		
		float CurrentAccelerationSize = (MoveComp.GravityForce + AcceleratedBuoyancyAcceleration.Value * Alpha) * DeltaTime;
		FVector AccelerationVector = WaveData.PointOnWaveNormal * CurrentAccelerationSize;
		Movement.AddVelocity(AccelerationVector);
		float NewSpeed = MoveComp.VerticalSpeed + CurrentAccelerationSize;
		if(NewSpeed > Settings.BuoyancyMaxVerticalSpeed)
		{
			FVector Velocity = -FVector::UpVector * (NewSpeed - Settings.BuoyancyMaxVerticalSpeed);
			Movement.AddVelocity(Velocity);

#if !RELEASE
			TEMPORAL_LOG(this).DirectionalArrow("Max Buoyancy Clamp Compensation Velocity", Player.ActorLocation, Velocity, 5.0f);
#endif
		}

#if !RELEASE
		TEMPORAL_LOG(this).DirectionalArrow("Buoyancy Acceleration", Player.ActorLocation, AccelerationVector, 5.0f);
#endif
	}

	USceneComponent GetAttachPoint() property
	{
		return WaterskiComp.CurrentWaterskiAttachPoint;
	}

	FVector GetWaterskiHorizontalTargetLocation(float DeltaTime)
	{
		float SteerbackTorque = GetSteerbackTorque(DeltaTime);
		float InputTorque = GetInputTorque(DeltaTime);

		float CurrentSpeed = SteerbackTorque + InputTorque;
		CurrentSpeed = Math::Clamp(CurrentSpeed, -Settings.MaxHorizontalSpeed, Settings.MaxHorizontalSpeed);

		CurrentSpeed /= DistanceFromAttach;
		CurrentWorldRadians += CurrentSpeed * DeltaTime;

		CurrentWorldRadians = Math::UnwindRadians(CurrentWorldRadians);

		FVector NewPoint = AcceleratedAttachPointOrigin.Value + AcceleratedAttachPointRotation.Value.ForwardVector * CurrentOffset + RadiansToDirection3D(CurrentWorldRadians) * DistanceFromAttach;

		PreviousOffset = CurrentOffset;
		return NewPoint;
	}

	float GetSteerbackTorque(float DeltaTime)
	{
		FVector PlayerLocationWithoutOffset = Player.ActorLocation - AcceleratedAttachPointRotation.Value.ForwardVector * PreviousOffset;
		FVector PlayerToAttachDir = (AcceleratedAttachPointOrigin.Value - PlayerLocationWithoutOffset).GetSafeNormal2D();
		FVector PlayerToAttachDirAttachSpace = FTransform(AcceleratedAttachPointRotation.Value, AcceleratedAttachPointOrigin.Value).InverseTransformVectorNoScale(PlayerToAttachDir);
		const float CurrentAngleOffsetRad = -Direction3DToRadians(PlayerToAttachDirAttachSpace);
		const float CurrentAngleOffsetDeg = Math::RadiansToDegrees(CurrentAngleOffsetRad);

		float SteerbackMultiplier = Math::GetMappedRangeValueClamped(FVector2D(-Settings.MaxWaterskiAngles, Settings.MaxWaterskiAngles), FVector2D(-1.0, 1.0), CurrentAngleOffsetDeg);

		//float SteerSpeed = WaterskiComp.IsAirborne() ? Settings.AirSteerSpeed : Settings.SteerSpeed;

		float CurrentAngularSteerbackSpeed = SteerbackMultiplier * Math::DegreesToRadians(Settings.SteerSpeed);
		return CurrentAngularSteerbackSpeed;
	}

	float GetInputTorque(float DeltaTime)
	{
		float SteerSpeed = WaterskiComp.IsAirborne() ? Settings.AirSteerSpeed : Settings.SteerSpeed;

		float RelativeMoveSize = -AcceleratedAttachPointRotation.Value.RightVector.DotProduct(MoveComp.MovementInput);
		const float TargetSteerSpeed = RelativeMoveSize * Math::DegreesToRadians(SteerSpeed);
		CurrentSteerSpeed = Math::FInterpTo(CurrentSteerSpeed, TargetSteerSpeed, DeltaTime, Settings.SteerSpeedInterpSpeed);
		return CurrentSteerSpeed;
	}

	void DrawTempSkiRope()
	{
		FVector RightHandLocation = Player.Mesh.GetSocketLocation(n"RightHand");
		FVector LeftHandLocation = Player.Mesh.GetSocketLocation(n"LeftHand");
		FVector BetweenHands = LeftHandLocation + (RightHandLocation - LeftHandLocation) * 0.5;

		Debug::DrawDebugLine(RightHandLocation, LeftHandLocation, FLinearColor::White, 10.0);
		Debug::DrawDebugLine(BetweenHands, AttachPoint.WorldLocation, FLinearColor::White, 3.0);
	}

	float GetCurrentWorldRadians() property
	{
		return WaterskiComp.CurrentWorldRadians;
	}

	void SetCurrentWorldRadians(float Value) property
	{
		WaterskiComp.CurrentWorldRadians = Value;
	}

	float GetDistanceFromAttach() property
	{
		return WaterskiComp.DistanceFromAttach;
	}

	void SetDistanceFromAttach(float Value) property
	{
		WaterskiComp.DistanceFromAttach = Value;
	}

	float Direction3DToRadians(FVector Dir) const
	{
		FVector2D Dir2D = FVector2D(Dir.X, Dir.Y);
		return Math::DirectionToAngleRadians(Dir2D);
	}

	FVector RadiansToDirection3D(float Ang) const
	{
		FVector2D Result = Math::AngleRadiansToDirection(Ang);
		return FVector(Result.X, Result.Y, 0.0);
	}
}