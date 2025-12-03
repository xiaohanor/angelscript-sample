
UCLASS(Abstract)
class UIsland_Tower_RedBlue_PhasablePlatformJetpack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnParticlesBeginPhasing(){}

	UFUNCTION(BlueprintEvent)
	void OnParticlesStopPhasing(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerPhaseThrough(FPhasableWallEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerKilled(FPhasableWallEventData Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	AIslandPhasablePlatform Platform;

	UPROPERTY()
	UHazeAudioActorMixer OpenLoopAmix;

	UPROPERTY()
	UHazeAudioActorMixer ShardsLoopAmix;

	UPROPERTY()
	UHazeAudioActorMixer ClosedLoopAmix;

	float PreviousAlpha = -1;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Platform = Cast<AIslandPhasablePlatform>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto NewAlpha = Platform.Audio_GetPlayerToPhasablePlatformAlpha();

		if (Math::IsNearlyEqual(NewAlpha, PreviousAlpha))
			return;

		PreviousAlpha = NewAlpha;

		auto MakeupGain = -15 * NewAlpha;
		// Is the inverted makeup gain value
		auto VoiceVolume = -15 * (1 - NewAlpha);

		DefaultEmitter.SetNodeProperty(OpenLoopAmix, EHazeAudioNodeProperty::MakeUpGain, MakeupGain);
		DefaultEmitter.SetNodeProperty(ShardsLoopAmix, EHazeAudioNodeProperty::MakeUpGain, MakeupGain);
		DefaultEmitter.SetNodeProperty(ClosedLoopAmix, EHazeAudioNodeProperty::VoiceVolume, VoiceVolume);
	}
}