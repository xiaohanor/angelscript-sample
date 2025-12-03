UCLASS(Abstract)
class ASketchbook_Bow_Fallingperch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallScene;

	UPROPERTY(DefaultComponent, Attach = FallScene)
	UStaticMeshComponent RopeMeshComp;

	UPROPERTY(DefaultComponent, Attach = RopeMeshComp)
	USketchbookArrowResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallToLocation;

	UPROPERTY(EditAnywhere)
	float SinkDistance = 500;

};
