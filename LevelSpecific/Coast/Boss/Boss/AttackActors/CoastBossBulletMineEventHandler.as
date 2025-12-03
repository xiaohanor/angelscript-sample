struct FCoastBossBulletMineBeepData
{
	UPROPERTY(BlueprintReadOnly)
	float TimeUntilNextBeep = 1.0;
}

UCLASS(Abstract)
class UCoastBossBulletMineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Detonate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Beep(FCoastBossBulletMineBeepData Data) {}
};