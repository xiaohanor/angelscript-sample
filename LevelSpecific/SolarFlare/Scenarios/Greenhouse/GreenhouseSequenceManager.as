event void FOnGreenhouseSequenceDestructionActivated();

class AGreenhouseSequenceManager : AHazeActor
{
	UPROPERTY()
	FOnGreenhouseSequenceDestructionActivated OnGreenhouseSequenceDestructionActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	AHazeLevelSequenceActor BreakSequenceActor;

	UPROPERTY(EditAnywhere)
	AHazeLevelSequenceActor DestroySequenceActor;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor ImpactEvent;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareCoverVolumeActor> CoverVolumes;

	UPROPERTY(EditAnywhere)
	TArray<AGreenhouseFogPlane> FogPlanes;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent GlassBreakAudioEvent;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent CompleteDestructionAudioEvent;

	int Counter;

	bool bIsDestructionEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactEvent.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		if (!bIsDestructionEnabled)
			return;

		Counter++;

		if (Counter == 1)
		{
			BreakSequenceActor.SequencePlayer.Play();
			UGreenhouseSequenceManagerEffectHandler::Trigger_OnGlassBreak(this);
			for (AGreenhouseFogPlane Plane : FogPlanes)
			{
				Plane.BP_VanishFogPlane();
			}

			if(GlassBreakAudioEvent != nullptr)
				AudioComponent::PostFireForget(GlassBreakAudioEvent, FHazeAudioFireForgetEventParams());
		}
		else if (Counter == 2)
		{
			DestroySequenceActor.SequencePlayer.Play();
			UGreenhouseSequenceManagerEffectHandler::Trigger_OnCompleteDestruction(this);

			if(CompleteDestructionAudioEvent != nullptr)
				AudioComponent::PostFireForget(CompleteDestructionAudioEvent, FHazeAudioFireForgetEventParams());
			
			for (ASolarFlareCoverVolumeActor CoverVolume : CoverVolumes)
				CoverVolume.AddDisabler(this);

			OnGreenhouseSequenceDestructionActivated.Broadcast();
		}
	}

	UFUNCTION()
	void EnableGreenhouseDestruction()
	{
		bIsDestructionEnabled = true;
	}
};