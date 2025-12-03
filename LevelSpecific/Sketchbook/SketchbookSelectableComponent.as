class USketchbookSelectableComponent : UActorComponent
{
	ASketchbookSelectable Selectable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Selectable = Cast<ASketchbookSelectable>(Owner);
		Selectable.OnSelectionMade.AddUFunction(this, n"OnSelected");
	}

	UFUNCTION()
	void OnSelected()
	{
	}
};