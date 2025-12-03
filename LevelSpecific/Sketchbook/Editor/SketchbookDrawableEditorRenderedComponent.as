#if EDITOR
class USketchbookDrawableEditorRenderedComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		MarkRenderStateDirty();
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		auto EditorSubsystem = USketchbookEditorSubsystem::Get();
		if(!EditorSubsystem.bShowDrawOutlines)
			return;

		auto Drawable = USketchbookDrawableComponent::Get(Owner);
		if(Drawable == nullptr)
			return;

		SetActorHitProxy();

		FLinearColor Color = Drawable.bDrawnFromStart ? FLinearColor(0.04, 0.31, 0.04) : FLinearColor(0.31, 0.04, 0.04);

		FVector Origin, Extents;
		Drawable.CalculateEditorBounds(Origin, Extents);
		DrawWireBox(Origin, Extents, FQuat::Identity, Color, EditorSubsystem.DrawOutlinesThickness);
	}
}
#endif