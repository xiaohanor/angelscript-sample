class UPlayerCentipedeRideLocomotionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerCentipedeComponent CentipedeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add locomotion feature
		ULocomotionFeatureCentipedeRiding LocomotionFeature = CentipedeComponent.PlayerRideAnimationSettings.GetLocomotionFeatureForPlayer(Player.Player);
		Player.AddLocomotionFeature(LocomotionFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"CentipedeRiding", this);
	}
}