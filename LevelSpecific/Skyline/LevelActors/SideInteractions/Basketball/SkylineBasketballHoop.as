class ASkylineBasketballHoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent HoopPivot;

	UPROPERTY(DefaultComponent)
	USkylineBasketballResponseComponent BasketballResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};