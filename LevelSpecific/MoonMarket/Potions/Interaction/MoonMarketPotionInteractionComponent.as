UCLASS(Abstract)
class UMoonMarketPotionInteractionComponent : UActorComponent
{
	UPROPERTY()
	FHazePlaySlotAnimationParams InteractionAnimation;

	private UHazeCapabilitySheet CurrentActiveSheet;

	AHazePlayerCharacter Player;
	UMoonMarketShapeshiftComponent ShapeshiftComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShapeshiftComponent = UMoonMarketShapeshiftComponent::GetOrCreate(Player);
	}

	void BeginInteraction(AMoonMarketPotion Potion)
	{
		CurrentActiveSheet = Potion.SheetToStartWhenConsumed;

		//IF player was about to morph into something, make sure to cancel this
		UPolymorphResponseComponent::Get(Owner).DesiredMorphClass = nullptr;

		Player.StartCapabilitySheet(CurrentActiveSheet, this);
	}

	void StopCurrentInteraction()
	{
		if(CurrentActiveSheet == nullptr)
			return;

		Player.StopCapabilitySheet(CurrentActiveSheet, this);
		CurrentActiveSheet = nullptr;
	}
};