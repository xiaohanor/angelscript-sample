class ASummitMetalRotatingPlattform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal QueenMetalLeft;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal QueenMetalRight;

	UPROPERTY()
	FRotator PlatformRotation;
}