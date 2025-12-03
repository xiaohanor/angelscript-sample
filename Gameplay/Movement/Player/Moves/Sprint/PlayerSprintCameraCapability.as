/*
 *	Handles camera settings application, camera shakes/etc on sprint activation 
 */

class UPlayerSprintCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);
	default CapabilityTags.Add(PlayerSprintTags::SprintCamera);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	bool bCameraSettingsActive = false;

	UPlayerSprintComponent SprintComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SprintComp = UPlayerSprintComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (bCameraSettingsActive)
		{
			if (IsBlocked()
				|| (!IsActive() && DeactiveDuration > SprintComp.Settings.CameraSettingsLingerTime)
				|| (!IsActive() && !SprintComp.IsSprintToggled())
				|| Player.IsPlayerDeadOrRespawning()
			)
			{
				if(Player.IsAnyCapabilityActive(n"Dash"))
					return;

				Player.ClearCameraSettingsByInstigator(this, Player.IsPlayerDeadOrRespawning() ? 2.0 : 4.0);
				bCameraSettingsActive = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SprintComp.IsSprinting())
			return false;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SprintComp.IsSprinting())
			return true;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!bCameraSettingsActive)
		{
			Player.ApplyCameraSettings(SprintComp.SprintCameraSetting, 2.0, this, EHazeCameraPriority::Default ,SubPriority = 20);
			bCameraSettingsActive = true;
		}
	
		// Player.PlayCameraShake(SprintComp.SprintShake, 0.45);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
};