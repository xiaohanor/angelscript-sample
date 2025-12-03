
struct FWorldDestructiblesPropCollisionParams
{
	UPROPERTY()
	FVector CollisionLocation;
}

UCLASS(Abstract)
class UWorld_Destructible_Prop_SoundDef : USoundDefBase
{
	UPROPERTY(Category = "Global")
	bool bShouldDeactivate = false;
	
	UFUNCTION(BlueprintOverride)
	bool CanDeactivate() const
	{
		return bShouldDeactivate;
	}

	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TriggerOnDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnCollision(FWorldDestructiblesPropCollisionParams WorldDestructiblesPropCollisionParams){}

	/* END OF AUTO-GENERATED CODE */

}