struct FSkylineEnemyMissileEventData
{
	ASkylineFlyingCarEnemyMissile Missile;

	FSkylineEnemyMissileEventData() {}
	FSkylineEnemyMissileEventData(ASkylineFlyingCarEnemyMissile EventMissile)
	{
		Missile = EventMissile;
	}
}

UCLASS(Abstract)
class USkylineFlyingCarEnemyMissileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HomingIn(FSkylineEnemyMissileEventData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ClosingIn(FSkylineEnemyMissileEventData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode(FSkylineEnemyMissileEventData Data) { }
};