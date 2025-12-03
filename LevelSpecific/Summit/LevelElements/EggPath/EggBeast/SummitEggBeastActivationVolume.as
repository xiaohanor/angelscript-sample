UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers PlayerTrigger", ComponentWrapperClass, Meta = (HighlightPlacement))
class ASummitEggBeastActivationVolume : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.00, 0.00, 0.00));
	default BrushComponent.LineThickness = 5;

	default bTriggerForMio = true;
	default bTriggerForZoe = true;
	default bStartDisabled = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTextRenderComponent EditorTextBillboard;
	default EditorTextBillboard.WorldSize = 46.0;
	default EditorTextBillboard.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
	default EditorTextBillboard.RelativeLocation = FVector(0,0, 100);
	default EditorTextBillboard.TextRenderColor = FColor::Black;
	default EditorTextBillboard.bHiddenInGame = true;
#endif

	bool bHasTriggered = false;

	UPROPERTY(EditAnywhere)
	bool bOnlyTriggerIfBeastInactive = false;

	UPROPERTY(EditAnywhere)
	ESummitEggBeastState ActivationEggBeastState;

	ASummitEggStoneBeast EggBeast;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		#if EDITOR
		EditorTextBillboard.Text = FText::FromString(f"{ActivationEggBeastState :n}");
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		EggBeast = EggPath::GetStoneBeast();
	}

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		if (bOnlyTriggerIfBeastInactive && EggBeast.GetState() != ESummitEggBeastState::None)
			return;

		if (bHasTriggered)
			return;

		bHasTriggered = true;

		Super::TriggerOnPlayerEnter(Player);

		EggPath::ActivateStoneBeastState(ActivationEggBeastState);
	}
};