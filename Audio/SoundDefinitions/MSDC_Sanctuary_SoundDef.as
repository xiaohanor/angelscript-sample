

struct FHazeMusicSanctuaryBelowProxy
{
	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeAudioAuxBus> Buses;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioAuxBus AuxSend;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioBus MusicBus;

	UPROPERTY(EditDefaultsOnly)
	float AttenuationScaling = 5000;
}

UCLASS(Abstract)
class UMSDC_Sanctuary_SoundDef : UHazeMusicSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	FHazeMusicSanctuaryBelowProxy SpatializationProxy;

	bool bPlayingSpatializationProxy = false;
	private UHazeAudioEmitter MusicEmitter;

	private const FHazeAudioID Rtpc_Sanctuary_Below_Choirs_Volume = FHazeAudioID("Rtpc_Sanctuary_Below_Choirs_Volume");

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		OnMusicStateChanged.BindUFunction(this, n"OnSanctuaryMusicStateChanged");
		MusicEmitter = UHazeAudioMusicManager::Get().Emitter;
	}

	UFUNCTION()
	void StartProxyRequest()
	{
		if (bPlayingSpatializationProxy)
			return;

		bPlayingSpatializationProxy = true;
		// Controls if the choir buses can play at all.
		// We need this to ensure when we remove the proxy that they don't route to the player listeners.
		MusicEmitter.SetRTPC(Rtpc_Sanctuary_Below_Choirs_Volume, 1, 0);

		for (int i=0; i < SpatializationProxy.Buses.Num(); ++i)
		{
			FHazeProxyEmitterRequest ProxyRequest;
			ProxyRequest.Target = this;
			ProxyRequest.Instigator = this;
			ProxyRequest.AuxBus = SpatializationProxy.Buses[i];
			ProxyRequest.AttenuationScaling = SpatializationProxy.AttenuationScaling;
			ProxyRequest.bRequiresAuxEmitter = false;

			ProxyRequest.OnProxyRequest.BindUFunction(this, n"ShouldActivateProxyEmitter");
			UHazeAudioMusicManager::RequestAuxSendProxy(ProxyRequest);
			// We did this before to balance out the listener count changes to dB, but with internal soundengine changes
			// this should no longer be a case. Leaving below as is, for now.
			/*

			auto Proxy = UHazeAudioMusicManager::RequestAuxSendProxy(ProxyRequest);
			// If it fails, just bail completely. 
			if (Proxy == nullptr)
				return;

			if (i > 1)
			{
				if (SpatializationProxy.MusicBus != nullptr)
					Proxy.SetNodeProperty(SpatializationProxy.MusicBus, EHazeAudioNodeProperty::BusVolume, -6);

				if (SpatializationProxy.AuxSend != nullptr)
					Proxy.SetNodeProperty(SpatializationProxy.AuxSend, EHazeAudioNodeProperty::BusVolume, -6);  
			}
			*/
		}
	}

	UFUNCTION()
	void StopProxyRequest()
	{
		bPlayingSpatializationProxy = false;
		// Forces the spatialized buses to be muted.
		MusicEmitter.SetRTPC(Rtpc_Sanctuary_Below_Choirs_Volume, 0, 0);
	}

	UFUNCTION(BlueprintEvent)
	bool ShouldActivateProxyEmitter(UObject ProxyOwner, FName EmitterName, float32& InterpolationTime)
	{
		if (bPlayingSpatializationProxy)
			return true;
		
		InterpolationTime = 0;
		// Should always be active.
		return false; 
	}

	UFUNCTION()
	void OnSanctuaryMusicStateChanged()
	{
		// If this happens after StartProxyRequest we should always disable the proxy.
		bPlayingSpatializationProxy = false;
		// Forces the spatialized buses to be muted.
		MusicEmitter.SetRTPC(Rtpc_Sanctuary_Below_Choirs_Volume, 0, 0);
	}
}