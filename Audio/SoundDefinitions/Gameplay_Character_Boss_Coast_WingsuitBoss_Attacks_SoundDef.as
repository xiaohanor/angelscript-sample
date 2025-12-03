
UCLASS(Abstract)
class UGameplay_Character_Boss_Coast_WingsuitBoss_Attacks_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ChangedPhase(FCoastBossEventHandlerPhaseData Params){}

	UFUNCTION(BlueprintEvent)
	void ChangedFormation(FCoastBossEventHandlerFormationData Params){}

	UFUNCTION(BlueprintEvent)
	void OnTakeDamage(){}

	UFUNCTION(BlueprintEvent)
	void Died(){}

	UFUNCTION(BlueprintEvent)
	void SpawnedBullets(FCoastBossEventHandlerSpawnedBulletsData Params){}

	UFUNCTION(BlueprintEvent)
	void SpawnedMill(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector2D _;
		float X = 0.0;
		float _Y = 0.0;
		if(Audio::GetScreenPositionRelativePanningValue(HazeOwner.ActorLocation, _, X, _Y))
		{
			DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0);
		}
	}
}