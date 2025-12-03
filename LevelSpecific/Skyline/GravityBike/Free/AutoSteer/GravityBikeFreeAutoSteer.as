UCLASS(NotBlueprintable)
class AGravityBikeFreeAutoSteer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.WorldScale3D = FVector(10);
#endif

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeFreeAutoSteerTargetComponent AutoSteerComp;
};