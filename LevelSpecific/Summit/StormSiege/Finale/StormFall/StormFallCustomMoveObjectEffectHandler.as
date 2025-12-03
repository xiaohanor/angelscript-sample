struct FStormFallCustomMoveObjectMoveAlphaParams
{
	UPROPERTY()
	float Alpha;

	FStormFallCustomMoveObjectMoveAlphaParams(float NewAlpha)
	{
		Alpha = NewAlpha;
	}
} 

UCLASS(Abstract)
class UStormFallCustomMoveObjectEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCustomObjectStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCustomObjectStoppedMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCustomObjectUpdateMoveAlpha(FStormFallCustomMoveObjectMoveAlphaParams Params) {}
};