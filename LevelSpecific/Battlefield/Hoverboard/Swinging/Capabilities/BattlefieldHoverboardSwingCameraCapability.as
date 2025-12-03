
class UBattlefieldHoverboardSwingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingCamera);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 24;
	
	AHazePlayerCharacter Player;
	UBattlefieldHoverboardSwingComponent SwingComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwingComp = UBattlefieldHoverboardSwingComponent::Get(Player);
		User = UCameraUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (!SwingComp.Data.HasValidSwingPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (!SwingComp.Data.HasValidSwingPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (SwingComp.Data.ActiveSwingPoint.CameraSettings != nullptr)
			Player.ApplyCameraSettings(SwingComp.Data.ActiveSwingPoint.CameraSettings, 2, this, SubPriority = 50);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 3.0);
	}
}