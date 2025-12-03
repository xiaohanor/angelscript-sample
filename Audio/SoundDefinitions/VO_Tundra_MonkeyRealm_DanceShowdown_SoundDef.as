
UCLASS(Abstract)
class UVO_Tundra_MonkeyRealm_DanceShowdown_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFail(FDanceShowdownPlayerEventData DanceShowdownPlayerEventData){}

	UFUNCTION(BlueprintEvent)
	void OnSuccess(FDanceShowdownPlayerEventData DanceShowdownPlayerEventData){}

	UFUNCTION(BlueprintEvent)
	void OnCorrectPoseEntered(FDanceShowdownPoseData DanceShowdownPoseData){}

	UFUNCTION(BlueprintEvent)
	void OnTutorialPoseEntered(){}

	UFUNCTION(BlueprintEvent)
	void OnStopMonkeyOnHead(FDanceShowdownPlayerEventData DanceShowdownPlayerEventData){}

	UFUNCTION(BlueprintEvent)
	void OnStartMonkeyOnHead(FDanceShowdownPlayerEventData DanceShowdownPlayerEventData){}

	UFUNCTION(BlueprintEvent)
	void DanceShowdown_OnPoseUpdated(FDanceShowdownNewPoseEvent DanceShowdownNewPoseEvent){}

	UFUNCTION(BlueprintEvent)
	void DanceShowdown_OnSequenceSucceeded(FDanceShowdownSequenceSucceededEvent DanceShowdownSequenceSucceededEvent){}

	UFUNCTION(BlueprintEvent)
	void DanceShowdown_OnLastBeat(FDanceShowdownLastBeatEvent DanceShowdownLastBeatEvent){}

	/* END OF AUTO-GENERATED CODE */

UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UHazeAudioMusicManager::Get().OnMusicBar.AddUFunction(this,n"OnMusicBar");
	}

UFUNCTION(BlueprintEvent)
    void OnMusicBar()
    {

    }

}