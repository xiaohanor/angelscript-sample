enum EMonkeyCongaWallIdentifier
{
	Left,
	Right,
	Bottom
}

class ACongaLineWall : AHazeActor
{
	UPROPERTY(EditAnywhere)
	int WallCount = 10;

	UPROPERTY(EditAnywhere)
	float WallSpacing = 400;

	UPROPERTY(EditAnywhere)
	float WallLowerAmount = 1000;

	UPROPERTY(EditInstanceOnly)
	int PreviousStage = 0;

	UPROPERTY(EditInstanceOnly)
	int MonkeysRequiredToUnlock = 0;

	UPROPERTY(EditInstanceOnly)
	EMonkeyCongaWallIdentifier Identifier;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACongaLinePillar> PillarActor;

	UPROPERTY(BlueprintReadWrite)
	TArray<ACongaLinePillar> Walls;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent LowerWallEvent;

	bool bWallLowered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CongaLine::GetManager().OnMonkeyAmountChangedEvent.AddUFunction(this, n"OnMonkeyAmountChanged");
		// CongaLine::GetManager().OnCongaStartedEvent.AddUFunction(this, n"BP_RaiseWall");

		TArray<AActor> ChildWalls;
		GetAttachedActors(ChildWalls);

		for(int i = ChildWalls.Num()-1; i >= 0; i--)
		{
			auto Wall = Cast<ACongaLinePillar>(ChildWalls[i]);
			Walls.Add(Wall);
		}
	}

	UFUNCTION()
	private void OnMonkeyAmountChanged(int TotalMonkeyAmount)
	{
		if(bWallLowered) return;

		int MonkeysAboveThreshold = TotalMonkeyAmount - PreviousStage;
		float Percent = MonkeysAboveThreshold / float(MonkeysRequiredToUnlock);
		int Progress = Math::FloorToInt(Percent * WallCount);

		for(int i = 0; i < WallCount; i++)
		{
			Walls[i].SetActive(Progress > i);
		}

		if(MonkeysAboveThreshold == MonkeysRequiredToUnlock)
		{
			FCongaLowerWallEventParams Params;
			Params.Wall = Identifier;
			UCongaLineManagerEventHandler::Trigger_LowerWall(CongaLine::GetManager(), Params);
			BP_LowerWall();	
			bWallLowered = true;

			for(auto Wall : Walls)
				Wall.ApplyColorOverride(FLinearColor::Black, this, EInstigatePriority::High);

			auto AudioParams = FHazeAudioFireForgetEventParams();
			FVector2D _;
			float PanningValue = 0.0;
			float _Y;
			Audio::GetScreenPositionRelativePanningValue(ActorLocation, _, PanningValue, _Y);

			AudioParams.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID("Rtpc_SpeakerPanning_LR"), PanningValue));
			AudioComponent::PostFireForget(LowerWallEvent, AudioParams);
		}
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_LowerWall(){}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_RaiseWall(){}

#if EDITOR
	UFUNCTION(CallInEditor)
	void RegenerateWall()
	{
		TArray<AActor> ChildWalls;
		GetAttachedActors(ChildWalls);

		for(auto Wall : ChildWalls)
			Wall.DestroyActor();

		for(int i = 0; i < WallCount; i++)
		{
			auto NewWall = SpawnActor(PillarActor, ActorLocation + ActorForwardVector * i * WallSpacing);
			NewWall.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
			NewWall.ParentWall = this;
		}
	}
#endif

};