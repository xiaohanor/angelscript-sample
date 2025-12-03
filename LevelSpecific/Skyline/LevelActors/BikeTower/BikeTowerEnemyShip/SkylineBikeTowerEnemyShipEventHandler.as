UCLASS(Abstract)
class USkylineBikeTowerEnemyShipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBikeTowerEnemyShip Ship;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ship = Cast<ASkylineBikeTowerEnemyShip>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
};