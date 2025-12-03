
UCLASS(Abstract)
class UVO_Village_Square_WobblyPerchPoles_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	TArray<AVillageWobblyPerchPole> Poles;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Poles = TListedActors<AVillageWobblyPerchPole>().Array;
	}

}