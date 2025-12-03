UCLASS(Abstract)
class ASanctuaryHydraTutorialFlyingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuaryFloatingSceneComponent FloatComp;

	UPROPERTY(DefaultComponent, Attach = FloatComp)
	UStaticMeshComponent PlatformMesh;
};
