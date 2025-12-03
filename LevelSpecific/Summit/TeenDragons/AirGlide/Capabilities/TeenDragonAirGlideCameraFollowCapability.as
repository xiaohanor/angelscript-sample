class UTeenDragonAirGlideCameraFollowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UCameraUserComponent CameraUserComp;
	UPlayerAcidTeenDragonComponent AcidDragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UPlayerAimingComponent AimComp;

	UTeenDragonAirGlideSettings AirGlideSettings;

	FRotator LastTargetRotation;

	float LastTimeAppliedCameraInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AcidDragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AirGlideComp.bIsAirGliding && !AirGlideComp.bInAirCurrent)
			return false;

		if(AimComp.IsAiming())
			return false;

		if(!CameraUserComp.CanControlCamera())
			return false;

		if(AcidDragonComp.bTopDownMode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AirGlideComp.bIsAirGliding && !AirGlideComp.bInAirCurrent)
			return true;

		if(!CameraUserComp.CanControlCamera())
			return true;

		if(AimComp.IsAiming())
			return true;

		if(AcidDragonComp.bTopDownMode)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CameraUserComp.HasAppliedUserInput())
			LastTimeAppliedCameraInput = Time::GameTimeSeconds;

		FRotator CameraRotation = CameraUserComp.ControlRotation;
		FRotator TargetCameraRotation = FRotator::MakeFromXZ(Player.ActorHorizontalVelocity, FVector::UpVector);
		TargetCameraRotation.Pitch = CameraRotation.Pitch;

		float HorizontalSpeed = Player.ActorHorizontalVelocity.Size();
		if(HorizontalSpeed < AirGlideSettings.CameraFollowMinSpeed)
		{
			TargetCameraRotation = LastTargetRotation;
			LastTargetRotation = Math::RInterpTo(LastTargetRotation, CameraRotation, DeltaTime, 5.0);
		}
		else
		{
			LastTargetRotation = TargetCameraRotation;
		}

		if(!RecentlyAppliedCameraInput())
		{
			CameraRotation = Math::RInterpTo(CameraRotation, TargetCameraRotation, DeltaTime, AirGlideSettings.CameraFollowSpeed * GetDotTowardsCameraForward());
			CameraUserComp.SetDesiredRotation(CameraRotation, this);
		}
	}

	float GetDotTowardsCameraForward() const
	{
		FVector FlatViewForward = CameraUserComp.ControlRotation.ForwardVector.ConstrainToPlane(FVector::UpVector);
		FVector PlayerHorizontalVelocityDir = Player.ActorHorizontalVelocity.GetSafeNormal();
		float VelocityDotViewForward = PlayerHorizontalVelocityDir.DotProduct(FlatViewForward);
		VelocityDotViewForward *= 0.5;
		VelocityDotViewForward += 0.5;
		return VelocityDotViewForward;
	}

	bool RecentlyAppliedCameraInput() const
	{
		return Time::GetGameTimeSince(LastTimeAppliedCameraInput) < AirGlideSettings.CameraInputStopFollowDuration;
	}
};