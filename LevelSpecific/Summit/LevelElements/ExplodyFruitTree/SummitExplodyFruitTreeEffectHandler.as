struct FSummitExplodyFruitFallingFromTreeParams
{
	UPROPERTY()
	FVector FruitStemLocation;
}

struct FSummitExplodyFruitLandingOnGroundParams
{
	UPROPERTY()
	FVector LandLocation;
}

UCLASS(Abstract)
class USummitExplodyFruitTreeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitFallingFromTree(FSummitExplodyFruitFallingFromTreeParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitLandingOnGround(FSummitExplodyFruitLandingOnGroundParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitExploding()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitExplodingWithWall()
	{
		
	}
};