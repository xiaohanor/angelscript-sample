struct FTundraFloatingPolePoleEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UTundraFloatingPoleClimbEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerAttachToPole(FTundraFloatingPolePoleEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerJumpFromPole(FTundraFloatingPolePoleEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachOtter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DetachOtter() {}
}