struct FSummitRotatingAbyssPlatformAlphaParams
{
	UPROPERTY()
	float Alpha;

	FSummitRotatingAbyssPlatformAlphaParams(float NewAlpha)
	{
		Alpha = NewAlpha;
	}
}

UCLASS(Abstract)
class USummitRotatingAbyssPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformMoveUp() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformMoveDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformTelegraphGoDownStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformTelegraphGoDownEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformTelegraphUpdateAlpha(FSummitRotatingAbyssPlatformAlphaParams Params) {}
};