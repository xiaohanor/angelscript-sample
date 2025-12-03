class APickupBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UPickupComponent PickupComponent;
	default PickupComponent.PickupSettings.PickupType = EPickupType::Light;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.InteractionSheet = Pickup::PickupInteractionSheet;	
}