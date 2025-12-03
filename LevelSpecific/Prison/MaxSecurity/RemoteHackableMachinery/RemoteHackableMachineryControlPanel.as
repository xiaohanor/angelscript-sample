event void FRemoteHackableMachineryControlPanelUpdateEvent(float Alpha);
event void FRemoteHackableMachineryControlPanelFinishEvent();

UCLASS(Abstract)
class ARemoteHackableMachineryControlPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ControlPanelRoot;

	UPROPERTY(DefaultComponent, Attach = ControlPanelRoot)
	URemoteHackingResponseComponent HackingComp;
	
	UPROPERTY(DefaultComponent)
	URemoteHackingResponseAudioComponent HackingAudioComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(URemoteHackableMachineryControlPanelCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedInput;
	default SyncedInput.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlphaComp;
	default SyncedAlphaComp.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY()
	FRemoteHackingEvent OnHackStarted;

	UPROPERTY()
	FRemoteHackingEvent OnHackStopped;

	UPROPERTY()
	FRemoteHackableMachineryControlPanelUpdateEvent OnUpdated;

#if EDITOR
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewAlpha = 0.0;
#endif

	float PreviousAlpha = 0.0;
	float TargetAlpha = 0.0;

	UPROPERTY(VisibleInstanceOnly)
	private TArray<ARemoteHackableMachineryCell> Cells;

	float PlayerInput = 0.0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		auto Actors = Editor::GetAllEditorWorldActorsOfClass(ARemoteHackableMachineryCell);
		Cells.Reset();
		for(auto Actor : Actors)
		{
			auto Cell = Cast<ARemoteHackableMachineryCell>(Actor);
			if(Cell != nullptr)
				Cells.Add(Cell);
		}

		for (auto Cell : Cells)
		{
			Cell.PreviewAlpha = PreviewAlpha;
			Cell.UpdatePreviewAlphaAndLoc(PreviewAlpha);
		}
	}
#endif
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		// Sync input from Mio
		SyncedInput.OverrideControlSide(Game::Mio);

		// Sync alpha from Zoe
		SyncedAlphaComp.OverrideControlSide(Game::Zoe);

		HackingComp.OnHackingStarted.AddUFunction(this, n"HackingStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackStopped");
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted()
	{
		OnHackStarted.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackStopped()
	{
		OnHackStopped.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PreviousAlpha = SyncedAlphaComp.Value;

		if(SyncedInput.HasControl())
			TickInput(DeltaTime);

		if(SyncedAlphaComp.HasControl())
			TickAlpha(DeltaTime);

		const float CurrentAlpha = SyncedAlphaComp.Value;
		if (!Math::IsNearlyEqual(CurrentAlpha, TargetAlpha))
			OnUpdated.Broadcast(CurrentAlpha);
	}

	private void TickInput(float DeltaTime)
	{
		check(Game::Mio.HasControl() && SyncedInput.HasControl());

		// Sync input from Mio to Zoe side
		SyncedInput.SetValue(PlayerInput);

		// Alpha will be automatically synced with SyncedAlphaComp
	}

	private void TickAlpha(float DeltaTime)
	{
		check(Game::Zoe.HasControl() && SyncedAlphaComp.HasControl());

		// Get the latest synced input
		float InputCrumbTime;
		SyncedInput.GetLatestAvailableData(PlayerInput, InputCrumbTime);

		// Calculate the new alpha
		TargetAlpha = Math::Clamp(TargetAlpha + (PlayerInput * 0.25 * DeltaTime), 0.0, 1.0);
		const float CurrentAlpha = Math::FInterpTo(SyncedAlphaComp.Value, TargetAlpha, DeltaTime, 5.0);

		// Set the synced alpha from Mio
		SyncedAlphaComp.SetValue(CurrentAlpha);
	}

	void UpdatePlayerInput(float Input)
	{
		PlayerInput = Input;
	}
}

class URemoteHackableMachineryControlPanelCapability : URemoteHackableBaseCapability
{
	ARemoteHackableMachineryControlPanel ControlPanel;
	UOtherPlayerIndicatorComponent IndicatorComp;

	float CurrentAlpha = 0.0;

	float TimeSpentMoving = 0.0;
	bool bTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		ControlPanel = Cast<ARemoteHackableMachineryControlPanel>(Owner);
		IndicatorComp = UOtherPlayerIndicatorComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		IndicatorComp.IndicatorMode.Apply(EOtherPlayerIndicatorMode::AlwaysVisible, this);

		if (!bTutorialCompleted)
		{
			UTutorialComponent::Get(Player).TutorialScreenSpaceOffset.Apply(-180.0, this);

			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
			Player.ShowTutorialPrompt(TutorialPrompt, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		IndicatorComp.IndicatorMode.Clear(this);

		UTutorialComponent::Get(Player).TutorialScreenSpaceOffset.Clear(this);

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		float Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw).Y;
		ControlPanel.UpdatePlayerInput(Input);

		if (Input != 0.0 && ControlPanel.SyncedAlphaComp.Value != 0.0 && ControlPanel.SyncedAlphaComp.Value != 1.0)
		{
			if (!bTutorialCompleted)
			{
				TimeSpentMoving += DeltaTime;
				if (TimeSpentMoving >= 5.0)
				{
					bTutorialCompleted = true;
					Player.RemoveTutorialPromptByInstigator(this);
				}
			}

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.2;
			FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.2;
			Player.SetFrameForceFeedback(FF);
		}
	}
}