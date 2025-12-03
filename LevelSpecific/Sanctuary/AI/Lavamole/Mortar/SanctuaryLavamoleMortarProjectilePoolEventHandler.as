UCLASS(Abstract)
class USanctuaryLavamoleMortarProjectilePoolEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAppear() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisappear() {}
};