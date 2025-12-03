/**
 * This camera allows the player to control where the camera looks,
 * but also applies settings from UJetskiSplineCameraLookComponent
 */
class UJetskiFreeCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(Jetski::Tags::JetskiFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AJetski Jetski;
	UJetskiCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUser;
	UHazeMovementComponent MoveComp;
	
	float FallDuration = 0.0;
	FHazeAcceleratedRotator AccCameraRotation;

	UCameraSettings CameraSettings;
	FHazeAcceleratedFloat AccPitchOffset;
	FHazeAcceleratedFloat AccAdditiveIdealDistance;
	FHazeAcceleratedFloat AccAdditiveFOV;

	bool bHadCameraOverrideOffset = false;
	FRotator CameraOverrideOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		CameraDataComp = UJetskiCameraDataComponent::Get(Jetski);
		MoveComp = UHazeMovementComponent::Get(Jetski);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FallDuration = Jetski.GetMovementState() != EJetskiMovementState::Air ? 0.0 : Jetski.Settings.FreeCameraFallDelay;
		CameraUser = UCameraUserComponent::Get(Jetski.Driver);
		AccCameraRotation.SnapTo(CameraUser.ViewRotation, CameraUser.ViewAngularVelocity);
		CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		CameraSettings = UCameraSettings::GetSettings(Jetski.Driver);

		AccPitchOffset.SnapTo(Jetski.Settings.FreeCameraSurfacePitch);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraSettings.IdealDistance.Clear(this);
		CameraSettings.FOV.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		UpdateFallDuration(DeltaTime);

		LerpSettingsFromCameraLookComponents(DeltaTime);

		UpdatePitchOffset(DeltaTime);

		if(HasCameraOverrideSpline())
			CameraOverrideOffset = Math::RInterpConstantTo(CameraOverrideOffset, GetOverrideCameraOffsetFromSpline(), DeltaTime, 100);
		else
			CameraOverrideOffset = Math::RInterpConstantTo(CameraOverrideOffset, FRotator::ZeroRotator, DeltaTime, 100);

		if(IsActivelyInputting())
		{
			// Always prioritize allowing the player to control the camera
			FVector2D AxisInput = Jetski.Driver.GetCameraInput();
			const float Yaw = AxisInput.X * Jetski.Settings.FreeCameraYawLimit;

			float Pitch = 0;
			if(AxisInput.Y > 0)
				Pitch = AxisInput.Y * Jetski.Settings.FreeCameraPitchLimits.Max;
			else
				Pitch = AxisInput.Y * -Jetski.Settings.FreeCameraPitchLimits.Min;


			FRotator TargetRotation = FRotator(Pitch, Yaw, 0);
			TargetRotation = GetReferenceTransform().TransformRotation(TargetRotation);
			TargetRotation.Roll = 0;

			TargetRotation = GetCameraRelativeRotationOffset().Compose(TargetRotation);

			AccCameraRotation.AccelerateTo(TargetRotation, Jetski.Settings.FreeCameraInputAccelerationDuration, DeltaTime);
			
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
		else if(CameraDataComp.HasLookAtTarget())
		{
			FRotator TargetRotation = GetReferenceTransform().Rotator();
			TargetRotation.Roll = 0;
			TargetRotation = GetCameraRelativeRotationOffset().Compose(TargetRotation);
			AccCameraRotation.AccelerateTo(TargetRotation, Jetski.Settings.FreeCameraInputAccelerationDuration, DeltaTime);
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
		else if(Jetski.bIsAirDiving)
		{
			// Face camera in velocity dir when falling and not inputting
			FRotator VelocityRotation = FRotator::MakeFromXZ(MoveComp.Velocity, MoveComp.WorldUp);
			AccCameraRotation.AccelerateTo(VelocityRotation, Jetski.Settings.FreeCameraFallFollowDuration, DeltaTime);
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
		else if(IsFalling() && MoveComp.HorizontalVelocity.Size() > 1000)
		{
			// Face camera in velocity dir when falling and not inputting
			FRotator VelocityRotation = FRotator::MakeFromXZ(MoveComp.Velocity, MoveComp.WorldUp);
			AccCameraRotation.AccelerateTo(VelocityRotation, Jetski.Settings.FreeCameraFallFollowDuration, DeltaTime);
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
		else if(IsJumping())
		{
			// Super ugly way of getting a camera looking slightly downwards, but hey, it works
			FRotator VelocityRotation = FRotator::MakeFromXZ(MoveComp.HorizontalVelocity, FVector::UpVector);
			FVector ForwardDir = VelocityRotation.RotateVector(FVector(1, 0, -Jetski.Settings.FreeCameraJumpLookDownAmount));
			FRotator Rotation = FRotator::MakeFromXZ(ForwardDir, FVector::UpVector);

			// FB TODO: Do we want to apply the full relative rotation here, or only the yaw from turning?
			Rotation = GetCameraRelativeRotationOffset().Compose(Rotation);

			AccCameraRotation.AccelerateTo(Rotation, Jetski.Settings.FreeCameraFallFollowDuration, DeltaTime);
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
		else
		{
			// Automatically face the camera towards a direction
			AccCameraRotation.AccelerateTo(GetBikeForwardTargetRotation(), Jetski.Settings.FreeCameraFollowDuration, DeltaTime);
			CameraUser.SetInputRotation(AccCameraRotation.Value, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Value("FallDuration", FallDuration);
		TemporalLog.Rotation("AccCameraRotation;Value", AccCameraRotation.Value, Jetski.ActorLocation);
		TemporalLog.Value("AccCameraRotation;Velocity", AccCameraRotation.Velocity);

		TemporalLog.Value("AccPitchOffset;Value", AccPitchOffset.Value);
		TemporalLog.Value("AccPitchOffset;Velocity", AccPitchOffset.Velocity);

		TemporalLog.Value("AccAdditiveIdealDistance;Value", AccAdditiveIdealDistance.Value);
		TemporalLog.Value("AccAdditiveIdealDistance;Velocity", AccAdditiveIdealDistance.Velocity);

		TemporalLog.Value("AccAdditiveFOV;Value", AccAdditiveFOV.Value);
		TemporalLog.Value("AccAdditiveFOV;Velocity", AccAdditiveFOV.Velocity);

		TemporalLog.Value("IsActivelyInputting", IsActivelyInputting());
		TemporalLog.Value("IsSteering", IsSteering());
		TemporalLog.Value("IsFalling", IsFalling());
		TemporalLog.Value("IsJumping", IsJumping());
		TemporalLog.Transform("ReferenceTransform", GetReferenceTransform());
		TemporalLog.Value("CameraOffsetFromSpline", GetCameraOffsetFromSpline());
		TemporalLog.Value("CameraRelativeRotationOffset", GetCameraRelativeRotationOffset());
		TemporalLog.Value("YawOffsetFromTurning", GetYawOffsetFromTurning());
		TemporalLog.Rotation("BikeForwardTargetRotation", GetBikeForwardTargetRotation(), Jetski.ActorLocation);

		TemporalLog.Value("bHadCameraOverrideOffset", bHadCameraOverrideOffset);
		TemporalLog.Rotation("CameraOverrideOffset", CameraOverrideOffset, Jetski.ActorLocation);
#endif
	}

	bool IsActivelyInputting() const
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		return !AxisInput.IsNearlyZero(0.001);
	}

	bool IsSteering() const
	{
		return Math::Abs(GetAttributeFloat(AttributeNames::MoveRight)) > 0.2;
	}

	void UpdateFallDuration(float DeltaTime)
	{
		if(Jetski.GetMovementState() == EJetskiMovementState::Air && MoveComp.Velocity.Z < 0)
			FallDuration += DeltaTime;
		else
			FallDuration = 0.0;
	}

	bool IsFalling() const
	{
		return FallDuration > Jetski.Settings.FreeCameraFallDelay;
	}

	bool IsJumping() const
	{
		if(Jetski.bHasJumpedFromUnderwater)
			return true;

		return false;
	}

	void LerpSettingsFromCameraLookComponents(float DeltaTime)
	{
		const float DistanceAlongSpline = Jetski.JetskiSpline.Spline.GetClosestSplineDistanceToWorldLocation(Jetski.ActorLocation);
		TOptional<FJetskiSplineCameraLookSettings> CameraLookSettings = Jetski.JetskiSpline.GetCameraLookSettingsAtDistanceAlongSpline(DistanceAlongSpline);
		if(!CameraLookSettings.IsSet())
			return;

		AccAdditiveIdealDistance.AccelerateTo(CameraLookSettings.Value.AdditiveIdealDistance, 1, DeltaTime);
		AccAdditiveFOV.AccelerateTo(CameraLookSettings.Value.AdditiveFOV, 1, DeltaTime);

		CameraSettings.IdealDistance.ApplyAsAdditive(AccAdditiveIdealDistance.Value, this, 0, EHazeCameraPriority::High);
		CameraSettings.FOV.ApplyAsAdditive(AccAdditiveFOV.Value, this, 0, EHazeCameraPriority::High);
	}

	void UpdatePitchOffset(float DeltaTime)
	{
		if(CameraDataComp.HasLookAtTarget())
		{
			AccPitchOffset.AccelerateTo(0, 1.0, DeltaTime);
		}
		else if(Jetski.IsUnderwater())
		{
			AccPitchOffset.AccelerateTo(Jetski.Settings.FreeCameraUnderwaterPitch, Jetski.Settings.FreeCameraUnderwaterPitchAccelerateDuration, DeltaTime);
		}
		else
		{
			AccPitchOffset.AccelerateTo(Jetski.Settings.FreeCameraSurfacePitch, Jetski.Settings.FreeCameraSurfacePitchAccelerateDuration, DeltaTime);
		}
	}

	FTransform GetReferenceTransform() const
	{
		FQuat Rotation = Jetski.ActorQuat;

		if(CameraDataComp.HasLookAtTarget())
		{
			FVector ToLookAtTarget = CameraDataComp.GetLookAtTarget().ActorLocation - Jetski.ActorLocation;
			Rotation = FQuat::MakeFromZX(FVector::UpVector, ToLookAtTarget);
		}

		return FTransform(Rotation, Jetski.ActorLocation);
	}

	FRotator GetCameraOffsetFromSpline() const
	{
		const float DistanceAlongSpline = Jetski.JetskiSpline.Spline.GetClosestSplineDistanceToWorldLocation(Jetski.ActorLocation);
		return Jetski.JetskiSpline.GetCameraRotationOffsetAtDistanceAlongSpline(DistanceAlongSpline);
	}

	FRotator GetOverrideCameraOffsetFromSpline() const
	{
		const float DistanceAlongSpline = Jetski.CameraOverrideSplines.Get().Spline.GetClosestSplineDistanceToWorldLocation(Jetski.ActorLocation);

		const float Alignment = Jetski.ActorVelocity.GetSafeNormal().DotProduct(Jetski.CameraOverrideSplines.Get().Spline.GetWorldForwardVectorAtSplineDistance(DistanceAlongSpline));
		if(Alignment < 0)
			return FRotator::ZeroRotator;

		FRotator CameraOffset = Jetski.CameraOverrideSplines.Get().GetCameraRotationOffsetAtDistanceAlongSpline(DistanceAlongSpline);
		return CameraOffset * Alignment;
	}

	FRotator GetCameraRelativeRotationOffset() const
	{
		FRotator RelativeOffset = FRotator::ZeroRotator;

		RelativeOffset += FRotator(AccPitchOffset.Value, GetYawOffsetFromTurning(), 0);

		RelativeOffset += GetCameraOffsetFromSpline();
		RelativeOffset += CameraOverrideOffset;

		return RelativeOffset;
	}

	float GetYawOffsetFromTurning() const
	{
		const float CameraYawLead = Jetski.AngularSpeed * -Jetski.Settings.FreeCameraLeadAmount;
		return CameraYawLead;
	}

	FRotator GetBikeForwardTargetRotation() const
	{
		return GetCameraRelativeRotationOffset().Compose(Jetski.ActorRotation);
	}

	bool HasCameraOverrideSpline() const
	{
		return Jetski.CameraOverrideSplines.Get() != nullptr;
	}
}