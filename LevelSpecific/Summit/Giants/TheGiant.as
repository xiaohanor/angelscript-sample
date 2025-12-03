event void FTheGiantOnPlayerStartSwing(AHazePlayerCharacter Player);

class ATheGiant : AHazeSkeletalMeshActor
{
	default Mesh.bUseShadowProxyMesh = true;
	default Mesh.ShadowProxyMinimumLOD = 3;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;
	private TMap<int, UHazeAudioComponent> PooledAnimationAudioComps;

#if EDITOR
	access PrivateWithDebugAudioNotify = private, UAnimNotify_GiantsAudio, UGiantsAnimationAudioDebugCapability;
	access:PrivateWithDebugAudioNotify
	TMap<FName, FName> AnimNotifyToEventDebugMap;
	
	private TMap<int, FName> PlayingIDToEventName;	

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent DebugCapabilityComponent;
	default DebugCapabilityComponent.DefaultCapabilities.Add(n"GiantsAnimationAudioDebugCapability");

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;
#endif

	UPROPERTY(EditAnywhere)
	bool bEnablePhysics = true;

	UPROPERTY(EditAnywhere)
	bool bLetAnimationPlayFromStart = false;

	default Mesh.SetCollisionProfileName(n"BlockAll");
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

	access PrivateWithAudioAnimNotify = private, UAnimNotify_GiantsAudio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!bLetAnimationPlayFromStart)
			Mesh.StopAllSlotAnimations();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	access:PrivateWithAudioAnimNotify 
	void PlayAudioOnSocket(UHazeAudioEvent Event, const float AttenuationScaling, const FName BoneName = NAME_None)
	{
		if(Event == nullptr)
			return;

		FHazeAudioPoolComponentParams Params;
		Params.bReverbEnabled = true;

		auto AudioComp = Audio::GetPooledAudioComponent(Params);		
		AudioComp.GetDistanceToTarget(EHazeAudioDistanceTrackingTarget::Listener, bAutoSetRtpc = true);

		auto Emitter = AudioComp.GetEmitter(this, FName(f"{GetName()} AnimNotifyEmitter"));
		
		AudioComp.AttachToComponent(Mesh, BoneName);

		//auto Emitter = AudioComp.GetEmitter(this, FName(f"{GetName()} AnimNotifyEmitter"));
		//Emitter.SetAttenuationScaling(AttenuationScaling);

		if(Event.MaxAttenuationRadius > 0)
			Emitter.SetAttenuationScaling(AttenuationScaling);
		else
			Emitter.SetAttenuationRadiusOverride(AttenuationScaling);

		FOnHazeAudioPostEventCallback Callback;
		Callback.BindUFunction(this, n"OnEventCallback");

		int PlayingID = Emitter.PostEvent(Event, Callback).PlayingID;
		PooledAnimationAudioComps.Add(PlayingID, AudioComp);

		#if EDITOR
		PlayingIDToEventName.Add(PlayingID, Event.GetName());
		#endif
	}

	UFUNCTION()
	void OnEventCallback(EAkCallbackType CallbackType, UHazeAudioCallbackInfo CallbackInfo)
	{
		if(CallbackType == EAkCallbackType::EndOfEvent)
		{
			auto EventCallbackInfo = Cast<UHazeAudioEventCallbackInfo>(CallbackInfo);
			UHazeAudioComponent PooledAudioComp;
			if(PooledAnimationAudioComps.Find(EventCallbackInfo.PlayingID, PooledAudioComp))
			{
				Audio::ReturnPooledAudioComponent((PooledAudioComp));
			}

			#if EDITOR
			FName EventName = NAME_None;
			if(PlayingIDToEventName.Find(EventCallbackInfo.PlayingID, EventName))
			{
				AnimNotifyToEventDebugMap.Remove(EventName);
			}
			#endif
		}
	}
}