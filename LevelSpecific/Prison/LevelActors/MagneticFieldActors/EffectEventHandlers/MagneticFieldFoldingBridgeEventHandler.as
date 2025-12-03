UCLASS(Abstract)
class UMagneticFieldFoldingBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PiecePlaced(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PieceRetracted(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurst() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRolling(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRolling(){}
};