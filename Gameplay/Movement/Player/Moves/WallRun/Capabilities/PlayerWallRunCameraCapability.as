

asset PlayerWallRunCameraBlendIn of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
	ClampVelocitySize = 2000;
	bIncludeLocationVelocity = true;
	LocationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::Accelerated;
}

asset PlayerWallRunCameraBlendOut of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
}

class UPlayerWallRunCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunCamera);
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 180;

	default DebugCategory = n"Movement";

	UPlayerWallRunComponent WallRunComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FAcceleratedInputInterruptedDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedDuration = 0.8;
	default AcceleratedDesiredRotation.PostInputCooldown = 0.0;
	default AcceleratedDesiredRotation.PostCooldownInputScaleInterp = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
		User = UCameraUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (WallRunComp.State == EPlayerWallRunState::WallRun)
			return true;

		if (WallRunComp.State == EPlayerWallRunState::WallRunLedge)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (WallRunComp.State != EPlayerWallRunState::WallRun && WallRunComp.State != EPlayerWallRunState::WallRunLedge)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		AcceleratedDesiredRotation.Activate(Player.GetCameraDesiredRotation());

		if (WallRunComp.CameraSettings != nullptr)
			Player.ApplyCameraSettings(WallRunComp.CameraSettings, 0.0, this, SubPriority = 26);
		
		Player.ApplyBlendToCurrentView(1.5, PlayerWallRunCameraBlendIn);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ApplyBlendToCurrentView(1.5, PlayerWallRunCameraBlendOut);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float CameraDeltaTime = Time::GetCameraDeltaSeconds();
		UpdatePivotOffset(CameraDeltaTime);
		UpdateDesiredRotation(CameraDeltaTime);
	}
	
	void UpdatePivotOffset(float DeltaTime)
	{		
		FVector PivotOffset = FVector(0.0, 0.0, 65.0);
		PivotOffset += WallRunComp.ActiveData.WallNormal * 150.0;
		UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(PivotOffset, this, 0, SubPriority = 26);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FVector Direction = WallRunComp.ActiveData.WallNormal.CrossProduct(MoveComp.WorldUp).GetSafeNormal();
		Direction *= Math::Sign(Direction.DotProduct(MoveComp.Velocity));
	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		FRotator DesiredRotation = FRotator::MakeFromX(Direction);
		DesiredRotation = Math::LerpShortestPath(WallRunComp.ActiveData.WallNormal.Rotation(), DesiredRotation, 0.9);
		DesiredRotation.Pitch = WallRunComp.Settings.CameraPitch;
		
		FRotator NewDesired = AcceleratedDesiredRotation.Update(User.DesiredRotation, DesiredRotation, Input, DeltaTime);
		User.SetDesiredRotation(NewDesired, this);
	}
}