UCLASS(Abstract)
class ATundra_River_TotemPuzzle_DisplayHeads : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UStaticMeshComponent SecondHeadComp;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UNiagaraComponent LeftEyeActivationComp;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UNiagaraComponent RightEyeActivationComp;

	UPROPERTY(EditInstanceOnly)
	ETundraTotemIndex TotemIndex = ETundraTotemIndex::NONE;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_TotemPuzzle_TreeControl TreeControl;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_Activate;

	ATundra_River_TotemPuzzle Totem;

	UPROPERTY()
	float TargetRotation = 0;

	bool bPuzzleSolved = false;
	bool bHeadActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TreeControl.TotemChangedPosition.AddUFunction(this, n"OnTotemChangedPosition");
		TreeControl.PuzzleIsSolved.AddUFunction(this, n"OnPuzzleSolved");

		Totem = TreeControl.ListOfTotems[TotemIndex];
		Totem.FirstPuzzleSolved.AddUFunction(this, n"OnFirstPuzzleSolved");
		Totem.OnCorrectTotemLocked.AddUFunction(this, n"OnCorrectTotemLocked");

		TL_Activate.BindUpdate(this, n"TL_Activate_Update");
	}

	UFUNCTION()
	private void TL_Activate_Update(float CurrentValue)
	{
		RotateRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(0, 20, CurrentValue));
	}

	UFUNCTION()
	private void OnFirstPuzzleSolved()
	{
		TargetRotation = 180;
		DeactivateHead();
	}

	UFUNCTION()
	private void OnCorrectTotemLocked()
	{
		ActivateHead();
	}

	UFUNCTION()
	private void OnPuzzleSolved()
	{
		bPuzzleSolved = true;
		UTundra_River_TotemPuzzle_DisplayHeads_EffectHandler::Trigger_PuzzleSolved(this);
	}

	UFUNCTION()
	private void OnTotemChangedPosition(ETundraTotemIndex Index, bool bCorrectPosition)
	{
		if(Index != TotemIndex || bPuzzleSolved)
			return;

		if(bCorrectPosition)
		{
			// ActivateHead();
		}
		else
		{
			if(bHeadActive)
				DeactivateHead();
		}
	}

	UFUNCTION()
	void ActivateHead()
	{
		bHeadActive = true;
		TL_Activate.SetPlayRate(1.0 / 0.15);
		TL_Activate.PlayFromStart();
		LeftEyeActivationComp.Activate(true);
		RightEyeActivationComp.Activate(true);
		UTundra_River_TotemPuzzle_DisplayHeads_EffectHandler::Trigger_HeadActivated(this);
	}

	UFUNCTION()
	void DeactivateHead()
	{
		bHeadActive = false;
		LeftEyeActivationComp.Deactivate();
		RightEyeActivationComp.Deactivate();
		UTundra_River_TotemPuzzle_DisplayHeads_EffectHandler::Trigger_HeadDeactivated(this);
	}
};
