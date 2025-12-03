class USkylineGravityZoneSwingEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityZone");
	default CapabilityTags.Add(n"GravityZoneSwingEnter");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	USkylineGravityZoneComponent ZoneComp;
	UCameraUserComponent CameraUser;
	UPlayerSwingComponent SwingComp;
	UPlayerMovementComponent MoveComp;

	float ActiveTickDuration;
	FVector StartGravityDirection;
	FVector TargetGravityDirection;
	FVector RotationAxis;
	float RotationAngularDistance;
	FHazeAcceleratedQuat CameraRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ZoneComp = USkylineGravityZoneComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineGravityZoneEnterParams& Params) const
	{
		if (!SwingComp.HasActivateSwingPoint())
			return false;

		if (ZoneComp.PrimaryZone == nullptr)
			return false;

		FVector ZoneUpVector = ZoneComp.PrimaryZone.ActorUpVector;
		if (ZoneUpVector.DotProduct(Player.MovementWorldUp) > 0.98)
			return false;

		Params.Zone = ZoneComp.PrimaryZone;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveTickDuration >= ZoneComp.SwitchDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSkylineGravityZoneEnterParams& Params)
	{
		ZoneComp.ActiveZone = Params.Zone;
		StartGravityDirection = Player.GetGravityDirection();
		TargetGravityDirection = -ZoneComp.ActiveZone.ActorUpVector;

		// Parallel start & target gravity, do a full rotation around the swing
		//  in whatever horizontal direction we're heading towards, looks pretty slick
		if (Math::Abs(StartGravityDirection.DotProduct(TargetGravityDirection)) > 0.99)
		{
			FVector UpVector = SwingComp.PlayerToSwingPoint.GetSafeNormal();
			FVector ForwardVector = MoveComp.HorizontalVelocity.GetSafeNormal();

			if (ForwardVector.IsNearlyZero())
				ForwardVector = Player.ActorForwardVector;

			RotationAxis = UpVector.CrossProduct(-ForwardVector).ConstrainToPlane(StartGravityDirection).GetSafeNormal();
		}
		else
		{
			RotationAxis = StartGravityDirection.CrossProduct(TargetGravityDirection).GetSafeNormal();
		}

		RotationAngularDistance = Math::RadiansToDegrees(Math::Acos(StartGravityDirection.DotProduct(TargetGravityDirection)));

		CameraRotation.SnapTo(Player.ViewRotation.Quaternion());

		Player.PlaySlotAnimation(Animation = ZoneComp.GravitySwitchAnimation, bLoop = true);
		Player.ApplyCameraSettings(ZoneComp.CameraSettings, 1, this, SubPriority = 61);

		// Align fucks with gravity if we happen to find a target below us during transition
		Player.BlockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.BlockCapabilities(n"GravityZoneSwingExit", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.OverrideGravityDirection(TargetGravityDirection, Skyline::GravityProxy);

		Player.StopSlotAnimationByAsset(ZoneComp.GravitySwitchAnimation);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(GravityBladeGrappleTags::GravityBladeGrappleGravityAlign, this);
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.UnblockCapabilities(n"GravityZoneSwingExit", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Clamp(ActiveDuration / ZoneComp.SwitchDuration, 0.0, 1.0);
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 1.6);

		const FVector GravityDirection = StartGravityDirection.RotateAngleAxis(RotationAngularDistance * Alpha, RotationAxis);
		Player.OverrideGravityDirection(GravityDirection, Skyline::GravityProxy);
	
		CameraUser.SetYawAxis(-GravityDirection, this);
		CameraRotation.AccelerateTo(Player.ActorQuat, ZoneComp.SwitchDuration / 2.0, DeltaTime);
		CameraUser.SetDesiredRotation(CameraRotation.Value.Rotator(), this);

		ActiveTickDuration = ActiveDuration;
	}
}