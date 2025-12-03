
UCLASS(Abstract)
class UWorld_Sanctuary_Shared_Interactable_LightBirdSocket_Object_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLightBirdEnter(FSanctuaryLightBirdSocketEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	ULightBirdResponseComponent LightResponse;
	USanctuaryLightMeshAudioComponent LightMeshAudioComp;
	TArray<FAkSoundPosition> SoundPositions;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UHazeAudioEmitter LightPlaneEmitter;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LightResponse == nullptr)
			return false;

		return LightResponse.bIsAttached;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !LightResponse.bIsAttached;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"LightPlaneEmitter")
		{
			bUseAttach = false;
			return false;
		}

		bUseAttach = true;
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LightResponse = ULightBirdResponseComponent::Get(HazeOwner);
		LightMeshAudioComp = USanctuaryLightMeshAudioComponent::Get(HazeOwner);

		if(LightResponse == nullptr)
		{
			#if EDITOR
			devCheck(false, "No LightBirdResponseComponent on LightBirdSocket-SoundDef owner: " + HazeOwner.ActorNameOrLabel);
			#endif

			return;
		}

		LightResponse.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightResponse.OnUnilluminated.AddUFunction(this, n"OnDelluminated");	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(LightMeshAudioComp != nullptr)
		{
			LightMeshAudioComp.GetLightMeshAudioPositions(SoundPositions);
			LightPlaneEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnIlluminated() {}

	UFUNCTION(BlueprintEvent)
	void OnDelluminated() {}

}