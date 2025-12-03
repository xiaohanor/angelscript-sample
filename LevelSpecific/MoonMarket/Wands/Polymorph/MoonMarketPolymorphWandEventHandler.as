UCLASS(Abstract)
class UMoonMarketPolymorphWandEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AWandPolymorph Wand;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wand = Cast<AWandPolymorph>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCasting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishCasting(FSpellHitData HitData) {}
};