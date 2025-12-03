UCLASS(Abstract)
class URedSpaceTetherEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ARedSpaceTether Tether;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tether = Cast<ARedSpaceTether>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TetherEnabled() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TetherDisabled() {}
}