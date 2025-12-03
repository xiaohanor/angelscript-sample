UCLASS(Abstract)
class UIslandJetpackEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AIslandJetpack Jetpack;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetpack = Cast<AIslandJetpack>(Owner);
		Player = Jetpack.Player;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetpackActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetpackDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterCancel() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBoostStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBoostStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBoostFirstActivation() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetpackDash() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FuelEmpty() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FuelStartRecharge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FuelFullyCharged() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitPhasableWall() {}
}