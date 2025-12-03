event void FOnMeltdownSeethroughMashUpdate(float MashProgress);

class AMeltdownSeethroughMashInteraction : AThreeShotInteractionActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;
	
	default Interaction.bStartDisabled = true;
	default Interaction.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditAnywhere)
	bool bAutoStartDanger = true;
	UPROPERTY(EditAnywhere)
	float MashDuration = 1.0;
	UPROPERTY(EditAnywhere)
	float InteractionUsableRange = 1500.0;
	UPROPERTY(EditInstanceOnly)
	AMeltdownUnderwaterManager Manager;

	UPROPERTY()
	FOndangerStarted DangerStarted;
	UPROPERTY()
	FOndangerStarted StartedMashing;
	UPROPERTY()
	FOndangerStarted StoppedMashing;
	UPROPERTY()
	FOnMeltdownSeethroughMashUpdate ProgressUpdate;

	bool bIsDangerous = false;
	bool bIsInteracting = false;
	FVector LockLocation;
	float Progress = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");
		Interaction.OnInteractionStopped.AddUFunction(this, n"OnStopInteraction");

		if (bAutoStartDanger)
			StartDanger();
	}

	UFUNCTION(BlueprintPure)
	float GetMashProgressPercentage() const
	{
		return Progress;
	}

	UFUNCTION()
	private void OnStartInteraction(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		bIsInteracting = true;

		FButtonMashSettings ButtonMash;
		ButtonMash.Duration = MashDuration;
		Player.StartButtonMash(ButtonMash, this);

		Player.SetButtonMashAllowCompletion(this, false);

		StartedMashing.Broadcast();
	}

	UFUNCTION()
	private void OnStopInteraction(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		bIsInteracting = false;
		Player.StopButtonMash(this);

		StoppedMashing.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartDanger() {}
	UFUNCTION(BlueprintEvent)
	void BP_StopDanger() {}

	UFUNCTION()
	void StartDanger()
	{
		if (bIsDangerous)
			return;

		Interaction.EnableAfterStartDisabled();
		bIsDangerous = true;
		BP_StartDanger();
		DangerStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsInteracting)
		{
			Progress = Game::Zoe.GetButtonMashProgress(this);
			ProgressUpdate.Broadcast(Progress);
		}
		else
		{
			if (Progress != 0.0)
			{
				Progress = Math::FInterpConstantTo(Progress, 0.0, DeltaSeconds, 0.5);
				ProgressUpdate.Broadcast(Progress);
			}

			LockLocation = Game::Zoe.ActorLocation;
		}

		if (bIsDangerous)
		{
			FVector DisplayPos;
			bool bOnScreen = Manager.ProjectSeethrough_InsideToOutside_LockToPlane(
				ActorLocation, LockLocation, DisplayPos
			);

			if (!bOnScreen || ActorLocation.Distance(Game::Mio.ActorLocation) > InteractionUsableRange)
			{
				Interaction.Disable(n"Offscreen");
				Interaction.KickAnyPlayerOutOfInteraction();
			}
			else
			{
				DisplayPos -= Interaction.WidgetVisualOffset;
				Interaction.Enable(n"Offscreen");
				Interaction.WorldLocation = DisplayPos;
			}
		}
	}
};