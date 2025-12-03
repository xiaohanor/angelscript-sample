class AForgeMoveableChuteTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent EndPoint1;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent EndPoint2;

}