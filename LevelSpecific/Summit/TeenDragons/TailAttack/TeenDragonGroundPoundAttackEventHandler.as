struct FTeenDragonGroundPoundAttackImpactParams
{
	UPROPERTY()
	ETailAttackImpactType ImpactType;
	UPROPERTY()
	UTeenDragonTailAttackResponseComponent HitComponent;
	UPROPERTY()
	FVector AttackAreaCenter;
}

UCLASS(Abstract)
class UTeenDragonGroundPoundAttackEventHandler : UHazeEffectEventHandler
{

	// UFUNCTION(BlueprintPure)
	// ATeenDragon GetTeenDragon() const
	// {
	// 	auto DragonComp = UPlayerTeenDragonComponent::Get(Owner);
	// 	return DragonComp.TeenDragon;
	// }

	// When the ground pound attack is first started in the air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundPoundAttackTriggered() {}

	// When we start diving to the ground after hanging in the air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundPoundDiveStarted() {}

	// When we hit the ground with our attack
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundPoundLanded() {}

	// Called for every impact that the ground pound attack hits
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackAreaImpact(FTeenDragonGroundPoundAttackImpactParams Impact) {}

	// After the attack is fully done and ended
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundPoundAttackEnded() {}
}