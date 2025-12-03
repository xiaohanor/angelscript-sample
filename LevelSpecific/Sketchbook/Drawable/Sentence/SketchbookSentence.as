event void FSketchbookDrawableSentenceStartBeingDrawn();
event void FSketchbookDrawableSentenceFinishBeingDrawn();

event void FSketchbookDrawableSentenceStartBeingErased();
event void FSketchbookDrawableSentenceFinishBeingErased();

UCLASS(Abstract, HideCategories = "Rendering Debug Cooking Actor")
class ASketchbookSentence : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UTextRenderComponent TextRenderer;
	default TextRenderer.HorizontalAlignment = EHorizTextAligment::EHTA_Left;
	default TextRenderer.bHazeForceDisableLoc = false;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USketchbookDrawableSentenceComponent DrawableSentenceComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USketchbookDrawableEditorRenderedComponent EditorRenderedComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Text")
	FLinearColor TextColor = FLinearColor(1, 0, 0);

	UPROPERTY(EditAnywhere, Category = "Text")
	float TextWorldSize = 75.0;

	UPROPERTY(EditDefaultsOnly, Category = "Text")
	UMaterialInterface TextMaterial;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Text")
	ESketchbookSentenceLayer Layer = ESketchbookSentenceLayer::Default;

	UPROPERTY(EditInstanceOnly = "TEXT")
	bool bUseDarkCaveColor = false;
#endif

	UPROPERTY(EditInstanceOnly, Category = "VOX")
	UHazeVoxAsset VoxAsset;

	UPROPERTY(EditInstanceOnly, Category = "VOX")
	float VoxAssetDuration = -1;
	
	UPROPERTY(BlueprintReadOnly, Category = "Drawable Sentence")
	FSketchbookDrawableSentenceStartBeingDrawn OnStartBeingDrawn;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Sentence")
	FSketchbookDrawableSentenceFinishBeingDrawn OnFinishedBeingDrawn;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Sentence")
	FSketchbookDrawableSentenceStartBeingErased OnStartBeingErased;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Sentence")
	FSketchbookDrawableSentenceFinishBeingErased OnFinishedBeingErased;

#if EDITOR
	private ESketchbookSentenceLayer PreviousLayer;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		TextRenderer.SetWorldSize(TextWorldSize);
		TextRenderer.TextRenderColor = TextColor.ToFColor(true);

		if(Layer >= ESketchbookSentenceLayer::MAX)
			Layer = ESketchbookSentenceLayer::Default;

		if(PreviousLayer != Layer)
			Sketchbook::Editor::RefreshSentenceLayers();

		PreviousLayer = Layer;

		if(VoxAssetDuration < 0 && VoxAsset != nullptr)
		{
			CalculateVoxDuration();
		}

		if (bUseDarkCaveColor)
		{
			TextRenderer.SetRenderCustomDepth(true);
			TextRenderer.TextRenderColor = FLinearColor(0.930209, 0.799866, 0.702246).ToFColor(true);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.SetVisibility(true, true);
		DrawableSentenceComp.OnStartBeingDrawn.AddUFunction(this, n"StartBeingDrawn");
		DrawableSentenceComp.OnFinishedBeingDrawn.BindUFunction(this, n"FinishedBeingDrawn");

		DrawableSentenceComp.OnStartBeingErased.BindUFunction(this, n"StartBeingErased");
		DrawableSentenceComp.OnFinishedBeingErased.BindUFunction(this, n"FinishedBeingErased");

		if(VoxAssetDuration < 0 && VoxAsset != nullptr)
		{
			CalculateVoxDuration();
		}
	}

	UFUNCTION()
	private void StartBeingDrawn()
	{
		OnStartBeingDrawn.Broadcast();
	}

	UFUNCTION()
	private void FinishedBeingDrawn()
	{
		OnFinishedBeingDrawn.Broadcast();
	}

	UFUNCTION()
	private void StartBeingErased()
	{
		OnStartBeingErased.Broadcast();
	}

	UFUNCTION()
	private void FinishedBeingErased()
	{
		OnFinishedBeingErased.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void DrawSentence()
	{
		DrawableSentenceComp.RequestDraw();
	}

	UFUNCTION(BlueprintCallable)
	void EraseSentence()
	{
		DrawableSentenceComp.RequestErase();
	}

	/**
	 * Iterate through all audio events of all voice lines on the assigned vox asset, and sum up their MaxDuration
	 */
	UFUNCTION(CallInEditor, Category = "Vox")
	void CalculateVoxDuration()
	{
		if(VoxAsset == nullptr)
			return;

		VoxAssetDuration = 0;
		for(auto VoiceLine : VoxAsset.VoiceLines)
		{
			if(VoiceLine.AudioEvent == nullptr)
				continue;

			VoxAssetDuration += VoiceLine.AudioEvent.MaximumDuration;
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Drawable Sentence")
	private void MakeAllSentencesStatic()
	{
		Editor::BeginTransaction("MakeAllSentencesStatic");

		TArray<ASketchbookSentence> Actors = Editor::GetAllEditorWorldActorsOfClass(ASketchbookSentence);
		for(auto Actor : Actors)
		{
			auto SentenceActor = Cast<ASketchbookSentence>(Actor);
			if(SentenceActor == nullptr)
				continue;

			SentenceActor.Modify();

			TArray<USceneComponent> SceneComponents;
			SentenceActor.GetComponentsByClass(SceneComponents);

			for(auto SceneComponent : SceneComponents)
				SceneComponent.SetMobility(EComponentMobility::Static);
		}

		Editor::EndTransaction();
	}

	UFUNCTION(CallInEditor, Category = "Vox")
	private void ReCalculateAllVoxDuration()
	{
		EAppReturnType ReturnType = Editor::MessageDialog(EAppMsgType::YesNo, FText::FromString("This will replace all the VoxDurations on all sentences. Don't be stupid Zach, think about it for a sec. Just take a lil break, and think for a while. Think think. Think thonk? No, just think think. Think of the children. And of the world. And the entropy of the universe. Ok, now you are ready, it is up to you to decide, Zach. Recalculate all VoxDurations?"));

		if(ReturnType == EAppReturnType::No || ReturnType == EAppReturnType::Cancel)
		{
			Editor::MessageDialog(EAppMsgType::Ok, FText::FromString("Well have lots of fun entering all of the vox durations manually then, jerk."));
			return;
		}

		ReturnType = Editor::MessageDialog(EAppMsgType::YesNo, FText::FromString("No actually, I don't think you were quite ready yet Zach. Instead of sitting down you should go to the relax room, lie down and rest for a while. Let your mind wander, and follow where it leads. Who are you? What is it you want? Is your brother actually dead or was that just a poorly timed joke? Who knows really. After many lifetimes spent wandering the ethereal infinity, time has simply become a concept. Space has been forgotten and all that exists is your consciousness. Nothing is, and nothing was. Recalculate all VoxDurations?"));

		if(ReturnType == EAppReturnType::No || ReturnType == EAppReturnType::Cancel)
		{
			Editor::MessageDialog(EAppMsgType::Ok, FText::FromString("Oh really? You actually decided to press no on the second message box? Wow, I didn't expect that. Well darn, you just keep surprising me."));
			return;
		}

		if(VoxAsset == nullptr)
			return;

		TArray<ASketchbookSentence> Actors = Editor::GetAllEditorWorldActorsOfClass(ASketchbookSentence);
		for(auto Actor : Actors)
		{
			auto Sentence = Cast<ASketchbookSentence>(Actor);
			if(Sentence == nullptr)
				continue;

			Sentence.CalculateVoxDuration();
		}
	}
#endif
};
