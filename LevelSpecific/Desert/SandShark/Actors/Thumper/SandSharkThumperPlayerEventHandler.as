UCLASS(Abstract)
class USandSharkThumperPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThumpSuccess(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThumpFail(){}
};