
UCLASS(Abstract)
class UVO_Tundra_Swamp_SideContent_BigSwing_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnterSwing(FTundraSideInteractSwingInteractEffectParams TundraSideInteractSwingInteractEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitSwing(FTundraSideInteractSwingInteractEffectParams TundraSideInteractSwingInteractEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnSnowMonkeyPunchSwing(FTundraSideInteractSwingPushEffectParams TundraSideInteractSwingPushEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnSwingingPlayerLaunched(FTundraSideInteractSwingLaunchEffectParams TundraSideInteractSwingLaunchEffectParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	APlayerLookAtTrigger LookAtTrigger;

	UPROPERTY(EditAnywhere)
	ATundraSideInteractSwing Swing;
}