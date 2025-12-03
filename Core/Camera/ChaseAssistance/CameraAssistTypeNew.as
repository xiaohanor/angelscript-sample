
class UCameraFollowAssistTypeNew : UCameraAssistType
{
	void Apply(
		float DeltaTime,
		float ScriptMultiplier,
		FCameraAssistSettingsData Settings,
	    FHazeActiveCameraAssistData& Data,
		FHazeCameraTransform& OutResult) const override
	{
		if(Settings.Settings.bResetRotateSpeedOnInputStop)
		{
			const bool bCameraInput = !Settings.CameraInput.IsNearlyZero();
			const bool bReleasedCameraInputThisFrame = bCameraInput && Settings.LastCameraInputFrame == Time::FrameNumber - 1;
			const bool bRecentlyReleasedCameraInput = Time::GetRealTimeSince(Settings.LastCameraInputTime) < Settings.Settings.RegainAfterInputStopDelay;

			if(!bCameraInput && (bReleasedCameraInputThisFrame || bRecentlyReleasedCameraInput))
			{
				Data.ResetYaw();
				Data.ResetPitch();
				return;
			}
		}

		FRotator LocalRotationSpeed;

		if(ApplyYaw(DeltaTime, ScriptMultiplier, Settings, Data))
			LocalRotationSpeed.Yaw += Data.YawRotationSpeed.Value;
		else
			Data.ResetYaw();

		if(ApplyPitch(DeltaTime, Settings, Data))
			LocalRotationSpeed.Pitch += Data.PitchRotationSpeed.Value;
		else
			Data.ResetPitch();

		OutResult.AddLocalDesiredDeltaRotation(LocalRotationSpeed * DeltaTime);
	}

	bool ApplyYaw(
		float DeltaTime,
		float ScriptMultiplier,
		FCameraAssistSettingsData Settings,
	    FHazeActiveCameraAssistData& Data) const
	{
		if(Settings.Settings.bYawResetRotateSpeedOnActivate && Settings.ActiveDuration < KINDA_SMALL_NUMBER)
			return false;

		if(Settings.Settings.bYawResetRotateSpeedOnInput && !Settings.CameraInput.IsNearlyZero())
			return false;

		if(!Settings.bApplyYaw)
		{
			Data.YawRotationSpeed.AccelerateTo(0, Settings.Settings.YawStopRotationSpeedDuration, DeltaTime);
			return true;
		}

		if(Settings.Settings.bRequireMovementInput && Settings.MovementInputRaw.IsNearlyZero())
		{
			// Not trying to move, slow down the rotation
			Data.YawRotationSpeed.AccelerateTo(0, 0.5, DeltaTime);
		}
		else
		{
			const FVector ViewRight = Settings.LocalViewRotation.RightVector;	
			float TargetYawSpeed = GetTargetYawSpeed(ViewRight, ScriptMultiplier, Settings);
			TargetYawSpeed *= Math::Sign(Settings.LocalUserVelocity.DotProduct(ViewRight));

			const bool bHasTargetYawSpeed = !Math::IsNearlyZero(TargetYawSpeed);
			const bool bHadTargetYawSpeed = !Math::IsNearlyZero(Data.YawRotationSpeed.Value);

			if(Settings.Settings.YawSwitchDirectionStopDuration > KINDA_SMALL_NUMBER)
			{
				const bool bSwitchedDirection = bHasTargetYawSpeed && bHadTargetYawSpeed && Math::Sign(TargetYawSpeed) != Math::Sign(Data.YawRotationSpeed.Value);

				if(bSwitchedDirection)
					Data.YawSwitchDirectionTime = Time::RealTimeSeconds;

				if(Time::GetRealTimeSince(Data.YawSwitchDirectionTime) < Settings.Settings.YawSwitchDirectionStopDuration)
				{
					// Slow down to a full stop
					Data.YawRotationSpeed.AccelerateTo(0, Settings.Settings.YawSwitchDirectionStopDuration, DeltaTime);
					return true;
				}
			}
			else if(Settings.Settings.YawSwitchDirectionStopDuration > -KINDA_SMALL_NUMBER)
			{
				const bool bSwitchedDirection = bHasTargetYawSpeed && bHadTargetYawSpeed && Math::Sign(TargetYawSpeed) != Math::Sign(Data.YawRotationSpeed.Value);

				if(bSwitchedDirection)
					Data.YawRotationSpeed.SnapTo(0);
			}

			if(!bHasTargetYawSpeed)
			{
				// No target, slow down fast
				Data.YawRotationSpeed.AccelerateTo(TargetYawSpeed, Settings.Settings.YawStopRotationSpeedDuration, DeltaTime);
			}
			else if(Math::Sign(TargetYawSpeed) != Math::Sign(Data.YawRotationSpeed.Value))
			{
				// Wrong direction, accelerate
				Data.YawRotationSpeed.AccelerateTo(TargetYawSpeed, Settings.Settings.YawDecreaseRotationSpeedDuration, DeltaTime);
			}
			else if(Math::Abs(TargetYawSpeed) > Math::Abs(Data.YawRotationSpeed.Value))
			{
				// Accelerating, be quite slow
				Data.YawRotationSpeed.AccelerateTo(TargetYawSpeed, Settings.Settings.YawIncreaseRotationSpeedDuration, DeltaTime);
			}
			else
			{
				// Decelerating, be quite fast
				Data.YawRotationSpeed.AccelerateTo(TargetYawSpeed, Settings.Settings.YawDecreaseRotationSpeedDuration, DeltaTime);
			}
		}

		return true;
	}

	float GetTargetYawSpeed(
		FVector ViewRight,
		float ScriptMultiplier,
		FCameraAssistSettingsData Settings) const
	{
		float Multiplier = ScriptMultiplier * Settings.ContextualMultiplier * Settings.InputMultiplier;
		const float VelocityAlpha = Settings.LocalUserVelocity.GetSafeNormal().DotProductLinear(ViewRight);
		Multiplier *= VelocityAlpha;

		float MoveVelocityMultiplier = 1;
		if(Settings.Settings.MaxUserVelocity > 0)
			MoveVelocityMultiplier = Math::Min(Settings.LocalUserVelocity.Size() / Settings.Settings.MaxUserVelocity, 1);

		const FVector ViewForward = Settings.LocalViewRotation.ForwardVector.VectorPlaneProject(Settings.UserWorldUp).GetSafeNormal();	
		const float ForwardDir = Math::Sign(Settings.LocalUserRotation.ForwardVector.DotProduct(ViewForward));

		if(ForwardDir >= 0)
			Multiplier = Settings.Settings.ForwardMovementMultiplier.GetFloatValue(Multiplier, Multiplier);
		else
			Multiplier = Settings.Settings.BackwardMovementMultiplier.GetFloatValue(Multiplier, Multiplier);

		return Settings.Settings.RotationSpeed * Multiplier * MoveVelocityMultiplier;
	}

	bool ApplyPitch(
		float DeltaTime,
		FCameraAssistSettingsData Settings,
	    FHazeActiveCameraAssistData& Data) const
	{
		if(!Settings.Settings.bApplyPitch)
			return false;

		// Never adjust pitch while giving camera input
		if(!Settings.CameraInput.IsNearlyZero())
			return false;

		if(Settings.Settings.bPitchResetRotateSpeedOnActivate && Settings.ActiveDuration < KINDA_SMALL_NUMBER)
			return false;

		if(!Settings.bApplyPitch)
		{
			Data.PitchRotationSpeed.AccelerateTo(0, Settings.Settings.PitchStopRotationSpeedDuration, DeltaTime);
			return true;
		}

		float HorizontalPitch = Settings.CameraUserSettings.SnapOffset.Pitch;
		float TargetPitchSpeed = 0;
		PitchFollowSlope(Settings, HorizontalPitch, TargetPitchSpeed);
		PitchDownFromRunForward(Settings, Data, HorizontalPitch, TargetPitchSpeed);
		PitchUpFromRunForward(Settings, Data, HorizontalPitch, TargetPitchSpeed);

		if(Math::IsNearlyZero(TargetPitchSpeed))
		{
			// No target, slow down fast
			Data.PitchRotationSpeed.AccelerateTo(TargetPitchSpeed, Settings.Settings.PitchStopRotationSpeedDuration, DeltaTime);
		}
		else if(Math::Abs(TargetPitchSpeed) > Math::Abs(Data.PitchRotationSpeed.Value) && Math::Sign(TargetPitchSpeed) == Math::Sign(Data.PitchRotationSpeed.Value))
		{
			// Accelerating
			Data.PitchRotationSpeed.AccelerateTo(TargetPitchSpeed, Settings.Settings.PitchIncreaseRotationSpeedDuration, DeltaTime);
		}
		else
		{
			// Decelerating
			Data.PitchRotationSpeed.AccelerateTo(TargetPitchSpeed, Settings.Settings.PitchDecreaseRotationSpeedDuration, DeltaTime);
		}

		return true;
	}

	void PitchFollowSlope(
		FCameraAssistSettingsData Settings,
		float&out OutHorizontalPitch,
		float& TargetPitchSpeed) const
	{
		if(!Settings.Settings.bFollowSlopes)
			return;

		const FVector LocalVerticalAxis = Settings.LocalVerticalAxis;
		const FVector LocalWorldUp = Settings.LocalUserWorldUp;

		const FVector ViewAlongSlope = Settings.LocalViewRotation.ForwardVector.VectorPlaneProject(LocalVerticalAxis).GetSafeNormal();
		if(ViewAlongSlope.IsNearlyZero())
			return;

		// Get the pitch angle of the ground slope
		OutHorizontalPitch += 90 - ViewAlongSlope.GetAngleDegreesTo(LocalWorldUp);

		// If  we are not moving, don't slope adjust
		const FVector HorizontalVelocity = Settings.LocalUserVelocity.VectorPlaneProject(LocalVerticalAxis);
		if(HorizontalVelocity.IsNearlyZero())
			return;

		// If we are moving towards the camera, don't slope adjust
		if(HorizontalVelocity.DotProduct(FVector::ForwardVector) < 0)
			return;

		if(Settings.LocalViewRotation.Pitch > Settings.Settings.PitchDownFromRunStartAngle || Settings.LocalViewRotation.Pitch < Settings.Settings.PitchUpFromRunStartAngle)
		{
			// Our current angle is too extreme, we should not assist it away, but instead let the next function handle this
			return;
		}

		float AngleDiff = OutHorizontalPitch - Settings.LocalViewRotation.Pitch;

		// Decrease the pitch speed applied if the player is not moving in the camera forward direction
		const float PitchSpeedMultiplier = HorizontalVelocity.DotProduct(ViewAlongSlope) / Settings.Settings.MaxUserVelocity;

		// Apply to pitch speed
		TargetPitchSpeed += AngleDiff * Settings.Settings.FollowSlopeSpeed * PitchSpeedMultiplier;
	}

	void PitchDownFromRunForward(
		FCameraAssistSettingsData Settings,
	    FHazeActiveCameraAssistData& Data,
		float HorizontalPitch,
		float& TargetPitchSpeed
	) const
	{
		// Don't apply if we are pitching up
		if(Data.bIsPitchingUpFromRun)
			return;

		if(!Settings.Settings.bPitchDownFromRunForwardWhenCameraPitchedUp)
			return;

		const FVector LocalWorldUp = Settings.ControlRotation.UnrotateVector(Settings.UserWorldUp);

		// Check if we should start pitching down
		const float TargetPitchAngle = Math::Min(HorizontalPitch + Settings.Settings.PitchDownFromRunTargetAngle, Settings.Settings.PitchDownFromRunStartAngle - 1);
		if(!Data.bIsPitchingDownFromRun && (Settings.LocalViewRotation.Pitch > Settings.Settings.PitchDownFromRunStartAngle))
		{
			const float MovingDuration = Time::GetRealTimeSince(Settings.LastNoMovementInputTime);

			// Wait until we have moved for some time before adjusting
			if(MovingDuration < Settings.Settings.PitchDownFromRunStartInputDelay)
				return;

			// Wait until we have not controlled the camera for some time before adjusting
			const float NoCameraInputDuration = Time::GetRealTimeSince(Settings.LastCameraInputTime);
			if(NoCameraInputDuration < Settings.Settings.PitchDownFromRunStartInputDelay)
				return;

			// Check if we are moving forward in the camera direction
			const FVector HorizontalForward = Settings.LocalViewRotation.ForwardVector.VectorPlaneProject(LocalWorldUp).GetSafeNormal();
			if(Settings.LocalUserVelocity.DotProduct(HorizontalForward) < Settings.Settings.PitchDownFromRunStartForwardVelocity)
				return;

			// Start pitching down
			Data.bIsPitchingDownFromRun = true;
		}

		if(Data.bIsPitchingDownFromRun)
		{
			// Have we reached the target?
			if(Settings.LocalViewRotation.Pitch < TargetPitchAngle)
			{
				// Stop pitching down
				Data.bIsPitchingDownFromRun = false;
			}
			else
			{
				// We are pitching down
				const float PitchSign = Math::Sign(TargetPitchAngle - Settings.LocalViewRotation.Pitch);
				float PitchAlpha = Math::GetPercentageBetweenClamped(TargetPitchAngle, Settings.Settings.PitchDownFromRunStartAngle, Settings.LocalViewRotation.Pitch);
				TargetPitchSpeed += Settings.Settings.PitchDownFromRunRotationSpeed * PitchSign * PitchAlpha;
			}
		}
	}

	void PitchUpFromRunForward(
		FCameraAssistSettingsData Settings,
	    FHazeActiveCameraAssistData& Data,
		float HorizontalPitch,
		float& TargetPitchSpeed
	) const
	{
		// Don't apply if we are pitching down
		if(Data.bIsPitchingDownFromRun)
			return;
		
		if(!Settings.Settings.bPitchUpFromRunForwardWhenCameraPitchedDown)
			return;

		const FVector LocalWorldUp = Settings.ControlRotation.UnrotateVector(Settings.UserWorldUp);

		// Check if we should start pitching up
		const float TargetPitchAngle = Math::Max(HorizontalPitch + Settings.Settings.PitchUpFromRunTargetAngle, Settings.Settings.PitchUpFromRunStartAngle + 1);
		if(!Data.bIsPitchingUpFromRun && (Settings.LocalViewRotation.Pitch < Settings.Settings.PitchUpFromRunStartAngle))
		{
			const float MovingDuration = Time::GetRealTimeSince(Settings.LastNoMovementInputTime);

			// Wait until we have moved for some time before adjusting
			if(MovingDuration < Settings.Settings.PitchUpFromRunStartInputDelay)
				return;

			// Wait until we have not controlled the camera for some time before adjusting
			const float NoCameraInputDuration = Time::GetRealTimeSince(Settings.LastCameraInputTime);
			if(NoCameraInputDuration < Settings.Settings.PitchUpFromRunStartInputDelay)
				return;

			// Check if we are moving forward in the camera direction
			const FVector HorizontalForward = Settings.LocalViewRotation.ForwardVector.VectorPlaneProject(LocalWorldUp).GetSafeNormal();
			if(Settings.LocalUserVelocity.DotProduct(HorizontalForward) < Settings.Settings.PitchUpFromRunStartForwardVelocity)
				return;

			// Start pitching up
			Data.bIsPitchingUpFromRun = true;
		}

		if(Data.bIsPitchingUpFromRun)
		{
			// Have we reached the target?
			if(Settings.LocalViewRotation.Pitch > TargetPitchAngle)
			{
				// Stop pitching up
				Data.bIsPitchingUpFromRun = false;
			}
			else
			{
				// We are pitching up
				const float PitchSign = Math::Sign(TargetPitchAngle - Settings.LocalViewRotation.Pitch);
				float PitchAlpha = Math::GetPercentageBetweenClamped(TargetPitchAngle, Settings.Settings.PitchUpFromRunStartAngle, Settings.LocalViewRotation.Pitch);
				TargetPitchSpeed += Settings.Settings.PitchUpFromRunRotationSpeed * PitchSign * PitchAlpha;
			}
		}
	}
}