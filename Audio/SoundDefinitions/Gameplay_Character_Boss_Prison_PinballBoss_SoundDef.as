
UCLASS(Abstract)
class UGameplay_Character_Boss_Prison_PinballBoss_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnMagnetDroneStartAttractToKnockdown(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossIntro(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossPhase1(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossPhase2(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossPhase25(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossPhase3(){}

	UFUNCTION(BlueprintEvent)
	void StartPinballBossPhase35(){}

	UFUNCTION(BlueprintEvent)
	void OnStartLaser(){}

	UFUNCTION(BlueprintEvent)
	void OnRocketFired(){}

	UFUNCTION(BlueprintEvent)
	void OnKnockedOut(){}

	UFUNCTION(BlueprintEvent)
	void OnBallReturn(){}

	UFUNCTION(BlueprintEvent)
	void ChargeAttackInterrupted(){}

	UFUNCTION(BlueprintEvent)
	void ChargeAttack(){}

	UFUNCTION(BlueprintEvent)
	void OnSmallDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnBecomeVulnerable(){}

	UFUNCTION(BlueprintEvent)
	void OnKillDamage(){}

	/* END OF AUTO-GENERATED CODE */

	APinballBoss PinballBoss;
	FVector PreviousLocation;
	FVector PreviousVelo;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PinballBoss = Cast<APinballBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float X;
		float _Y;
		FVector2D Previous;
		Audio::GetScreenPositionRelativePanningValue(PinballBoss.ActorLocation, Previous, X, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
	}

	UFUNCTION(BlueprintPure)
	float GetChaseDistance()
	{
		return PinballBoss.ChaseDistance;
	}

	UFUNCTION(BlueprintPure)
	float GetChaseRotation()
	{
		return PinballBoss.BallChaseRotationDistance;
	}

}