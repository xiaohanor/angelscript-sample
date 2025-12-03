UCLASS(Abstract, ClassGroup = "Audio Volume")
class APlayerAudioVolumeBase : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Yellow);
	default BrushComponent.LineThickness = 6.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(EditInstanceOnly, Category = "Asset")
	FHazeSpotSoundAssetData AudioAsset;	

	UPROPERTY(EditInstanceOnly, Category = "Properties", meta = (Units = "times"))
	float AttenuationScaling = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	bool bSetPlayerPanning = false;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	TMap<UHazeAudioRtpc, float> Rtpcs;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	TArray<FHazeAudioNodePropertyParam> NodeProperties;

	UPROPERTY(EditInstanceOnly, Category = "Properties", meta = (EditCondition = "bHasSoundDefAsset", EditConditionHides))
	bool bCanTick = false;

	UPROPERTY(EditInstanceOnly, Category = "Properties")
	bool bTriggerOnce = false;

	UPROPERTY(EditInstanceOnly, Category = "Properties", meta = (ForceUnits = "seconds", EditCondition = "bTriggerOnce == false"))
	float CooldownTime = 0.0;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Properties")
    bool bTriggerForMio = true;

    UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Properties")
    bool bTriggerForZoe = true;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Properties")
	bool bUseSpatialPanning = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Properties", Meta = (EditCondition = "bUseSpatialPanning"))
	EHazePlayer SpatialPanningPlayer = EHazePlayer::Mio;

	private TArray<AHazePlayerCharacter> PlayersInBounds;

	protected float CooldownTimestamp = 0.0;
	protected UHazeAudioEmitter VolumeEmitter = nullptr;

	protected UHazeAudioEvent Event = nullptr;
	protected FSoundDefReference SoundDefRef;

	#if EDITOR
	UPROPERTY(NotVisible, Transient)
	bool bHasSoundDefAsset = false;
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(AudioAsset.GetSoundAsset(Event, SoundDefRef) != EHazeSpotSoundAssetType::None)
		{
			if(CooldownTime > 0)
				CooldownTimestamp = Time::GetGameTimeSeconds();
		}
	}

	// Override this implementation to handle any setup required for the emitter used for this volume
	private void SetupEmitter()	 
	{
		FHazeAudioPoolComponentParams PoolingParams;
		PoolingParams.bReverbEnabled = true;

		UHazeAudioComponent AudioComp = Audio::GetPooledAudioComponent(PoolingParams);

		AudioComp.SetWorldTransform(GetActorTransform());
		VolumeEmitter = AudioComp.GetEmitter(this);	
	}

	private void PostSetupEmitter()
	{
		for(auto& RtpcData : Rtpcs)
		{
			VolumeEmitter.SetRTPC(RtpcData.Key, RtpcData.Value, 0);
		}

		for(auto& NodePropertyData : NodeProperties)
		{
			VolumeEmitter.SetNodeProperty(NodePropertyData.ActorMixer, NodePropertyData.Property, NodePropertyData.Value);
		}

		if(bSetPlayerPanning)
		{
			SetPlayerPanning();
		}

		if (bUseSpatialPanning)
		{
			VolumeEmitter.SetSpatialPanning(SpatialPanningPlayer);
		}
	}

	// Called when a valid player enter has occured
	void PlayOnEnter(AHazePlayerCharacter Player) {}

	// Called when a valid player exit has occured
	void PlayOnExit(AHazePlayerCharacter Player) {}

	protected bool IsCooldownReady()
	{
		if(CooldownTimestamp == 0)
			return true;
		
		if(CooldownTime <= 0)
			return true;

		return Time::GetGameTimeSince(CooldownTimestamp) >= CooldownTime;
	}

	protected void SetPlayerPanning()
	{
		float PanningValue = 0.0;
		
		if(!IsAnyPlayerInside())
			return;

		AHazePlayerCharacter ForPlayer = nullptr;
		if(!IsBothPlayersInside())
		{
			ForPlayer = PlayersInBounds[0];
		}

		if(ForPlayer != nullptr)
		{
			PanningValue = ForPlayer.IsMio() ? -1.0 : 1.0;
		}	
	
		VolumeEmitter.SetRTPC(FHazeAudioID("Rtpc_SpeakerPanning_LR"), PanningValue, 0);			
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return;

		if(!IsEnabledForPlayer(Player))
			return;

		if(VolumeEmitter == nullptr)
		{
			SetupEmitter();
			PostSetupEmitter();
		}

		if(IsCooldownReady())
		{
			if(bSetPlayerPanning)
				SetPlayerPanning();

			PlayOnEnter(Player);
		}		

		CooldownTimestamp = Time::GetGameTimeSeconds();

		if(bTriggerOnce)		
			AddActorDisable(this);
		
	}

	UFUNCTION()
	private void OnPlayerExit(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return;

		if(!IsEnabledForPlayer(Player))
			return;
		
		PlayersInBounds.RemoveSingleSwap(Player);		

		if(IsCooldownReady())
		{			
			if(bSetPlayerPanning)
				SetPlayerPanning();
		
			PlayOnExit(Player);
		}

		if(bTriggerOnce)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

        if (!IsEnabledForPlayer(Player))
            return;

		if(!IsCooldownReady())
			return;

		if(VolumeEmitter == nullptr)
			SetupEmitter();

		if(bSetPlayerPanning)
			SetPlayerPanning();

		PlayOnEnter(Player);	

		CooldownTimestamp = Time::GetGameTimeSeconds();
		PlayersInBounds.Add(Player);

		if(bTriggerOnce)		
			AddActorDisable(this);		
	}

	UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
	
        if (!IsEnabledForPlayer(Player))
            return;

		if(!IsCooldownReady())
			return;

		PlayersInBounds.RemoveSingleSwap(Player);
		PlayOnExit(Player);
	}

	private bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
		{
			if (!bTriggerForMio)
				return false;
		}
		else
		{
			if (!bTriggerForZoe)
				return false;
		}

		return true;
	}

	private bool IsAnyPlayerInside()
	{
		return PlayersInBounds.Num() > 0;
	}

	private bool IsBothPlayersInside()
	{
		return PlayersInBounds.Num() == 2;
	}
}

class UPlayerAudioTriggerBaseDetails : UHazeScriptDetailCustomization
{
	default DetailClass = APlayerAudioVolumeBase;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		if(ObjectsBeingCustomized[0].IsA(APlayerAudioTriggerVolume))
			HideCategory(n"Asset");
	}
}