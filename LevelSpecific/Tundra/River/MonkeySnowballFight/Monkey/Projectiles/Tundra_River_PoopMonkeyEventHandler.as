struct FPoopMonkeyEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UTundra_River_PoopMonkeyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetectPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowPoop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPoopHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPoopHitGround() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitBySnowball(FPoopMonkeyEventData Params) {}
};