
UCLASS(Abstract)
class UVO_Island_Stormdrain_ForcefieldTutorial_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Audio_OnHoleAlmostFullyClosed(FIslandRedBlueForceFieldAudioEffectParams IslandRedBlueForceFieldAudioEffectParams){}

	UFUNCTION(BlueprintEvent)
	void Audio_OnClosedHole(FIslandRedBlueForceFieldAudioEffectParams IslandRedBlueForceFieldAudioEffectParams){}

	UFUNCTION(BlueprintEvent)
	void Audio_OnHoleStartShrinking(FIslandRedBlueForceFieldAudioEffectParams IslandRedBlueForceFieldAudioEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnForceFieldActivated(){}

	UFUNCTION(BlueprintEvent)
	void OnForceFieldDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void OnNewHoleInForceField(FIslandRedBlueForceFieldOnGrenadeDetonateOnForceFieldParams IslandRedBlueForceFieldOnGrenadeDetonateOnForceFieldParams){}

	UFUNCTION(BlueprintEvent)
	void OnBulletReflectOnForceField(FIslandRedBlueForceFieldOnBulletReflectOnForceFieldParams IslandRedBlueForceFieldOnBulletReflectOnForceFieldParams){}

	/* END OF AUTO-GENERATED CODE */

}