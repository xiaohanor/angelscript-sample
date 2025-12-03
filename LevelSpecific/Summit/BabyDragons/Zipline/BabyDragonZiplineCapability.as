struct FBabyDragonZiplineActivationParams
{
	bool bIsInAir = false;
}

class UBabyDragonZiplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"Zipline");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 0;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;

	const float InAirFeedbackStartDelay = 0.4;
	const float GroundFeedbackStartDelay = 0.6;

	bool bStartedFromAir = false;
	bool bHasStartedShake = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonZiplineActivationParams& Params) const
	{
		if (DragonComp.ZiplineState != ETailBabyDragonZiplineState::None)
		{
			if(MoveComp.IsInAir())
				Params.bIsInAir = true;
			else
				Params.bIsInAir = false;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ZiplineState == ETailBabyDragonZiplineState::None)
			return true;
		if (DragonComp.ZiplineActivePoint == nullptr)
			return true;
		if (MoveComp.HasMovedThisFrame())
        	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonZiplineActivationParams Params)
	{
		bStartedFromAir = Params.bIsInAir;
		bHasStartedShake = false;

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"TailGrab", this);
		Player.BlockCapabilities(n"TailWhip", this);
		Player.BlockCapabilities(n"TailAim", this);
		Player.ApplyCameraSettings(DragonComp.ZiplineCameraSettings, 1, this, SubPriority = 100);
		Player.ActivateCamera(DragonComp.ZiplineActivePoint.ZiplineCamera, DragonComp.ZiplineActivePoint.CameraBlendInTime, this);

		UBabyDragonZiplineEventHandler::Trigger_StartedZipline(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"TailGrab", this);
		Player.UnblockCapabilities(n"TailWhip", this);
		Player.UnblockCapabilities(n"TailAim", this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.DeactivateCameraByInstigator(this, DragonComp.ZiplineActivePoint.CameraBlendOutTime);
		Player.StopCameraShakeByInstigator(this);
		Player.StopForceFeedback(this);
		
		DragonComp.ZiplineState = ETailBabyDragonZiplineState::None;
		DragonComp.ZiplineActivePoint = nullptr;
		DragonComp.ZiplinePosition = FSplinePosition();

		UBabyDragonZiplineEventHandler::Trigger_StoppedZipline(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasStartedShake)
		{
			if((bStartedFromAir && ActiveDuration >= InAirFeedbackStartDelay)
			|| (!bStartedFromAir && ActiveDuration >= GroundFeedbackStartDelay))
			{
				Player.PlayCameraShake(DragonComp.ZiplineCameraShake, this, 1.0);
				Player.PlayForceFeedback(DragonComp.ZiplineRumble, true, true, this);
				bHasStartedShake = true;
			}
		}
	}
}