class AJetskiSquidArmSequenceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;
	default Mesh01.RelativeScale3D = FVector(15.0, 15.0, 15.0);

	UPROPERTY(DefaultComponent, Attach = Mesh01)
	UStaticMeshComponent Mesh02;
	default Mesh02.RelativeLocation = FVector(165.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = Mesh02)
	UStaticMeshComponent Mesh03;
	default Mesh03.RelativeLocation = FVector(165.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = Mesh03)
	UStaticMeshComponent Mesh04;
	default Mesh04.RelativeLocation = FVector(165.0, 0.0, 0.0);
}