struct FSpaceWalkHackingEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USpaceWalkHackingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	// When the player browse shapes to the left
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrowseLeft(FSpaceWalkHackingEffectParams Params) {}
	// When the player browse shapes to the right
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrowseRight(FSpaceWalkHackingEffectParams Params) {}

	// When the player presses to make the shape move into the middle
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttemptShape(FSpaceWalkHackingEffectParams Params) {}

	// When a player's shape starts moving back to the start
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShapeCancelled(FSpaceWalkHackingEffectParams Params) {}

	// When a shape has been correctly filled by both players
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShapeFilled() {}
};