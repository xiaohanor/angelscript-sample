#if EDITOR
class USketchbookEditorSubsystem : UHazeEditorSubsystem
{
	bool bShowDrawOutlines = false;
	float DrawOutlinesThickness = 2;

	bool bShowAllSentenceLayers = true;
	TMap<int, bool> SentenceLayerMap;

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelPreSave(ULevel Level)
	{
		if(!IsInSketchbookLevel())
			return;

		Sketchbook::Editor::ForceUpdateAllDrawables();
	}

	void OpenEditorWindow()
	{
		if(!IsInSketchbookLevel())
			return;

		Blutility::OpenEditorUtilityWindow("/Script/Blutility.EditorUtilityWidgetBlueprint'/Game/Editor/LevelSpecific/Sketchbook/EWBP_Sketchbook.EWBP_Sketchbook'");
	}

	bool IsInSketchbookLevel() const
	{
		if(!World.IsEditorWorld())
			return false;

		if(World.Name != n"Sketchbook_P")
			return false;

		return true; 
	}
};

namespace Sketchbook::Editor
{
	void OpenToolsWindow()
	{
		USketchbookEditorSubsystem::Get().OpenEditorWindow();
	}

	void RefreshSentenceLayers()
	{
		TArray<AActor> SentenceActors = ::Editor::GetAllEditorWorldActorsOfClass(ASketchbookSentence);

		for(auto SentenceActor : SentenceActors)
		{
			auto Sentence = Cast<ASketchbookSentence>(SentenceActor);
			if(Sentence == nullptr)
				continue;

			if(ShouldShowSentence(Sentence))
			{
				Sentence.Root.SetVisibility(true, true);
			}
			else
			{
				Sentence.Root.SetVisibility(false, true);
			}
		}
	}

	bool ShouldShowSentence(ASketchbookSentence Sentence)
	{
		auto Subsystem = USketchbookEditorSubsystem::Get();
		if(Subsystem == nullptr)
			return true;

		if(Subsystem.bShowAllSentenceLayers)
			return true;

		if(!Subsystem.SentenceLayerMap.Contains(int(Sentence.Layer)))
			return true;

		if(Subsystem.SentenceLayerMap[int(Sentence.Layer)])
			return true;

		return false;
	}
}
#endif