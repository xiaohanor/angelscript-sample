UCLASS(Abstract)
class UZipKitePlayerEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrappleStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrappleConnected() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartZipping() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchUp() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landed() {}
}