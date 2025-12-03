UCLASS(NotBlueprintable)
class AGravityBikeSplineAutoJumpTrigger : APlayerTrigger
{
	default bTriggerForZoe = false;
	default bTriggerLocally = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeSplineAutoJumpTriggerComponent AutoJumpTriggerComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIconComp;
	default EditorIconComp.SpriteName = "S_RadForce";
	default EditorIconComp.WorldScale3D = FVector(10);
#endif
};