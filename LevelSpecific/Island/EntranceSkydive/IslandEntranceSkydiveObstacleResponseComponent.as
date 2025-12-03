event void FIslandEntranceSkydiveObstacleOnImpact(AHazePlayerCharacter Player);

UCLASS(HideCategories = "Activation Cooking Navigation")
class UIslandEntranceSkydiveObstacleResponseComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FIslandEntranceSkydiveObstacleOnImpact OnImpact;

	UPROPERTY(EditAnywhere)
	bool bIgnoreCollisionWithAllComponents = true;

	/**
	 * If bIgnoreCollisionWithAllComponents is false, we only ignore collision with components with this tag
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bIgnoreCollisionWithAllComponents"))
	FName IgnoreCollisionTag = n"IgnoreAfterImpact";

	void BroadcastOnImpact(AHazePlayerCharacter Player, FVector ImpactLocation)
	{
		OnImpact.Broadcast(Player);

		auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		SkydiveComp.RequestHitReaction(ImpactLocation);
	}
};