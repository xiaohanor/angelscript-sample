class UPlayerSlideCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerSlideTags::SlideCamera)
;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerSlideComponent SlideComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerMovementComponent MoveComp;

	bool bHasAppliedCamSettings = false;
	bool bCameraShakeActive = false;

	UCameraShakeBase CurrentCamShake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideComp = UPlayerSlideComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SlideComp.IsSlideActive() && GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::Grounded)
			return false;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SlideComp.IsSlideActive() && GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::Grounded)
			return true;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(MoveComp.IsOnAnyGround())
		{	
			Player.ApplyCameraSettings(SlideComp.SlideCameraSetting, 1.5, this, SubPriority = 35);
			bHasAppliedCamSettings = true;
			
			TriggerCameraImpulse();

			CurrentCamShake = Player.PlayCameraShake(SlideComp.SlideShake, this, 0.5);
			bCameraShakeActive = true;
		}
		else
		{
			bHasAppliedCamSettings = false;
			bCameraShakeActive = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5);

		if(SlideComp.CamOverrideInstigators.Num() > 0)
		{
			for(auto Instigator : SlideComp.CamOverrideInstigators)
			{
				Player.ClearCameraSettingsByInstigator(Instigator, 1.5);
			}

			SlideComp.CamOverrideInstigators.Empty();
		}

		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.IsOnAnyGround())
		{
			if(!bHasAppliedCamSettings)
			{
				Player.ApplyCameraSettings(SlideComp.SlideCameraSetting, 1.5, this, SubPriority = 35);
				bHasAppliedCamSettings = true;
			}

			if(!bCameraShakeActive)
			{
				CurrentCamShake = Player.PlayCameraShake(SlideComp.SlideShake, this);
				TriggerCameraImpulse();

				bCameraShakeActive = true;
			}
			else if(CurrentCamShake != nullptr && bCameraShakeActive)
				CurrentCamShake.ShakeScale = Math::GetMappedRangeValueClamped(FVector2D(0, SlideComp.Settings.SlideMaximumSpeed), FVector2D(0.25, 1), MoveComp.Velocity.Size());
		}
		else
		{
			if(bCameraShakeActive)
			{
				Player.StopCameraShakeByInstigator(this);
				bCameraShakeActive = false;
			}
		}
	}

	void TriggerCameraImpulse()
	{
		FHazeCameraImpulse CamImpulse;
		CamImpulse.AngularImpulse = FRotator(25.0, 0.0, 0.0);
		CamImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, -100.0);
		CamImpulse.CameraSpaceImpulse = FVector(0.0, 150.0, 0.0);
		CamImpulse.ExpirationForce = 10.5;
		CamImpulse.Dampening = 0.8;
		Player.ApplyCameraImpulse(CamImpulse, this);
	}
};