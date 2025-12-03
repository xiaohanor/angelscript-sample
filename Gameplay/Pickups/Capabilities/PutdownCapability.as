class UPutdownCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::Pickups);
	default CapabilityTags.Add(PickupTags::PutdownCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PlayerPickupComponent;

	UPickupComponent CurrentPickup = nullptr;

	FQuat PickupStartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerPickupComponent.GetCurrentPickup() == nullptr)
			return false;

		if (!PlayerPickupComponent.GetCurrentPickup().PickupSettings.bCanBePutDown)
			return false;

		if (!IsActioning(ActionNames::Cancel))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Eman TODO: Use putdown animation duration
		return ActiveDuration > 0.93;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentPickup = PlayerPickupComponent.GetCurrentPickup();
		PickupStartRotation = CurrentPickup.Owner.ActorQuat;

		// Consume velocity
		UPlayerMovementComponent::Get(PlayerOwner).Reset(true);

		// Eman TODO: Block dash and other movement shit while this is active!
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);

		// Fire putdown started event
		FPutDownStartedParams PutDownStartedParams;
		PlayerPickupComponent.OnPutDownStartedEvent.Broadcast(PutDownStartedParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Eman TODO: Stupid, handle with animation
		LetGo();

		PlayerPickupComponent.CurrentPickup = CurrentPickup = nullptr;

		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Eman TODO: Wait until putdown animation lets the pickup go
		FQuat Rotation = FQuat::FastLerp(PickupStartRotation, FQuat::MakeFromXZ(PlayerOwner.ActorForwardVector, PlayerOwner.MovementWorldUp), Math::Saturate(ActiveDuration/ 0.5));
		CurrentPickup.Owner.SetActorRotation(Rotation);
	}

	void LetGo()
	{
		PlayerPickupComponent.DetachPickupActor();
		PlayerPickupComponent.bCarryingPickup = false;

		// Eman TODO: Make pickup nicely lerp to the ground
		FQuat Rotation = FQuat::MakeFromXZ(PlayerOwner.ActorForwardVector, PlayerOwner.MovementWorldUp);
		CurrentPickup.Owner.SetActorRotation(Rotation);

		FPutDownParams PutDownParams;
		PutDownParams.PickupComponent = CurrentPickup;
		PlayerPickupComponent.OnPutDownEvent.Broadcast(PutDownParams);
	}
}