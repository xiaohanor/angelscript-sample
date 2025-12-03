UCLASS(Abstract)
class UGravityBikeSplineAttackShipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBikeSplineAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<AGravityBikeSplineAttackShip>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackShipActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackShipDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged(FGravityBikeSplineEnemyTakeDamageData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartVeering() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFacePlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFaceForward() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenHatchStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenHatchFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseHatchStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseHatchFinished() {}
};