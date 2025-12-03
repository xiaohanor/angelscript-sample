UCLASS(Abstract)
class ASkylineCarPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent Collision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	// --- Animation variables ---

	UPROPERTY(EditInstanceOnly, Category = "Animation")
	FRotator AnimWheelRotation = FRotator(2, 0.5, 3);

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence Animation;
};
