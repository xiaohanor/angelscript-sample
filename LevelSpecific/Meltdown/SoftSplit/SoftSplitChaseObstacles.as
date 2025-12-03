class ASoftSplitChaseObstacles : AWorldLinkDoubleActor
{
	UPROPERTY(EditAnywhere)
	ASoftSplitChaseGlitch ChaseGlitch;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USoftSplitBobbingComponent Bobbing;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USoftSplitBobbingComponent BobbingFantasy;


	UPROPERTY()
	FHazeTimeLike AmpIncrease;
	default AmpIncrease.Duration = 1;
	default AmpIncrease.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
};