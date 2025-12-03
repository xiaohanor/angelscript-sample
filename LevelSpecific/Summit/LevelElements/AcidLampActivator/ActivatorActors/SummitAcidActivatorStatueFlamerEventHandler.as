UCLASS(Abstract)
class USummitAcidActivatorStatueFlamerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlameActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlameDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAcidSprayStartedHitting() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAcidSprayStoppedHitting() {}

	ASummitAcidActivatorStatueFlamer Flamer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Flamer = Cast<ASummitAcidActivatorStatueFlamer>(Owner);
	}

	UFUNCTION(BlueprintPure, Meta = (AutoCreateBPNode))
	float GetFillAlpha() const
	{
		return Flamer.GetEnergyRuneAlpha();
	}
};