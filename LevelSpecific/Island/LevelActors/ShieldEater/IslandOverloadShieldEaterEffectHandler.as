struct FIslandOverloadShieldEaterCreateBeamEffectParams
{
	UPROPERTY()
	USceneComponent StartPoint;

	UPROPERTY()
	USceneComponent EndPoint;
}

UCLASS(Abstract)
class UIslandOverloadShieldEaterEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, Transient, BlueprintReadOnly)
	AIslandOverloadShieldEater ShieldEater;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShieldEater = Cast<AIslandOverloadShieldEater>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCreateBeam(FIslandOverloadShieldEaterCreateBeamEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecharge() {}
}