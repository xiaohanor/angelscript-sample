struct FSkylineAttackShipAttackEventData
{
	UPROPERTY()
	ASkylineAttackShipProjectileBase Projectile = nullptr;

	UPROPERTY()
	AHazePlayerCharacter TargetPlayer = nullptr;

	FSkylineAttackShipAttackEventData(AHazePlayerCharacter InPlayerTarget, ASkylineAttackShipProjectileBase InProjectile)
	{
		TargetPlayer = InPlayerTarget;
		Projectile = InProjectile;
	}
}

struct FSkylineAttackShipShieldEventData
{
	UPROPERTY()
	float ShieldDamageAmount = 0.0;

	UPROPERTY()
	bool bShieldBreak = false;
}

class USkylineAttackShipEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnStartAimLaser(FSkylineAttackShipAttackEventData Params) {}

	UFUNCTION(BlueprintEvent)
	void OnStopAimLaser(FSkylineAttackShipAttackEventData Params) {}

	UFUNCTION(BlueprintEvent)
	void OnFireMissiles(FSkylineAttackShipAttackEventData Params) {}

	UFUNCTION(BlueprintEvent)
	void OnShieldDamage(FSkylineAttackShipShieldEventData Params) {}

	UFUNCTION(BlueprintEvent)
	void OnWeakPointHit() {}

	UFUNCTION(BlueprintEvent)
	void OnCrash() {}
}