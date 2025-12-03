
UCLASS(Abstract)
class UCharacter_Boss_Skyline_MrHammer_Bolo_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnImpact(FSkylineTorBoloEventHandlerOnImpactData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter GreenEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter PurpleEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Music::Get().OnMusicBeat.AddUFunction(this, n"OnMusicBeat");
	}

	UFUNCTION(BlueprintEvent)
	void OnMusicBeat()
	{

	}
}