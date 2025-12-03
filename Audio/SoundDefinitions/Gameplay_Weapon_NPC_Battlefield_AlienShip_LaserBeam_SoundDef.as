
UCLASS(Abstract)
class UGameplay_Weapon_NPC_Battlefield_AlienShip_LaserBeam_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaserStarted(FBattlefieldLaserStartedParams Params){}

	UFUNCTION(BlueprintEvent)
	void UpdateLaserPoint(FBattlefieldLaserUpdateParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLaserEnd(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	UHazeAudioEmitter LaserEndEmitter;
}