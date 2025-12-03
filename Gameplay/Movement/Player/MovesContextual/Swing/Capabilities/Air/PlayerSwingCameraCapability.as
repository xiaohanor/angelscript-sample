
class UPlayerSwingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingCamera);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 24;
	
	AHazePlayerCharacter Player;
	UPlayerSwingComponent SwingComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		User = UCameraUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (!SwingComp.Data.HasValidSwingPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (!SwingComp.Data.HasValidSwingPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const float BlendTime = 2;

		if (SwingComp.Data.ActiveSwingPoint.CameraSettings != nullptr)
			Player.ApplyCameraSettings(SwingComp.Data.ActiveSwingPoint.CameraSettings, BlendTime, this, SubPriority = 50);
		
		// This will clear the ideal distance multiplier so the camera can actually go underneath the player
		CameraSettings.IdealDistanceByPitchCurveAlpha.Apply(0, this, BlendTime);
		CameraSettings.PivotHeightByPitchCurveAlpha.Apply(0, this, BlendTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 3.0);
	}
}