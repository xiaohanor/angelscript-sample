event void FCyclopsOnAnswerSelectedEvent(USketchbookCyclopsRiddleSelectableComponent Answer);

class USketchbookCyclopsRiddleSelectableComponent : USketchbookSelectableComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bIsCorrectAnswer;

	UPROPERTY(EditInstanceOnly)
	ASketchbookSentence Text;

	FCyclopsOnAnswerSelectedEvent OnAnswerSelected;

	void OnSelected() override
	{
		OnAnswerSelected.Broadcast(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		if(Text != nullptr)
			Owner.SetActorLabel(f"Selectable \"{Text.TextRenderer.Text.ToString()}\"");
	}
#endif
};