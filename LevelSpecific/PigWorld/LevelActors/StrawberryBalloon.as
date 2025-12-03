UCLASS(Abstract)
class AStrawberryBalloon : AAmbientMovement
{
	UPROPERTY(DefaultComponent)
	UCableComponent Cable1;
	UPROPERTY(DefaultComponent, Attach = ActualMesh)
	USceneComponent CableAttach1;

	UPROPERTY(DefaultComponent)
	UCableComponent Cable2;
	UPROPERTY(DefaultComponent, Attach = ActualMesh)
	USceneComponent CableAttach2;

	UPROPERTY(DefaultComponent)
	UCableComponent Cable3;
	UPROPERTY(DefaultComponent, Attach = ActualMesh)
	USceneComponent CableAttach3;

	UPROPERTY(DefaultComponent)
	UCableComponent Cable4;
	UPROPERTY(DefaultComponent, Attach = ActualMesh)
	USceneComponent CableAttach4;
}