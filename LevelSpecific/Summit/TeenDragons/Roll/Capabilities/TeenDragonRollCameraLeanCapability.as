class UTeenDragonRollCameraLeanCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Gameplay;

	UCameraUserComponent CameraUser;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UPlayerMovementComponent MoveComp;

	UTeenDragonRollSettings RollSettings;

	FHazeAcceleratedFloat AccLeanDegrees;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

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

		if(MoveComp.HorizontalVelocity.Size() < RollSettings.CameraFollowMinRollingSpeed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;
		

		if(ShouldStopLeaning())
		{
			if(Math::IsNearlyZero(AccLeanDegrees.Value))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		AccLeanDegrees.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bShouldStopLeaning = ShouldStopLeaning();
		if(!bShouldStopLeaning)
		{
			float RollingSpeed = MoveComp.HorizontalVelocity.Size();
			float SpeedAlpha = Math::GetPercentageBetweenClamped(RollSettings.CameraLeanMinSpeed, RollSettings.CameraLeanSpeedForMinDuration, RollingSpeed);
			SpeedAlpha = Math::EaseIn(0.0, 1.0, SpeedAlpha, 4.0);
			float RotationDuration = Math::Lerp(RollSettings.CameraFollowMaxDuration, RollSettings.CameraFollowMinDuration, SpeedAlpha);
			
			FVector MovementInput = MoveComp.MovementInput;
			FVector LocalMovementInput = Player.ActorTransform.InverseTransformVector(MovementInput);

			float ClampedSideInput = LocalMovementInput.Y / RollSettings.CameraLeanMaxInput;
			ClampedSideInput = Math::Min(ClampedSideInput, 1.0);

			float TargetLean = ClampedSideInput * RollSettings.CameraLeanMaxDegrees;
			AccLeanDegrees.AccelerateTo(-TargetLean, RotationDuration, DeltaTime);
		}
		else
		{
			AccLeanDegrees.AccelerateTo(0, RollSettings.CameraLeanDeactivateAccelerateDuration, DeltaTime);
		}
		FVector CameraYawTiltAxis = CameraUser.ControlRotation.ForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector CameraYawAxis = FVector::UpVector.RotateAngleAxis(AccLeanDegrees.Value, CameraYawTiltAxis);

		CameraUser.SetYawAxis(CameraYawAxis, this);
	}

	bool ShouldStopLeaning() const
	{
		if(!RollComp.IsRolling())
			return true;

		if(SceneView::IsFullScreen())
			return true;

		if(MoveComp.HorizontalVelocity.Size() < RollSettings.CameraLeanMinSpeed)
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}
};