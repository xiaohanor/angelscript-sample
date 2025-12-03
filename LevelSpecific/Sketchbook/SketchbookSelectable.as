event void FSketchbookOnSelectionMade();

enum ESketchbookSelectableProgressState
{
	Empty,
	FillingUp,
	Full,
	DrainingDown,
};

UCLASS(Abstract)
class ASketchbookSelectable : AHazeActor
{
	access Internal = private, USketchbookSelectableComponent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Volume;

	UPROPERTY(DefaultComponent)
	USceneComponent WidgetOffset;

	UPROPERTY(DefaultComponent, Attach = WidgetOffset)
	USketchbookLanguageOffsetComponent LanguageOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = LanguageOffsetComponent)
	UStaticMeshComponent Circle;

	UPROPERTY(EditAnywhere)
	FLinearColor CircleColor;

	UMaterialInstanceDynamic MaterialInstance;

	access:Internal
	FSketchbookOnSelectionMade OnSelectionMade;

	TPerPlayer<bool> InVolume;
	TPerPlayer<float> Progress;
	TPerPlayer<ESketchbookSelectableProgressState> ProgressState;

	bool bCanSelect = false;

	bool bSelected = false;

	UPROPERTY(EditAnywhere)
	float SelectionDuration = 2;

	UPROPERTY(EditAnywhere)
	float DeselectionDuration = 0.5;

	float Opacity = 1;

	UPROPERTY(EditAnywhere)
	const float FadeOutDuration = 0.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Volume.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		Volume.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		MaterialInstance = Circle.CreateDynamicMaterialInstance(0, Circle.GetMaterial(0));
		MaterialInstance.SetScalarParameterValue(n"PercentMio", 0);
		MaterialInstance.SetScalarParameterValue(n"PercentZoe", 0);
		MaterialInstance.SetVectorParameterValue(n"CircleColor", CircleColor);
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		InVolume[Player] = true;
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		InVolume[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSelected || !bCanSelect)
		{
			if(Opacity > 0)
			{
				Opacity -= 1 / FadeOutDuration * DeltaSeconds;
				Opacity = Math::Saturate(Opacity);
				MaterialInstance.SetScalarParameterValue(n"Opacity", Opacity);
			}

			return;
		}

		bool bBothPlayersDone = true;

		for(auto Player : Game::Players)
		{
			const float RemoteSpeedMultiplier = 1;

			if(InVolume[Player])
			{
				if(Progress[Player] < 1)
				{
					FHazeFrameForceFeedback FF;
					FF.RightMotor = Progress[Player];
					Player.SetFrameForceFeedback(FF, 0.05);
				}

				float Multiplier = Player.HasControl() ? 1 : RemoteSpeedMultiplier;
				Progress[Player] += 1 / SelectionDuration * DeltaSeconds * Multiplier;

				if(Progress[Player] > 1.0 - KINDA_SMALL_NUMBER)
				{
					SetProgressState(Player, ESketchbookSelectableProgressState::Full);
				}
				else
				{
					SetProgressState(Player, ESketchbookSelectableProgressState::FillingUp);
				}
			}
			else
			{
				Progress[Player] -= 1 / DeselectionDuration * DeltaSeconds;

				if(Progress[Player] < KINDA_SMALL_NUMBER)
				{
					SetProgressState(Player, ESketchbookSelectableProgressState::Empty);
				}
				else
				{
					SetProgressState(Player, ESketchbookSelectableProgressState::DrainingDown);
				}
			}

			Progress[Player] = Math::Saturate(Progress[Player]);
			FName ParamName = Player.IsMio() ? n"PercentMio" : n"PercentZoe";
			MaterialInstance.SetScalarParameterValue(ParamName, Progress[Player]);

			if(Progress[Player] < 1)
				bBothPlayersDone = false;
		}

		MaterialInstance.SetScalarParameterValue(n"Opacity", Opacity);

		if(bBothPlayersDone && HasControl())
			CrumbSelectionFinished();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSelectionFinished()
	{
		bCanSelect = false;
		bSelected = true;
		OnSelectionMade.Broadcast();

		for(auto Player : Game::Players)
		{
			SetProgressState(Player, ESketchbookSelectableProgressState::Full);
			Player.PlayForceFeedback(ForceFeedback::Default_Light, this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void EnableChoice()
	{
		bCanSelect = true;
		Opacity = 1;
	}

	UFUNCTION(BlueprintCallable)
	void DisableChoice()
	{
		bCanSelect = false;

		// Reset so any, audio for example, gets a chance to respond to the choices being removed.
		for(auto Player : Game::Players)
		{
			SetProgressState(Player, ESketchbookSelectableProgressState::Empty);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Circle.SetColorParameterValueOnMaterials(n"CircleColor", CircleColor);
	}
#endif

	void SetProgressState(AHazePlayerCharacter Player, ESketchbookSelectableProgressState NewState)
	{
		const ESketchbookSelectableProgressState CurrentState = ProgressState[Player];

		if(CurrentState == NewState)
			return;

		switch(CurrentState)
		{
			case ESketchbookSelectableProgressState::Empty:
				break;

			case ESketchbookSelectableProgressState::FillingUp:
			{
				FSketchbookSelectableOnStopFillingUpEventData EventData;
				EventData.bIsMio = Player.IsMio();
				EventData.bFinished = NewState == ESketchbookSelectableProgressState::Full;
				//Print(f"Trigger_OnStopFillingUp: {EventData.bFinished=}");
				USketchbookSelectableEventHandler::Trigger_OnStopFillingUp(this, EventData);
				break;
			}

			case ESketchbookSelectableProgressState::Full:
				break;

			case ESketchbookSelectableProgressState::DrainingDown:
			{
				FSketchbookSelectableOnStopDrainingDownEventData EventData;
				EventData.bIsMio = Player.IsMio();
				EventData.bFinished = NewState == ESketchbookSelectableProgressState::Empty;
				//Print(f"Trigger_OnStopDrainingDown: {EventData.bFinished=}");
				USketchbookSelectableEventHandler::Trigger_OnStopDrainingDown(this, EventData);
				break;
			}

		}

		switch(NewState)
		{
			case ESketchbookSelectableProgressState::Empty:
				break;

			case ESketchbookSelectableProgressState::FillingUp:
			{
				//Print("Trigger_OnStartFillingUp");
				FSketchbookSelectableOnStartFillingUpEventData EventData;
				EventData.bIsMio = Player.IsMio();
				USketchbookSelectableEventHandler::Trigger_OnStartFillingUp(this, EventData);
				break;
			}

			case ESketchbookSelectableProgressState::Full:
				break;

			case ESketchbookSelectableProgressState::DrainingDown:
			{
				//Print("Trigger_OnStartDrainingDown");
				FSketchbookSelectableOnStartDrainingDownEventData EventData;
				EventData.bIsMio = Player.IsMio();
				USketchbookSelectableEventHandler::Trigger_OnStartDrainingDown(this, EventData);
				break;
			}
		}

		ProgressState[Player] = NewState;
	}
};