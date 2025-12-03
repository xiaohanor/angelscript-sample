UCLASS(Abstract)
class ASkylineBossManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif

	UPROPERTY(EditInstanceOnly)
	ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss.OnTraversalBegin.AddUFunction(this, n"HandleTraversalBegin");
		Boss.OnTraversalEnd.AddUFunction(this, n"HandleTraversalEnd");
	}

	UFUNCTION()
	private void HandleTraversalBegin(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub)
	{
	}

	UFUNCTION()
	private void HandleTraversalEnd(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub)
	{
		// Boss.MoveAlongSpline(Hub.Paths[Math::RandRange(0, 2)]);
	}
};