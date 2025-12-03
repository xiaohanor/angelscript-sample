//
// Eman TODO: Work in progress... still adding stuff
//

class AExamplePickup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	// In order to make something pickupable just add a pickup component,
	// you will be able to specify different settings via its PickupSettings
	UPROPERTY(DefaultComponent)
	UPickupComponent PickupComponent;
	default PickupComponent.PickupSettings.PickupType = EPickupType::Light;

	// If you want the player to be able to pick something up via an interaction, you'll need to
	// add an interaction component to your actor and specify the PickupInteractionSheet on it.
	//
	// OBS: You should ONLY use this interaction component for the pickup system, nothing else.
	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.InteractionSheet = Pickup::PickupInteractionSheet;

	UFUNCTION(BlueprintCallable)
	void PickupWithPlayer(AHazePlayerCharacter Player)
	{
		// You could also scrap the interaction component and manually tell a player to pick something up
		// by using the player pickup component. Just get a reference to it and pass in the pickup component.
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if (PlayerPickupComponent != nullptr)
		{
			PlayerPickupComponent.PickUp(PickupComponent);
		}
	}
}