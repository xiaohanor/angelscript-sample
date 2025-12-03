
enum EBothPlayerCameraVolumeOutsideType
{
	WhenOneExit,
	WhenBothExit,
	WhenMioExit,
	WhenZoeExit
}

class ABothPlayerCameraVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.0, 1.0, 0.4, 1.0));
	default BrushComponent.SetCollisionProfileName(n"Trigger");
	default PrimaryActorTick.bStartWithTickEnabled = false;

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCameraSettingsComponent CameraSettings;
	default CameraSettings.bBothPlayersMustMeetConditions = true;

	// When do we count as outside the volume
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Conditions", AdvancedDisplay)
	EBothPlayerCameraVolumeOutsideType OutSideCondition = EBothPlayerCameraVolumeOutsideType::WhenOneExit;
	
	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bTriggerLocally = false;

    UPROPERTY(Category = "Both Player Trigger")
    FBothPlayerTriggerEvent OnBothPlayersInside;

    UPROPERTY(Category = "Both Player Trigger")
    FBothPlayerTriggerEvent OnStopBothPlayersInside;

	// Broadcast for each player when both players are inside and any other conditoins are met
	UPROPERTY()
	FHazeCameraSettingsApplied OnVolumeActivated;

	// Broadcast for each player when any player left volume or conditions stopped being met
	UPROPERTY()
	FHazeCameraSettingsCleared OnVolumeDeactivated;

	// Broadcast for each player when both players have entered volume, before applying any settings, activating camera etc.
	UPROPERTY()
	FHazeCameraVolumeEntered OnBothPreEntered;

	// Broadcast for each player when both players have entered volume, after any camera or settings have had a chance to be applied 
	UPROPERTY()
	FHazeCameraVolumeEntered OnBothEntered;

	// This is broadcast (for each player) when any player exits the volume when both where inside previously.
	UPROPERTY()
	FHazeCameraVolumeExited OnOneExited;

	private TPerPlayer<UHazeCameraUserComponent> Users;
	private TArray<FInstigator> DisableInstigators;
	private TPerPlayer<bool> PlayersInsideTrigger;
	private bool bBothPlayersInside = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnBothPlayersInside.AddUFunction(this, n"OnBothInside");
		OnStopBothPlayersInside.AddUFunction(this, n"OnStopBothInside");
		CameraSettings.OnSettingsApplied.AddUFunction(this, n"OnSettingsApplied");
		CameraSettings.OnSettingsCleared.AddUFunction(this, n"OnSettingsCleared");

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Users[Player] = UHazeCameraUserComponent::Get(Player);
		}
	}

	UFUNCTION(Category = "Both Player Trigger")
    void EnableBothPlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Both Player Trigger")
    void DisableBothPlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(NotBlueprintCallable)
	private void OnBothInside()
	{
		if (CameraSettings.ShouldUpdate())
			SetActorTickEnabled(true);

		for (UHazeCameraUserComponent User : Users)
		{
			OnBothPreEntered.Broadcast(User);
			CameraSettings.Apply(User);
			OnBothEntered.Broadcast(User);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnStopBothInside()
	{
		for (UHazeCameraUserComponent User : Users)
		{
			CameraSettings.Clear(User);
			OnOneExited.Broadcast(User);
		}

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Will only ever be ticking if settings conditions require this and both players are inside
		for (UHazeCameraUserComponent User : Users)
		{
			CameraSettings.Update(User);
		}
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnSettingsApplied(UHazeCameraUserComponent User)
    {
		OnVolumeActivated.Broadcast(User);
    }

    UFUNCTION(NotBlueprintCallable)
    private void OnSettingsCleared(UHazeCameraUserComponent User)
    {
		OnVolumeDeactivated.Broadcast(User);
    }

	// Manually update which players are inside, we may have missed overlap events due to disable or streaming
	private void UpdateAlreadyInsidePlayers()
	{
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

		for (auto Player : Game::Players)
		{
			bool bIsInside = false;
			if (DisableInstigators.Num() == 0)
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			PlayersInsideTrigger[Player] = bIsInside;
		}

		if (PlayersInsideTrigger[0] && PlayersInsideTrigger[1])
		{
			if (!bBothPlayersInside)
			{
				bBothPlayersInside = true;
				if (bTriggerLocally)
					OnBothPlayersInside.Broadcast();
				else
					CrumbBothPlayersInside();
			}
		}
		else if (CanTriggerOutside())
		{
			bBothPlayersInside = false;
			if (bTriggerLocally)
				OnStopBothPlayersInside.Broadcast();
			else
				CrumbStopBothPlayersInside();
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (DisableInstigators.Num() != 0)
            return;

		PlayersInsideTrigger[Player] = true;
		if (!bBothPlayersInside && PlayersInsideTrigger[0] && PlayersInsideTrigger[1])
		{
			bBothPlayersInside = true;
			if (bTriggerLocally)
				OnBothPlayersInside.Broadcast();
			else
				CrumbBothPlayersInside();
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (DisableInstigators.Num() != 0)
            return;

		PlayersInsideTrigger[Player] = false;
		if (CanTriggerOutside())
		{
			bBothPlayersInside = false;
			if (bTriggerLocally)
				OnStopBothPlayersInside.Broadcast();
			else
				CrumbStopBothPlayersInside();
		}
	}

	private bool CanTriggerOutside() const
	{
		if(!bBothPlayersInside)
			return false;

		if(OutSideCondition == EBothPlayerCameraVolumeOutsideType::WhenOneExit)
		{
			if(!PlayersInsideTrigger[0] || !PlayersInsideTrigger[1])
				return true;
		}

		if(OutSideCondition == EBothPlayerCameraVolumeOutsideType::WhenBothExit)
		{
			if(!PlayersInsideTrigger[0] && !PlayersInsideTrigger[1])
				return true;
		}

		if(OutSideCondition == EBothPlayerCameraVolumeOutsideType::WhenMioExit)
		{
			if(!PlayersInsideTrigger[Game::GetMio()])
				return true;
		}

		if(OutSideCondition == EBothPlayerCameraVolumeOutsideType::WhenZoeExit)
		{
			if(!PlayersInsideTrigger[Game::GetZoe()])
				return true;
		}

		return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBothPlayersInside()
	{
		OnBothPlayersInside.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopBothPlayersInside()
	{
		OnStopBothPlayersInside.Broadcast();
	}
}
