
class UPlayerSwingWallCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingCamera);
	
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 13;

	AHazePlayerCharacter Player;
	UPlayerSwingComponent SwingComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;

	FAcceleratedInputInterruptedDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedDuration = 1.2;
	default AcceleratedDesiredRotation.PostInputCooldown = 0.5;
	default AcceleratedDesiredRotation.PostCooldownInputScaleInterp = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwingComp.Data.HasValidWall())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwingComp.Data.HasValidWall())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedDesiredRotation.Activate(Player.GetCameraDesiredRotation());

		// if (SwingComp.Data.ActiveSwingPoint.WallCameraSettings != nullptr)
		// 	Player.ApplyCameraSettings(SwingComp.Data.ActiveSwingPoint.WallCameraSettings, 1.5, this, SubPriority = 51);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FVector Direction = -SwingComp.Data.WallNormal.GetSafeNormal();
	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		FRotator DesiredRotation = FRotator::MakeFromX(Direction);
		DesiredRotation.Pitch -= 5.0;
		
		FRotator NewDesired = AcceleratedDesiredRotation.Update(User.DesiredRotation, DesiredRotation, Input, DeltaTime);
		User.SetDesiredRotation(NewDesired, this);
	}
}