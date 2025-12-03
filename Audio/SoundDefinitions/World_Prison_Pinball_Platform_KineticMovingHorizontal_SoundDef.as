
UCLASS(Abstract)
class UWorld_Prison_Pinball_Platform_KineticMovingHorizontal_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	UFUNCTION(BlueprintEvent)
	void OnMusicBeat()
	{

	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		UHazeAudioMusicManager::Get().OnMusicBeat.AddUFunction(this,n"OnMusicBeat");
	}

}