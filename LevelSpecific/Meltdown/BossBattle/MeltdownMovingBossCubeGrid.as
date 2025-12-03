class AMeltdownMovingBossCubeGrid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent DisplacementActor;

	UPROPERTY()
	float DisplacementZ = 500.0;


	UPROPERTY()
	FHazeTimeLike DisplacementLike;
	default DisplacementLike.Duration = 5.0;
	default DisplacementLike.UseLinearCurveZeroToOne();
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}


	UFUNCTION(BlueprintCallable)
	void StartDisplacement()
	{
		DisplacementActor.ActivateDisplacement();
		StartTimelike();
		}

	UFUNCTION(BlueprintEvent)
	void StartTimelike()
	{}
}; 