
UCLASS(Abstract)
class UBabyDragonAirBoostEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintPure)
	ABabyDragon GetBabyDragon() const
	{
		auto DragonComp = UPlayerBabyDragonComponent::Get(Owner);
		return DragonComp.BabyDragon;
	}

	// When the player does the 'double jump' in the air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirBoostActivated() {}

	// When the player starts gliding
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedGliding() {}

	// When the player stops gliding
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StoppedGliding() {}
};