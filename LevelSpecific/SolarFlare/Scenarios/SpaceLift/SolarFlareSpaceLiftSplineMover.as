class ASolarFlareSpaceLiftSplineMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;
	default SplineMoveComp.bBackAndForth = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	//Rotation for breaking sequences
	void SetRotationTarget()
	{

	}
}