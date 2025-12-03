// This capability is used when picking something up through an actor's interaction component
class UPickupInteractionCapability : UInteractionCapability
{
	default CapabilityTags.Add(PickupTags::Pickups);
	default CapabilityTags.Add(PickupTags::PickupInteractionCapability);

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (UPlayerPickupComponent::Get(Owner) == nullptr)
			return false;

		if (UPickupComponent::Get(CheckInteraction.Owner) == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Eman TODO: Deactivate interaction component

		// Tell player pickup component to pickup object
		UPickupComponent PickupComponent = UPickupComponent::Get(ActivationParams.Interaction.Owner);
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);
		PlayerPickupComponent.PickUp(PickupComponent);

		// Disable interaction so that other player can't fuck with it
		ActivationParams.Interaction.Disable(this);

		// Subscribe to pickup component's putdown event so we stop interacting with interaction component
		PlayerPickupComponent.OnPutDownEvent.AddUFunction(this, n"OnPutDown");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Eman TODO: Do this after putdown animation is done!
		ActiveInteraction.Enable(this);

		Super::OnDeactivated();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPutDown(FPutDownParams PutDownParams)
	{
		// Get actor's interaction component
		PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteraction);
	}
}