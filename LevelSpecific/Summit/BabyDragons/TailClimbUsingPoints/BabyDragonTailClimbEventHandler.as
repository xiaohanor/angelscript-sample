
UCLASS(Abstract)
class UBabyDragonTailClimbEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintPure)
	ABabyDragon GetBabyDragon() const
	{
		auto DragonComp = UPlayerBabyDragonComponent::Get(Owner);
		return DragonComp.BabyDragon;
	}

	// Player launched off to the first climb point
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedClimbEnter() {}

	// Player finished entering the climb and is now hanging from a climb point
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedClimbEnter() {}

	// Player started hopping from one climb point to another
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedClimbTransfer() {}

	// Player has finished hopping from one climb point to another
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedClimbTransfer() {}
};