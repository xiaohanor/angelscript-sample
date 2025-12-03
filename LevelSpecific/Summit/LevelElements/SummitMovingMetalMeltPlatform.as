class ASummitMovingMetalMeltPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal QueenMetalLeft;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal QueenMetalRight;


	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBillboardComponent PlatformTarget;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
 
	UHazeSplineComponent SplineComp;

	bool bIsReversing;

	float CurrentDistance;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  PlatformAnimation;
	default PlatformAnimation.Duration = 10.0;
	default PlatformAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default PlatformAnimation.Curve.AddDefaultKey(5.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformAnimation.BindUpdate(this, n"OnUpdate");
		QueenMetalLeft.OnNightQueenMetalMelted.AddUFunction(this, n"LeftMetalMelted");
		QueenMetalRight.OnNightQueenMetalMelted.AddUFunction(this, n"RightMetalMelted");
		SplineComp = SplineActor.Spline;
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		
	}

	UFUNCTION()
	private void LeftMetalMelted()
	{	
		PlatformAnimation.Play();
		bIsReversing = false;
	}
	UFUNCTION()
	private void RightMetalMelted()
	{
		PlatformAnimation.Reverse();
		bIsReversing = true;
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		CurrentDistance = Math::GetMappedRangeValueClamped(FVector2D(0,1), FVector2D(0, SplineComp.SplineLength), Alpha);
		
		if (!bIsReversing)
			CurrentDistance += Alpha * 100;
		else
			CurrentDistance -= Alpha * 100;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
	
	}

}