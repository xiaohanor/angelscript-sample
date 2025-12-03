struct FTeenDragonTailRollAttackImpactParams
{
	UPROPERTY()
	ETailAttackImpactType ImpactType;
	UPROPERTY()
	UTeenDragonTailAttackResponseComponent HitComponent;
	UPROPERTY()
	FVector RollAreaCenter;
}

UCLASS(Abstract)
class UTeenDragonTailRollAttackEventHandler : UHazeEffectEventHandler
{

	// UFUNCTION(BlueprintPure)
	// ATeenDragon GetTeenDragon() const
	// {
	// 	auto DragonComp = UPlayerTeenDragonComponent::Get(Owner);
	// 	return DragonComp.TeenDragon;
	// }

	// When the dragon first starts the roll attack at its current location
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollAreaAttackStarted() {}

	// When the roll attack hits a target in the target area
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollAreaAttackImpact(FTeenDragonTailRollAttackImpactParams Impact) {}
}