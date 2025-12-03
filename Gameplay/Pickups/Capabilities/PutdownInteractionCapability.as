// Puts down pickup at specific location
class UPutdownInteractionCapability : UInteractionCapability
{
	default CapabilityTags.Add(PickupTags::Pickups);
	default CapabilityTags.Add(PickupTags::PutdownInteractionCapability);

	UPutdownInteractionComponent PutdownInteractionComponent;
	UPlayerPickupComponent PlayerPickupComponent;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		UPutdownInteractionComponent PutdownInteraction = Cast<UPutdownInteractionComponent>(CheckInteraction);
		if (PutdownInteraction == nullptr)
			return false;

		// Eman TODO: Optional?
		// if (PutdownInteraction.PickupInSocket != nullptr)
		// 	return false;

		UPlayerPickupComponent PlayerPickupComp = UPlayerPickupComponent::Get(Player);
		if (PlayerPickupComp == nullptr)
			return false;

		if (PlayerPickupComp.GetCurrentPickup() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Get player pickup component
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);

		// Get data and setup putdown interaction component
		PutdownInteractionComponent = Cast<UPutdownInteractionComponent>(ActivationParams.Interaction);
		PutdownInteractionComponent.PickupInSocket = PlayerPickupComponent.CurrentPickup;

		ActivationParams.Interaction.Disable(this);

		// Fire putdown started event
		FPutDownStartedParams PutDownStartedParams;
		PlayerPickupComponent.OnPutDownStartedEvent.Broadcast(PutDownStartedParams);

		PutDown();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Eman TODO: Do we want to enable this after interaction has completed?
		ActiveInteraction.Enable(this);

		Super::OnDeactivated();
		PutdownInteractionComponent = nullptr;
		PlayerPickupComponent = nullptr;
	}

	void PutDown()
	{
		// Eman TODO: Play animation and put shit down after it's done

		LetGo();
	}

	void LetGo()
	{
		PlayerPickupComponent.DetachPickupActor();
		PlayerPickupComponent.bCarryingPickup = false;

		AActor PickupActor = PutdownInteractionComponent.PickupInSocket.Owner;

		// Eman TODO: Lerp into position
		PickupActor.AttachToComponent(PutdownInteractionComponent);

		FHitResult HitResult;
		PickupActor.SetActorRelativeLocation(PutdownInteractionComponent.PickupSocketTransform.Translation, false, HitResult, true);
		PickupActor.SetActorRelativeRotation(PutdownInteractionComponent.PickupSocketTransform.Rotator(), false, HitResult, true);

		UPlayerInteractionsComponent::Get(Player).KickPlayerOutOfInteraction(ActiveInteraction);

		// Fire player pickup component putdown event
		FPutDownParams PutDownParams;
		PutDownParams.PickupComponent = PutdownInteractionComponent.PickupInSocket;
		PlayerPickupComponent.OnPutDownEvent.Broadcast(PutDownParams);

		// Fire putdown interaction putdown-in-socket event
		PutdownInteractionComponent.OnPickupPlacedInSocketEvent.Broadcast(PutdownInteractionComponent.PickupInSocket);
	}
}