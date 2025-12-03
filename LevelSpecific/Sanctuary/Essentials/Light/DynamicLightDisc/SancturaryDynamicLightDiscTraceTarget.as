UCLASS(NotBlueprintable)
class ASancturaryDynamicLightDiscTraceTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USancturaryDynamicLightDiscTraceTargetEditorComponent EditorComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};

#if EDITOR
UCLASS(NotBlueprintable)
class USancturaryDynamicLightDiscTraceTargetEditorComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		DrawLocalLine(FVector(0, 0, 100 * WorldScale.Z), FVector(0, 0, -100 * WorldScale.Z), FLinearColor::Yellow, 10 * WorldScale.X);
		DrawLocalLine(FVector::ZeroVector, FVector(100, 0, 0), FLinearColor::Yellow, 10);
	}
}
#endif