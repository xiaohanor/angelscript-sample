UCLASS(Abstract)
class UPrisonBossVersusButtonMashEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ButtonMashStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Fail() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Success() {}
}