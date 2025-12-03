
class ASkylineBallBossStageActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent StageBounds;
	default StageBounds.RelativeLocation = FVector(0.0, 556.0, -30.0);
	default StageBounds.BoxExtent = FVector(32.0 * 30.0, 32.0 * 37.0, 5.0);

	bool bConstrainToFront = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent FrontStageBounds;
	default FrontStageBounds.RelativeLocation = FVector(0.0, -600.0, -30.0);
	default FrontStageBounds.BoxExtent = FVector(32.0 * 30.0, 5.0, 5.0);

	FBox StageBox;
	FBox FrontBox;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector StageBoxExtent = FVector(StageBounds.BoxExtent.X, StageBounds.BoxExtent.Y, 5000.0);
		StageBox = FBox(-StageBoxExtent, StageBoxExtent);
		FrontBox = FBox(-FrontStageBounds.BoxExtent, FrontStageBounds.BoxExtent);
	}
}