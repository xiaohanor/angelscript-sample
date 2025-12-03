UCLASS(Abstract)
class UPinballBossDamageZoneEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballBossDamageZone DamageZone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DamageZone = Cast<APinballBossDamageZone>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamageBoss() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetAfterDamageBoss() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}
};