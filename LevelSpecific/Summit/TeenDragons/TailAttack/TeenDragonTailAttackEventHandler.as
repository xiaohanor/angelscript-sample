struct FTeenDragonTailAttackImpactParams
{
	UPROPERTY()
	ETailAttackImpactType ImpactType;
	UPROPERTY()
	FVector Location;
	UPROPERTY()
	FVector Normal;
}

UCLASS(Abstract)
class UTeenDragonTailAttackEventHandler : UHazeEffectEventHandler
{

	// UFUNCTION(BlueprintPure)
	// ATeenDragon GetTeenDragon() const
	// {
	// 	auto DragonComp = UPlayerTeenDragonComponent::Get(Owner);
	// 	return DragonComp.TeenDragon;
	// }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TailAttackImpact(FTeenDragonTailAttackImpactParams Params) {}
}