event void FOnPickUpStarted(FPickUpStartedParams PickUpStartedParams);
event void FOnPickedUp(FPickedUpParams PickedUpParams);

event void FOnPutDownStarted(FPutDownStartedParams PutDownStartedParams);
event void FOnPutDown(FPutDownParams PutDownParams);

class UPlayerPickupComponent : UActorComponent
{
	// Pickup capability can access some of these privates
	access PickupCapabilities = private, UPickupCapability, UPutdownCapability, UPutdownInteractionCapability;

	UPROPERTY(Category = Animation)
	ULocomotionFeaturePickUp LocomotionFeature;

	private AHazePlayerCharacter PlayerOwner;

	UPROPERTY()
	FOnPickUpStarted OnPickupStartedEvent;

	UPROPERTY()
	FOnPickedUp OnPickedUpEvent;

	UPROPERTY()
	FOnPutDownStarted OnPutDownStartedEvent;

	UPROPERTY()
	FOnPutDown OnPutDownEvent;


	access : PickupCapabilities
	UPickupComponent CurrentPickup = nullptr;

	access : PickupCapabilities
	bool bCarryingPickup = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerPickUp(UPickupComponent PickupComponent)
	{
		if (CurrentPickup != nullptr)
			return false;

		// Eman TODO: Maybe don't allow pickup if player is in air and shiet

		return true;
	}

	UFUNCTION()
	void PickUp(UPickupComponent PickupComponent)
	{
		if (!CanPlayerPickUp(PickupComponent))
			return;

		// Sets up bool or fires event for pickup capability to use
		CurrentPickup = PickupComponent;
	}

	// Eman TODO: Implement manual put down!
	UFUNCTION()
	void PutDown()
	{
		if (CurrentPickup == nullptr)
			return;

	}

	UFUNCTION()
	UPickupComponent GetCurrentPickup()
	{
		return CurrentPickup;
	}

	access : PickupCapabilities
	void DetachPickupActor()
	{
		CurrentPickup.Owner.DetachFromActor();
		CurrentPickup = nullptr;
	}

	UFUNCTION()
	bool IsPickingUp()
	{
		return PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupCapability);
	}

	UFUNCTION()
	bool IsCarryingPickup()
	{
		return bCarryingPickup;
	}

	UFUNCTION()
	bool IsPuttingDown()
	{
		return PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability)
			|| PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownInteractionCapability);
	}
}