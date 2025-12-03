UCLASS(Abstract)
class UGravityBikeSplineBikeEnemyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineBikeEnemy BikeEnemy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnemyActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnemyDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGroundImpact() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJump() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged(FGravityBikeSplineEnemyTakeDamageData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartCrashing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
};