class AMeltdownScreenWalkCartButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Button;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ArrowLeft;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ArrowRight;

	UPROPERTY(EditAnywhere)
	AScreenWalkConstrainedPlatform MineCart;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};