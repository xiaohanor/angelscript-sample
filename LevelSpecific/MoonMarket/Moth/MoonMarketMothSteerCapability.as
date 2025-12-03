class UMoonMarketMothSteerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;

	AMoonMarketMoth Moth;

	float ActivationTime;

	FVector FlyDirection;

	
	float CurrentPitch = 0.0;
	float CurrentRoll = 0.0;

	FHazeAcceleratedFloat AccForwardSpeed;
	FHazeAcceleratedFloat AccSideSpeed;
	FHazeAcceleratedFloat AccVerticalSpeed;

	FHazeAcceleratedVector2D AccMoveInput;
	FRotator Rotation;

	UMoonMarketMothFlyingSettings Settings;

	bool bStartedDisintigrate = false;
	float StartDisintegrateDistance = 700;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Moth = Cast<AMoonMarketMoth>(Owner);
		Settings = Moth.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Moth.IsBeingRidden())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Moth.IsBeingRidden())
			return true;

		// if(Time::GameTimeSeconds - ActivationTime >= Settings.RideDuration)
		// 	return true;

		if(Moth.CurrentSplinePosition.IsAtEnd())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// FVector RelativeLoc = Moth.ActorLocation - Moth.Spline.ActorLocation;
		// Moth.Spline.Spline.SplinePoints[0].RelativeLocation = RelativeLoc;
		// Moth.Spline.Spline.UpdateSpline();
		//Moth.Spline.Spline.SetWorldLocation(Moth.ActorLocation);
		ActivationTime = Time::GameTimeSeconds;

		FlyDirection = Moth.ActorForwardVector;
		AccForwardSpeed.SnapTo(0);
		AccSideSpeed.SnapTo(0);
		AccVerticalSpeed.SnapTo(0);
		AccMoveInput.Value = FVector2D(0,0);
		Rotation = Owner.ActorRotation;
		bStartedDisintigrate = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketMothEventHandler::Trigger_OnMothStopDisintegrating(Moth);
		Moth.ThrowOffRider();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TEMPORAL_LOG(Moth).Transform("SplinePosition", Moth.CurrentSplinePosition.WorldTransform);

		if(!bStartedDisintigrate)
		{
			if(Moth.Spline.Spline.SplineLength - Moth.CurrentSplinePosition.CurrentSplineDistance < StartDisintegrateDistance)
			{
				bStartedDisintigrate = true;
				UMoonMarketMothEventHandler::Trigger_OnMothStartDisintegrating(Moth);
			}
		}

		SplineSteer(DeltaTime);

		FHitResult HitResult = Moth.TraceForWall();
		if(HitResult.IsValidBlockingHit())
		{
			Moth.ThrowOffRider();
		}
	}

	void SplineSteer(float DeltaTime)
	{
		FVector Delta;
		GetSplineDelta(Delta, DeltaTime);
		HandleMothRotation(Moth.Spline.Spline.GetClosestSplineWorldTransformToWorldLocation(Moth.ActorLocation).Rotation.ForwardVector, DeltaTime);
		GetSidewaysDelta(Delta, DeltaTime);
		//GetFlapDelta(Delta, DeltaTime);

		Moth.ActorLocation += Delta;
		Moth.SetActorVelocity(Delta / DeltaTime);

		// if(Moth.CurrentTiltValue.HasControl() && Moth.MoveWillResultInFatalImpact(Delta))
		// {
		// 	Moth.KillMoth();
		// }
	}

	void GetFlapDelta(FVector& Delta, float DeltaTime)
	{
		const float TriangleWave = Math::LogX(Math::Abs(Math::Fmod(ActiveDuration * Moth.Settings.FlapFrequency * 0.5, 1) - 0.5), 2);
		const FTransform TargetTransform = Moth.CurrentSplinePosition.WorldTransform;
		const FVector HorizontalFlapOffset = TargetTransform.Rotation.RightVector * TriangleWave * Moth.Settings.HorizontalFlapDistance;

		const float AnimationCurveValue = Moth.Settings.FlapSpeedCurve.GetFloatValue(Math::Fmod(ActiveDuration * Moth.Settings.FlapFrequency, 1));
		const FVector VerticalFlapOffset = FVector::UpVector * AnimationCurveValue * Moth.Settings.VerticalFlapDistance;

		Delta += HorizontalFlapOffset + VerticalFlapOffset;
	}

	void GetSplineDelta(FVector& Delta, float DeltaTime)
	{
		Moth.CurrentSplineSpeed += Moth.Settings.Acceleration * DeltaTime;
		Moth.CurrentSplineSpeed = Math::Min(Moth.CurrentSplineSpeed, Moth.Settings.FlySpeed);

		Moth.CurrentSplinePosition.Move(Moth.CurrentSplineSpeed * DeltaTime);
		const FTransform TargetTransform = Moth.CurrentSplinePosition.WorldTransform;
		FVector TargetLocation = TargetTransform.Location;

		FVector MothLocationMinusSidewaysMovement = Moth.ActorLocation - Moth.PreviousSidewaysWorldOffset;
		
		//FVector NextLocation = Math::VInterpConstantTo(MothLocationMinusSidewaysMovement, TargetLocation, DeltaTime, Moth.CurrentSplineSpeed);

		Delta = (TargetLocation - MothLocationMinusSidewaysMovement);
	}

	void HandleMothRotation(FVector TargetForward, float DeltaTime)
	{
		float RotationMultiplier = Moth.Settings.SidewaysRotationCurve.GetFloatValue(Math::Abs(Moth.SidewaysDistance.Value) / Moth.Spline.MaxSidewaysDistance);
			
		if(Math::Sign(Moth.CurrentTiltValue.Value) != Math::Sign(Moth.TargetTiltValue.Value) && RotationMultiplier != 1)
			Moth.CurrentTiltValue.Value = 0;
		
		Moth.CurrentTiltValue.Value = Math::FInterpTo(Moth.CurrentTiltValue.Value, Moth.TargetTiltValue.Value, DeltaTime, Moth.Settings.SidewaysInterpSpeed);

		FQuat CurrentTargetRotation = FQuat::MakeFromXZ(TargetForward, FVector::UpVector.RotateAngleAxis(Moth.Settings.SidewaysRollDegrees * -Moth.CurrentTiltValue.Value * RotationMultiplier, TargetForward));
		Moth.ActorRotation = Math::RInterpShortestPathTo(Moth.ActorRotation, CurrentTargetRotation.Rotator(), DeltaTime, Moth.Settings.SplineRotationInterpSpeed);
	}

	void GetSidewaysDelta(FVector& Delta, float DeltaTime)
	{
		Delta -= Moth.PreviousSidewaysWorldOffset;

		const float Sign = Math::Sign(Moth.CurrentTiltValue.Value);
		AccSideSpeed.AccelerateTo(Sign, 1, DeltaTime);
		float CurrentSidewaysSpeed = Moth.Settings.SidewaysSpeed * AccSideSpeed.Value;

		FVector RightNoHeight = Moth.ActorRightVector.GetSafeNormal2D();
		if(HasControl())
		{
			Moth.SidewaysDistance.Value += CurrentSidewaysSpeed * DeltaTime;
			Moth.SidewaysDistance.Value = Math::Clamp(Moth.SidewaysDistance.Value, -Moth.Spline.MaxSidewaysDistance, Moth.Spline.MaxSidewaysDistance);
		}
		FVector SidewaysWorldOffset = RightNoHeight * Moth.SidewaysDistance.Value;
		TEMPORAL_LOG(Moth).Value("Sideways Offset", SidewaysWorldOffset);

		Delta += SidewaysWorldOffset;
		Moth.PreviousSidewaysWorldOffset = SidewaysWorldOffset;
	}

	void FreeSteer(float DeltaTime)
	{
		FVector2D SteerInput = Moth.SteerInput.Value;
		
		if (Moth.GetRider().Player.IsSteeringPitchInverted())
			SteerInput.X *= -1.0;
			
		AccMoveInput.AccelerateTo(SteerInput, Moth.Settings.SidewaysAccelerationDuration, DeltaTime);	
		Rotation.Pitch = Math::Clamp(Rotation.Pitch + (AccMoveInput.Value.X * DeltaTime), -Settings.MaxPitch, Settings.MaxPitch);
		Rotation.Yaw += AccMoveInput.Value.Y * DeltaTime;

		Owner.SetActorRotation(Rotation);

		Moth.GetRider().Player.SetCameraDesiredRotation(Owner.ActorRotation, this);
		
		float TargetForwardSpeed = Settings.FlySpeed;
		AccForwardSpeed.AccelerateTo(TargetForwardSpeed, 0.5, DeltaTime);
		FVector MoveDirection = Owner.ActorForwardVector * AccForwardSpeed.Value;

		FVector MoveDelta = MoveDirection * DeltaTime;
		Owner.AddActorWorldOffset(MoveDelta);
		
		float TargetPitch = Moth.GetRider().Player.ViewRotation.Pitch -90.0;
		CurrentPitch = Math::FInterpTo(CurrentPitch, TargetPitch, DeltaTime, 5.0);
		CurrentRoll = Math::FInterpTo(CurrentRoll, SteerInput.Y * -20.0, DeltaTime, 5.0);
	}
};