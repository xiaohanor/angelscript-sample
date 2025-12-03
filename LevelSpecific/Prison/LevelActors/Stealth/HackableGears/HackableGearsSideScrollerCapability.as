/**
 * When Mio is hacking the Hackable Gears and Zoe has attached to a water wheel:
 * - Set sticky respawn point to the start
 * - Activate the SplineLock focus camera
 * Deactivate when Mio stops hacking, or Zoe leaves the ZoeTrigger.
 */
class UHackableGearsSideScrollerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHackableGearsManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AHackableGearsManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Manager.bFinished)
			return false;

		// Only spline lock when Mio has hacked the gears
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return false;

		// Zoe must be in the ZoeTrigger
		if(!IsZoeInSideScrollerArea())
			return false;

		if(Manager.OperationTrigger.IsPlayerInside(Game::Zoe))
		{
			// Zoe is in the operations part
			return true;
		}
		else
		{
			// If Zoe is not in the operation part, make sure that she attaches to something
			auto AttachedComp = UMagnetDroneAttachedComponent::Get(Game::Zoe);

			// We aren't attached to anything
			if(!AttachedComp.IsAttached())
				return false;

			// Check if we are attached to a water wheel
			auto AttachComp = AttachedComp.AttachedData.GetAttachComp();
			auto HackableWaterGearWheel = Cast<AHackableWaterGearWheel>(AttachComp.Owner);
			if(HackableWaterGearWheel == nullptr)
				return false;

			// Just in case there are water wheels that are not part of the hackable gear segment
			if(!Manager.HackableWaterGear.Wheels.Contains(HackableWaterGearWheel))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return true;

		if(Manager.bFinished)
			return true;

		if(!IsZoeInSideScrollerArea())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.bSideScrollerActive = true;
		Manager.EnableWaterGearWheels();
		Manager.SplineLockRespawnPoint.EnableForPlayer(Game::Zoe, this);

		Game::Zoe.ActivateCamera(Manager.SplineLockFocusCameraActor.Camera, 2, this, EHazeCameraPriority::High);

		Game::Zoe.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.DisableWaterGearWheels();
		Manager.bSideScrollerActive = false;
		Manager.SplineLockRespawnPoint.DisableForPlayer(Game::Zoe, this);

		Game::Zoe.DeactivateCameraByInstigator(this);

		Game::Zoe.ClearGameplayPerspectiveMode(this);
	}

	bool IsZoeInSideScrollerArea() const
	{
		if(Manager.ZoeTrigger.IsPlayerInside(Game::Zoe))
			return true;

		if(Manager.ZoeStartTrigger.IsPlayerInside(Game::Zoe))
			return true;

		return false;
	}
};