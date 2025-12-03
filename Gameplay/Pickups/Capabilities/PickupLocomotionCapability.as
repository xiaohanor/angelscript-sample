class UPickupLocomotionCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::Pickups);
	default CapabilityTags.Add(PickupTags::PickupLocomotionCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PlayerPickupComponent;

	bool bPutdown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);

		// Setup player pickup component events
		PlayerPickupComponent.OnPutDownEvent.AddUFunction(this, n"OnPutDown");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerPickupComponent.GetCurrentPickup() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bPutdown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerOwner.AddLocomotionFeature(PlayerPickupComponent.LocomotionFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerOwner.ClearLocomotionFeatureByInstigator(this);
		bPutdown = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerOwner.Mesh.CanRequestOverrideFeature())
			PlayerOwner.Mesh.RequestOverrideFeature(n"PickUp", this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPutDown(FPutDownParams PutDownParams)
	{
		bPutdown = true;
	}
}