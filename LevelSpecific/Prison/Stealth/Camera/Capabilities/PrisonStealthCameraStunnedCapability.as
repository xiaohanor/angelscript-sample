/**
 * Temporarily stop both movement and vision.
 */
class UPrisonStealthCameraStunnedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthCamera);

	APrisonStealthCamera StealthCamera;
	UPrisonStealthStunnedComponent StunnedComp;
    UPrisonStealthVisionComponent VisionComponent;
	UPrisonStealthDetectionComponent DetectionComp;

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthCamera = Cast<APrisonStealthCamera>(Owner);
        VisionComponent = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
		DetectionComp = UPrisonStealthDetectionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!StunnedComp.ShouldBeStunned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!StunnedComp.ShouldBeStunned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StunnedComp.bIsStunned = true;

		FPrisonStealthCameraOnStunStartedParams Params;
		Params.bReset = true;
		UPrisonStealthCameraEventHandler::Trigger_OnStunStarted(StealthCamera, Params);

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			StealthCamera.SetDetectionAlpha(Player, 0, true);
		}

		StartRotation = StealthCamera.ActorRotation;

		StealthCamera.BlockCapabilities(PrisonStealthTags::BlockedWhileStunned, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StunnedComp.bIsStunned = false;

		StealthCamera.UnblockCapabilities(PrisonStealthTags::BlockedWhileStunned, this);

		StunnedComp.ResetStun();
		UPrisonStealthCameraEventHandler::Trigger_OnStunStopped(StealthCamera);
		StealthCamera.Reset();
	}
}