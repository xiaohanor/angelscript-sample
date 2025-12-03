UCLASS(Abstract)
class AMoonMarketTrumpetHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USquashSceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USquashSceneComponent SquashRoot;

	UPROPERTY(DefaultComponent, Attach = SquashRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphShapeComponent ShapeComp;
	default ShapeComp.ShapeData.ShapeTag = "Trumpet";
	default ShapeComp.ShapeData.bIsBubbleBlockingShape = true;
	default ShapeComp.ShapeData.bCanDash = false;
	default ShapeComp.ShapeData.bUseCustomMovement = true;
	default ShapeComp.ShapeData.bCancelByThunder = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};