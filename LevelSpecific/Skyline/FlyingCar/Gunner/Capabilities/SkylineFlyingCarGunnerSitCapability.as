class USkylineFlyingCarGunnerSitCapability : UHazePlayerCapability
{
	USkylineFlyingCarGunnerComponent GunnerComponent;

	default TickGroup = EHazeTickGroup::Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return false;

		if (!GunnerComponent.IsSittingInsideCar())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return true;

		if (!GunnerComponent.IsSittingInsideCar())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// FHazeSlotAnimSettings Settings;
		// Settings.bLoop = true;
		// Settings.BlendTime = 0.5;
		// Player.PlaySlotAnimation(GunnerComponent.SitSequence, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player.StopSlotAnimationByAsset(GunnerComponent.SitSequence, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GunnerComponent.GetGunnerState() == EFlyingCarGunnerState::Rifle)
			Player.RequestLocomotion(n"FlyingCarGunnerRifle", this);
		else
			Player.RequestLocomotion(n"FlyingCarGunnerBazooka", this);
	}
}