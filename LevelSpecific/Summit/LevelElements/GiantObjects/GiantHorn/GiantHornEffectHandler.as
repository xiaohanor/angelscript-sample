struct FOnGiantHornBlowParams
{
	UPROPERTY()
	USceneComponent BlowPoint;
}

UCLASS(Abstract)
class UGiantHornEffectHandler : UHazeEffectEventHandler
{
	/** When dragon starts blowing */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHornBlow(FOnGiantHornBlowParams Params) {}
	
	/** When dragon stops blowing */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHornBlowStop() {}

	/** When button is pressed */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHornStartedBlowing() {}

	/** When button is released */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHornStoppedBlowing() {}

}