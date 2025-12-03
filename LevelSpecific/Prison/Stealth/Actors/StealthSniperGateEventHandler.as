UCLASS(Abstract)

class UStealthSniperGateEventHandler : UHazeEffectEventHandler
{
	AStealthSniperGate Gate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gate = Cast<AStealthSniperGate>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartReverseMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopReverseMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitRoof()
    {
	}
	
}