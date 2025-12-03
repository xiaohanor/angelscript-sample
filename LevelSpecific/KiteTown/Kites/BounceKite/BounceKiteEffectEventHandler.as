UCLASS(Abstract)
class UBounceKiteEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Bounce() {}
}