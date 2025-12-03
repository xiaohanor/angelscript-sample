class UTeenDragonRollCameraFollowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Gameplay;

	UCameraUserComponent CameraUser;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UTeenDragonRollSettings RollSettings;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccPitch;

	float LastTimeAppliedCameraInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!RollComp.IsRolling())
			return false;

		if(SceneView::IsFullScreen())
			return false;

		if(!CameraUser.CanControlCamera())
			return false;

		if(Player.ActorVelocity.Size() < RollSettings.CameraFollowMinRollingSpeed)
			return false;

		if(Time::GetGameTimeSince(LastTimeAppliedCameraInput) <= RollSettings.CameraFollowDelayAfterInput)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if(!RollComp.IsRolling())
			return true;

		if(SceneView::IsFullScreen())
			return true;

		if(!CameraUser.CanControlCamera())
			return true;

		if(Player.ActorVelocity.Size() < RollSettings.CameraFollowMinRollingSpeed)
			return true;

		if(Time::GetGameTimeSince(LastTimeAppliedCameraInput) <= RollSettings.CameraFollowDelayAfterInput)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(CameraUser.ControlRotation, CameraUser.ViewAngularVelocity);
		AccPitch.SnapTo(CameraUser.ControlRotation.Pitch, CameraUser.ViewAngularVelocity.Pitch);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(CameraUser.HasAppliedUserInput())
			LastTimeAppliedCameraInput = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CameraUser.CanControlCamera())
		{
			FVector VelocityDir = FVector::ZeroVector;
			float RollingSpeed = 0;
			Player.ActorVelocity.ToDirectionAndLength(VelocityDir, RollingSpeed);

			FVector VelocityTangent = FVector::UpVector.CrossProduct(VelocityDir);
			FVector CameraDir = VelocityDir.RotateAngleAxis(RollSettings.CameraFollowPitchDownDegrees, VelocityTangent);
			FRotator TargetRotation = FRotator::MakeFromX(CameraDir);
			TargetRotation.Pitch = Math::Clamp(TargetRotation.Pitch, RollSettings.CameraFollowPitchRange.Min, RollSettings.CameraFollowPitchRange.Max);

			const float SpeedAlpha = Math::GetPercentageBetweenClamped(RollSettings.CameraFollowMinRollingSpeed, RollSettings.CameraFollowRollingSpeedForMinDuration, RollingSpeed);
			const float RotationDuration = Math::Lerp(RollSettings.CameraFollowMaxDuration, RollSettings.CameraFollowMinDuration, SpeedAlpha);
			AccRotation.AccelerateTo(TargetRotation, RotationDuration, DeltaTime);
			const float PitchRotationDuration = Math::Lerp(RollSettings.CameraFollowPitchMaxDuration, RollSettings.CameraFollowPitchMinDuration, SpeedAlpha);
			AccPitch.AccelerateTo(TargetRotation.Pitch,	PitchRotationDuration, DeltaTime);

			FRotator NewRotation = AccRotation.Value;
			NewRotation.Pitch = AccPitch.Value;

			CameraUser.SetDesiredRotation(NewRotation, this);

			TEMPORAL_LOG(Player, "Camera Follow")
				.Value("Rotation Duration", RotationDuration)
				.DirectionalArrow("Velocity Dir", Player.ActorLocation, VelocityDir * 500, 20, 100)
				.DirectionalArrow("Velocity Tangent", Player.ActorLocation, VelocityTangent * 500, 20, 100, FLinearColor::Green)

			;
		}
	}
};