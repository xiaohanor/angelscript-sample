
UCLASS(Abstract)
class UWorld_Skyline_Shared_Interactable_SkylineBrokenElectricBox_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPulseArrived(){}

	UFUNCTION(BlueprintEvent)
	void OnHit(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(Category = "Emitters", DisplayName = "Emitter - Cable Pulse")
	UHazeAudioEmitter CablePulseEmitter;

	UPROPERTY(EditInstanceOnly)
	float AttenuationScaling = 1000;

	UPROPERTY(EditInstanceOnly, Category = "Master", DisplayName = "Master - Voice Volume")
	float MasterVoiceVolume = 0;

	UPROPERTY(EditInstanceOnly, Category = "Master", DisplayName = "Master - Make-Up Gain")
	float MasterMakeUpGain = 0;

	UPROPERTY(EditInstanceOnly, Category = "Master", DisplayName = "Master - Pitch")
	float MasterPitch = 0;

	UPROPERTY(EditInstanceOnly, Category = "Pulse", DisplayName = "Pulse - Pitch Start", Meta = (ForceUnits = "hz"))
	float PulsePitchStart = 0.0;

	UPROPERTY(EditInstanceOnly, Category = "Pulse", DisplayName = "Pulse - Pitch End", Meta = (ForceUnits = "hz"))
	float PulsePitchEnd = 0.0;

	ASkylineBrokenElectricBox ElectricBox;

	private bool GetbIsPulseActive() const property
	{
		return ElectricBox.IsActorTickEnabled();
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ElectricBox = Cast<ASkylineBrokenElectricBox>(HazeOwner);
		CablePulseEmitter.AudioComponent.AttachToComponent(ElectricBox.SparkVFXComp);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Pulse Alpha"))
	float GetPulseAlpha()
	{
		return Math::Min(1, ElectricBox.ProgressAlongCable / ElectricBox.SplineComp.SplineLength);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Activation Time"))
	float GetActivationTime()
	{
		return ElectricBox.ActivationDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bIsPulseActive)	
			TickPulse(DeltaSeconds);

	}

	UFUNCTION(BlueprintEvent)
	void TickPulse(float DeltaSeconds) {}
}