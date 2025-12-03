UCLASS(Abstract)
class AStormChaseFallingCrystalObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormChaseFallingObstacleComponent FallingComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonHomingTailSmashAutoAimComponent HomingSmashAutoAimComp;
	default HomingSmashAutoAimComp.AutoAimMaxAngle = 60.0;
	default HomingSmashAutoAimComp.TargetShape = FHazeShapeSettings::MakeBox(FVector(50, 50, 50));

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnTailSmashHit");
	}

	UFUNCTION()
	private void OnTailSmashHit(FTailSmashModeHitParams Params)
	{
		DestroyActor();
	}
};