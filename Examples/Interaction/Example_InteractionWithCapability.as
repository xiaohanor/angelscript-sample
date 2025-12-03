
/**
 * This is an example of an actor that has an interaction with a specific
 * capability / sheet that should be used while in the interaction.
 */
class AExample_InteractionWithCapability : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UInteractionComponent Interaction;

	// Set the capability that this interaction will use while the player is inside it
	default Interaction.InteractionCapability = n"ExampleCapability_Interaction";

	// Allow the player to cancel the interaction by pressing Q/B
	default Interaction.bPlayerCanCancelInteraction = true;

	// We set the interaction to use a smooth teleport
	default Interaction.MovementSettings = FMoveToParams::SmoothTeleport();
};

/**
 * An example of a capability that becomes active when a specific kind of interaction is active.
 *
 * Interaction capabilities should override `SupportsInteraction` to determine which interactions
 * they want to be used for.
 *
 * The UInteractionCapability parent class then takes care of activating/deactivating the capability.
 *
 * You will have access to the `ActiveInteraction` variable with the component that the player is using.
 */
class UExampleCapability_Interaction : UInteractionCapability
{
	AExample_InteractionWithCapability InteractionActor;

	// Determines whether this interaction capability is intended for the given interaction
	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		// Only interact if the actor is of the correct class
		if (!CheckInteraction.Owner.IsA(AExample_InteractionWithCapability))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		// `ActiveInteraction` is available here as the interaction component the player is using
		InteractionActor = Cast<AExample_InteractionWithCapability>(ActiveInteraction.Owner);

		// `Player` is available here as the player that is interacting
		Print("Interaction Activated by "+Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Example Interaction Capability Active: "+InteractionActor);

		// Automatically exit the interaction after 5 seconds
		if (ActiveDuration > 5.0)
			LeaveInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Print("Interaction Deactivated!");
	}
};