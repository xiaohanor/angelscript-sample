
UCLASS(Abstract)
class UBabyDragonZiplineEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintPure)
	ABabyDragon GetBabyDragon() const
	{
		auto DragonComp = UPlayerBabyDragonComponent::Get(Owner);
		return DragonComp.BabyDragon;
	}

	// Player started ziplining with the baby tail dragon
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedZipline() {}

	// Player stopped ziplining with the baby tail dragon
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StoppedZipline() {}
};