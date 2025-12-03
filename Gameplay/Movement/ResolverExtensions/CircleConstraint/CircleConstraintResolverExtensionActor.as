/**
 * Used with UCircleConstraintResolverExtension to define the constraint location, normal and radius.
 */
UCLASS(NotBlueprintable)
class ACircleConstraintResolverExtensionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Radius = 500;

	/**
	 * If true, we will clamp location as well.
	 * Note that this can cause issues on uneven terrain!
	 */
	UPROPERTY(EditAnywhere)
	bool bHardConstraint = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "S_Pawn";
	default EditorIcon.WorldScale3D = FVector(2);

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugCircle(ActorLocation, Radius, 100, FLinearColor::Yellow, 10, ActorRightVector, bDrawAxis = true);
	}
#endif
};