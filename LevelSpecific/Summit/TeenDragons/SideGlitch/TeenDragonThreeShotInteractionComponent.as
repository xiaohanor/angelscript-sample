class UTeenDragonThreeShotInteractionComponent : UThreeShotInteractionComponent
{
	default InteractionSheet = TeenDragonThreeShotInteractionSheet;
	UPROPERTY(EditAnywhere, Category = "Three Shot Interaction")
	TPerPlayer<FThreeShotSettings> DragonThreeShotSettings;
}

asset TeenDragonThreeShotInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"TeenDragonThreeShotInteractionCapability");

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};