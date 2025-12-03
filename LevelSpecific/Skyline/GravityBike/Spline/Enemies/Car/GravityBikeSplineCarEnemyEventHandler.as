UCLASS(Abstract)
class UGravityBikeSplineCarEnemyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBikeSplineCarEnemy CarEnemy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged(FGravityBikeSplineEnemyTakeDamageData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartVeering() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
};