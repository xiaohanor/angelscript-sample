class UCameraControlCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

	default BlockExclusionTags.Add(CameraTags::Camera);
	default BlockExclusionTags.Add(CameraTags::CameraControl);

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default TickGroupSubPlacement = 10; // So we can apply other control capabilities before this

	UCameraUserComponent User;
	USpringArmCamera SpringArm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Player);
		SpringArm = USpringArmCamera::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!User.CanApplyUserInput())
			return false;

		if(!User.CanControlCamera())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!User.CanApplyUserInput())
			return true;

		if(!User.CanControlCamera())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		SpringArm.PivotTraceOriginOffset = FVector::UpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Ignore on remote side; control rotation is replicated
		// Note that this should still be active on remote side so we know control is not blocked or otherwise stopped.
		if(!HasControl())
			return;

		FVector2D AxisInput = Player.GetCameraInput();
		FRotator TurnRate = User.GetCameraTurnRate();	
		FRotator DeltaRotation = User.CalculateAndUpdateInputDeltaRotation(AxisInput, TurnRate);
		if(!DeltaRotation.IsNearlyZero())
			User.AddUserInputDeltaRotation(DeltaRotation, this);
	}
};