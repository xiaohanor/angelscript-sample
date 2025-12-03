UCLASS(NotBlueprintable)
class AGravityBikeSplineAutoJumpTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIconComp;
	default EditorIconComp.SpriteName = "Target";
	default EditorIconComp.WorldScale3D = FVector(30);
#endif

	UPROPERTY(EditInstanceOnly)
	float Width = 1000;

	FVector GetLeftEdgeLocation() const
	{
		return ActorTransform.TransformPositionNoScale(FVector(0, Width * 0.5, 0));
	}

	FVector GetRightEdgeLocation() const
	{
		return ActorTransform.TransformPositionNoScale(FVector(0, Width * -0.5, 0));
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(
			GetLeftEdgeLocation(),
			GetRightEdgeLocation(),
			FLinearColor::Red,
			30
		);
	}
#endif
};