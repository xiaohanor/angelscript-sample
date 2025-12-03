class AMoonMarketCheese : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Scene;
	//default Scene.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = Scene)
	UStaticMeshComponent Cheese;
};