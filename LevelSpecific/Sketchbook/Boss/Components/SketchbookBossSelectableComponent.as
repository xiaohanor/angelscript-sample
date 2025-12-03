class USketchbookBossSelectableComponent : USketchbookSelectableComponent
{
	UPROPERTY(EditInstanceOnly)
	TSubclassOf<ASketchbookBoss> BossChoice;

	UPROPERTY(EditInstanceOnly)
	ASketchbookSentence Text;

	bool bHasBeenSelected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Text.OnFinishedBeingDrawn.AddUFunction(this, n"OnChoiceDrawn");
		SketchbookBoss::GetSketchbookBossFightManager().OnChoicesPresented.AddUFunction(this, n"EnableChoice");
		SketchbookBoss::GetSketchbookBossFightManager().OnBossSelected.AddUFunction(this, n"OnBossSelected");
	}

	UFUNCTION()
	private void OnBossSelected(ESketchbookBossChoice BossType)
	{
		Selectable.DisableChoice();
	}

	UFUNCTION()
	private void OnChoiceDrawn()
	{
		SketchbookBoss::GetSketchbookBossFightManager().ChoiceFinishedDrawing();
	}

	void OnSelected() override
	{
		SketchbookBoss::GetSketchbookBossFightManager().SelectBossChoice(BossChoice, Text);
		bHasBeenSelected = true;
	}

	UFUNCTION()
	void EnableChoice()
	{
		if(bHasBeenSelected)
			return;

		Selectable.EnableChoice();
	}
};