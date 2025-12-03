
struct FEngineersRunningData
{
	UPROPERTY()
	UHazeAudioEmitter Emitter;

	UPROPERTY()
	FHazeAudioPostEventInstance EventInstance;

	UPROPERTY()
	bool bFinishedPanicScream = false;

	FEngineersRunningData(UHazeAudioEmitter InEmitter, const FHazeAudioPostEventInstance InPostInstance)
	{
		Emitter = InEmitter;
		EventInstance = InPostInstance;
	}
}

UCLASS(Abstract)
class UWorld_SolarFlare_Shared_Event_EngineersRunning_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */


	UPROPERTY()
	ASolarFlareWaveImpactEventActor EventActor;

	UPROPERTY()
	USceneComponent EndLocationComp;

	TArray<FEngineersRunningData> Instances;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		EventActor = Cast<ASolarFlareWaveImpactEventActor>(HazeOwner);
		EndLocationComp = USceneComponent::Get(HazeOwner, n"AudioEndTargetLocation");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EventActor.OnSolarWaveImpactImpostersTriggered.AddUFunction(this, n"OnImpostersTriggered");
		EventActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnShockwaveTriggered");

		if (bFirstActivation && EventActor.LastImposterDuration != 0)
		{
			OnImpostersTriggered(EventActor.LastImposterDuration);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		EventActor.OnSolarWaveImpactImpostersTriggered.Unbind(this, n"OnImpostersTriggered");
		EventActor.OnSolarWaveImpactEventActorTriggered.Unbind(this, n"OnShockwaveTriggered");

		for (int i = Instances.Num() - 1; i >= 0; --i)
		{
			Audio::ReturnPooledEmitter(this, Instances[i].Emitter);
		}

		Instances.Empty();
	}

	UFUNCTION()
	void MoveComponentTowards(FEngineersRunningData& Instance, float DeltaSeconds, float Speed)
	{
		Instance.Emitter.AudioComponent.WorldLocation = Instance.Emitter.AudioComponent.WorldLocation.MoveTowards(EndLocationComp.WorldLocation, DeltaSeconds * Speed);

		Instance.Emitter.SetScreenRelativePostionPanning();
	}

	UFUNCTION(BlueprintEvent)
	private void OnImpostersTriggered(float Duration)
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnShockwaveTriggered()
	{
	}

	UFUNCTION()
	void AddNewInstance(UHazeAudioEvent PanicScreamEvent, float AttenuationScaling)
	{
		if (PanicScreamEvent == nullptr)
			return;

		auto Params = FHazeAudioEmitterAttachmentParams();
		Params.Owner = HazeOwner;
		Params.Transform = HazeOwner.ActorTransform;
		Params.Instigator = this;
		Params.bCanAttach = false;
		Params.EmitterName = n"EngineersPanic";
		Params.bSetOverrideTransform = true;

		auto Emitter = Audio::GetPooledEmitter(Params);
		Emitter.AttenuationScaling = AttenuationScaling;
		const auto& NewPostInstance = Emitter.PostEvent(PanicScreamEvent);

		Instances.Add(FEngineersRunningData(Emitter, NewPostInstance));
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for (int i = Instances.Num() - 1; i >= 0; --i)
		{
			auto& Instance = Instances[i];

			if (!Instance.bFinishedPanicScream)
				MoveComponentTowards(Instance, DeltaSeconds, 500);

			if (!Instance.Emitter.IsPlaying())
			{
				Audio::ReturnPooledEmitter(this, Instance.Emitter);
				Instances.RemoveAtSwap(i);
			}
		}
	}

	UFUNCTION()
	void StopSoundOnAllEmitters(UHazeAudioEvent DeathScream)
	{
		if (DeathScream == nullptr)
			return;

		for (int i = Instances.Num() - 1; i >= 0; --i)
		{
			auto& Instance = Instances[i];

			Instance.EventInstance.Stop(100);
			Instance.Emitter.PostEvent(DeathScream);
			Instance.bFinishedPanicScream = true;
		}
	}

}