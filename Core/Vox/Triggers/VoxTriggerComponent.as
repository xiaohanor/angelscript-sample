
event void FVoxTriggerEvent(AHazeActor Actor);

class UVoxTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	UHazeVoxAsset VoxAsset;

	// If set, this event will be used if Mio is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	UHazeVoxAsset MioVoxAsset;

	// If set, this event will be used if Zoe is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	UHazeVoxAsset ZoeVoxAsset;

	// Who should speak the bark (Mio and Zoe do not need to be added)
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	TArray<AHazeActor> Actors;

	// If > 0 the bark will not trigger until the conditions for this trigger has been true for this many seconds.
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	float TimeInTrigger = 0.0;

	// If true, any delay count down will be reset when the conditions for this trigger becomes false. If false, countdown remains at the value it had when conditions failed.
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	bool bResetDelayOnLeave = true;

	// If true we will repeat bark until disabled, ignoring max trigger count.
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	bool bRepeatForever = false;

	// VO event can be retriggered this many times.
	UPROPERTY(EditAnywhere, Category = "HazeVox", meta = (EditCondition = "!bRepeatForever"))
	int MaxTriggerCount = 1;

	// If > 0 the bark will delay this many seconds before playing
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	float DelayBeforePlaying = 0.0;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	FVoxTriggerEvent OnVoxAssetTriggered;

	private bool bPlayCrumbed = false;
	private float Timer = 0.0;
	private int TriggerCount = 0;
	private AHazeActor TriggeredBy;

	private float PlayingDelayTimer = -1.0;

	void OnStarted(AHazeActor InTriggeredBy, bool bInPlayCrumbed)
	{
		bPlayCrumbed = bInPlayCrumbed;
		TriggeredBy = InTriggeredBy;
		SetComponentTickEnabled(true);
	}

	void OnEnded()
	{
		// Keep alive if trigger delay timer is active
		if (PlayingDelayTimer > 0)
			return;

		if (bResetDelayOnLeave)
			Timer = 0.0;

		if (VoxCVar::HazeVoxAutoResetTriggers.GetInt() != 0)
		{
			Timer = 0.0;
			TriggerCount = 0;
		}

		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayingDelayTimer > 0)
		{
			PlayingDelayTimer -= DeltaTime;
			if (PlayingDelayTimer > 0)
				return;
			
			TriggerVoxAsset();
		}

		if (!bRepeatForever && (TriggerCount >= MaxTriggerCount))
		{
			SetComponentTickEnabled(false);
			return;
		}

		Timer += DeltaTime;

		if (Timer >= TimeInTrigger)
		{
			if (DelayBeforePlaying > 0)
			{
				PlayingDelayTimer = DelayBeforePlaying;
			}
			else
			{
				TriggerVoxAsset();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayVoxAsset(AHazeActor InTriggeredBy)
	{
		TriggeredBy = InTriggeredBy;
		LocalPlayVoxAsset();
	}

	private void LocalPlayVoxAsset()
	{
		UHazeVoxAsset AssetToPlay = VoxAsset;
		if (TriggeredBy == Game::GetMio() && MioVoxAsset != nullptr)
			AssetToPlay = MioVoxAsset;
		if (TriggeredBy == Game::GetZoe() && ZoeVoxAsset != nullptr)
			AssetToPlay = ZoeVoxAsset;

		HazePlayVox(AssetToPlay, Actors);
		OnVoxAssetTriggered.Broadcast(TriggeredBy);
	}

	private void TriggerVoxAsset()
	{
		TriggerCount++;
		Timer = 0.0;

		if (bPlayCrumbed)
		{
			CrumbPlayVoxAsset(TriggeredBy);
		}
		else
		{
			LocalPlayVoxAsset();
		}

		if (!bRepeatForever && (TriggerCount >= MaxTriggerCount))
			SetComponentTickEnabled(false);
	}
}
