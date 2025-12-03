class UIslandWalkerHeadHatchButtonMashComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UIslandWalkerHeadHatchButtonMashComponent Other;	
	UHazeCrumbSyncedFloatComponent SyncedProgress;
	bool bStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		
		SyncedProgress = UHazeCrumbSyncedFloatComponent::Create(Player, n"SyncedHatchButtonMashProgress");
		SyncedProgress.OverrideSyncRate(EHazeCrumbSyncRate::High); // Value will only change when high rate is appropriate 
		SyncedProgress.SetValue(0.0);

		Other = UIslandWalkerHeadHatchButtonMashComponent::GetOrCreate(Player.OtherPlayer); 	
	}

	void Start(USceneComponent AttachTo, UIslandWalkerSettings Settings)
	{
		if (bStarted)
			return;
		bStarted = true;
		FButtonMashSettings Params;
		Params.Difficulty = Settings.HatchButtonMashDifficulty;
		Params.Mode = EButtonMashMode::ButtonMash;
		Params.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
		Params.bShowButtonMashWidget = true; 
		Params.WidgetAttachComponent = AttachTo;
		Params.WidgetPositionOffset = Settings.HatchButtonMashOffset;
		Player.StartButtonMash(Params, this);
		Player.SetButtonMashAllowCompletion(this, false);
	}

	void Hide()
	{
		if (!bStarted)
			return;
		bStarted = false;
		Player.StopButtonMash(this);

		if (HasControl())
		{
			SyncedProgress.SetValue(0.0);
			SyncedProgress.SnapRemote();
		}
	}

	void Update()
	{
		if (!bStarted)
			return;

		if (HasControl())
			SyncedProgress.SetValue(Player.GetButtonMashProgress(this));
	}

	bool IsCompleted()
	{
		if (SyncedProgress.Value < 0.99)
			return false;
		if (Other.SyncedProgress.Value < 0.99)
			return false;
		return true;
	}
}
