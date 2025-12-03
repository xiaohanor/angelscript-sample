
#if EDITOR
class UHazeWorldLinkComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHazeWorldLinkComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UHazeWorldLinkComponent Comp = Cast<UHazeWorldLinkComponent>(Component);

		if (!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		if (Comp.LinkedActor.IsValid())
		{
			DrawLine(Comp.Owner.ActorLocation, 
				Comp.LinkedActor.Get().ActorLocation, 
				FLinearColor::Yellow, 
				3.0);
		}
	}
} 
#endif

class AHazeWorldLinkSyncedPosition : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeEditorWorldLinkPositionComponent PositionComponent;
	default PositionComponent.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeWorldLinkComponent WorldLinkComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		PositionComponent.OnActorModifiedInEditor();
	}
#endif
}