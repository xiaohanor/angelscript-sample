UCLASS(Abstract)
class UPinballBossEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	APinballBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBecomeVulnerable() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndVulnerable() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLaser() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLaser() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketFired() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossIntro () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossPhase1 () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossPhase2 () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossPhase25 () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossPhase3 () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPinballBossPhase35 () {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagnetDroneStartAttractToKnockdown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmallDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKnockedOut() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallReturn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeAttack() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeAttackInterrupted() {}
		
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeAttackExplosion() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DyingExplosion() {}
};