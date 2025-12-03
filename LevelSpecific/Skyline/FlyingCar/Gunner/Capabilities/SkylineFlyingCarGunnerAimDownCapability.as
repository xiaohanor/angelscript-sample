

class UFlyingCarGunnerAimDownCapability: UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UCameraUserComponent CameraUserComponent;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	UTargetableComponent PrimaryTarget = nullptr;

	const float AutoAimDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		CameraUserComponent = UCameraUserComponent::Get(Owner);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if (GunnerComponent.Car == nullptr)
	        return false;

		if (GunnerComponent.IsReloadingRifle())
			return false;

		if (GunnerComponent.IsReloadingBazooka())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (GunnerComponent.Car == nullptr)
	        return true;

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		if (GunnerComponent.IsReloadingRifle())
			return true;

		if (GunnerComponent.IsReloadingBazooka())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(GunnerComponent.GetGunnerState() == EFlyingCarGunnerState::Rifle)
		{
			Player.ApplyCameraSettings(GunnerComponent.AimdownSettings, 0.5, this, EHazeCameraPriority::High);
		}

		if(GunnerComponent.GetGunnerState() == EFlyingCarGunnerState::Bazooka)
		{
			Player.ApplyCameraSettings(GunnerComponent.BazookaAimdownSettings, 0.5, this, EHazeCameraPriority::High);
		}
		
		GunnerComponent.bIsInAimDown = true;

		PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(USkylineFlyingCarRifleTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AutoAimAlpha = Math::Saturate(ActiveDuration / AutoAimDuration);

		if (PrimaryTarget != nullptr && AutoAimAlpha < 1.0)
		{
			FQuat PreviousDesiredRotation = CameraUserComponent.GetDesiredRotation().Quaternion();

			FVector CameraToTarget = (PrimaryTarget.WorldLocation - CameraUserComponent.ViewLocation).GetSafeNormal();
			FQuat TargetDesiredRotation = FQuat::MakeFromX(CameraToTarget);

			float InterpSpeed = Math::Lerp(8, 2, Math::Square(AutoAimAlpha));
			FQuat DesiredRotation = Math::QInterpTo(PreviousDesiredRotation, TargetDesiredRotation, DeltaTime, InterpSpeed);
			CameraUserComponent.SetDesiredRotation(DesiredRotation.Rotator(), this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		GunnerComponent.bIsInAimDown = false;
	}
}