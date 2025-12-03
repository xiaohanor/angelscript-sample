class UAdultDragonSplineFollowCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);
	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);

	default DebugCategory = n"AdultDragon";
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;
	UAdultDragonStrafeComponent StrafeComp;
	UCameraUserComponent CameraUser;
	UPlayerMovementComponent MoveComp;

	FHazeAcceleratedRotator AccSplineRotation;
	FHazeAcceleratedRotator AccInputRotation;

	UAdultDragonStrafeSettings StrafeSettings;

	FHazeAcceleratedFloat AcceleratedSideFlyMultiplier;

	const float CameraRotationDuration = 0.5;
	FHazeAcceleratedFloat AccelCamRoll;
	float CamRollDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SplineFollowManagerComp.bForceLockedStrafe)
			return true;

		if (StrafeSettings.bUseFreeFlyStrafe)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SplineFollowManagerComp.bForceLockedStrafe)
			return false;

		if (StrafeSettings.bUseFreeFlyStrafe)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccSplineRotation.SnapTo(CameraUser.ViewRotation, CameraUser.ViewAngularVelocity);
		AccInputRotation.SnapTo(FRotator::ZeroRotator);
		StrafeComp.AccMovementRotation.SnapTo(Player.ActorRotation.Quaternion());
		StrafeComp.InputRotation = FRotator::ZeroRotator;
		AcceleratedSideFlyMultiplier.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TOptional<FAdultDragonSplineFollowData> CurrentSplineFollowData = SplineFollowManagerComp.CurrentSplineFollowData;
		if (CurrentSplineFollowData.IsSet())
		{
			TEMPORAL_LOG(StrafeComp)
				.DirectionalArrow("Actor Forward", Player.ActorLocation, Player.ActorForwardVector * 5000, 10, 40, FLinearColor::Red)
				.DirectionalArrow("Actor Up", Player.ActorLocation, Player.ActorUpVector * 5000, 10, 40, FLinearColor::Blue)
				.DirectionalArrow("Actor Right", Player.ActorLocation, Player.ActorRightVector * 5000, 10, 40, FLinearColor::Green);
		}

		if (CameraUser.CanApplyUserInput() && CameraUser.CanControlCamera())
		{
			float CameraDeltaSeconds = Time::CameraDeltaSeconds;

			FRotator FractionOfPlayerInputRotation = StrafeComp.InputRotation * StrafeSettings.CameraPlayerRotationFraction.Min;

			if (DragonComp.bCanInputRotate)
			{
				AccInputRotation.AccelerateTo(FractionOfPlayerInputRotation, StrafeSettings.CameraPlayerRotationAccelerationDuration, DeltaTime);
			}
			else
			{
				AccInputRotation.AccelerateTo(FRotator(0), StrafeSettings.CameraPlayerRotationAccelerationDuration, DeltaTime);
			}

			if (CurrentSplineFollowData.IsSet())
			{
				if (DragonComp.bGapFlying && DragonComp.GapFlyingData.Value.bAllowSideFlying)
				{
					AcceleratedSideFlyMultiplier.AccelerateTo(0.7, 4.5, DeltaTime);
				}
				else
				{
					AcceleratedSideFlyMultiplier.AccelerateTo(0.0, 3.0, DeltaTime);
				}

				if (DragonComp.GapFlyingData.IsSet())
					AccelCamRoll.AccelerateTo(DragonComp.GapFlyingData.Value.RollAmount[Player], CamRollDuration, DeltaTime);

				FRotator SplineRotation = CurrentSplineFollowData.Value.WorldRotation.Rotator();
				SplineRotation += FRotator(0.0, 0.0, AcceleratedSideFlyMultiplier.Value * AccelCamRoll.Value);
				AccSplineRotation.AccelerateTo(SplineRotation, CameraRotationDuration, CameraDeltaSeconds);
				DragonComp.DesiredCameraRotation.Apply(AccSplineRotation.Value, this);
			}

			FRotator CameraTargetRotation = AccSplineRotation.Value + AccInputRotation.Value;
			CameraUser.SetInputRotation(CameraTargetRotation, this);
		}
	}
};