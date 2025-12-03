class ASkylineGlassRoofOverPass : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp;

	UPROPERTY(EditAnywhere)
	ASkylineBreakableGlassRoofSegment RoofSegment;

	UPROPERTY(EditAnywhere)
	TArray<AHazeProp> GlassProps;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RoofSegment.OnMissileHit.AddUFunction(this,n"HandleOnMissleHit");
	}

	UFUNCTION()
	private void HandleOnMissleHit()
	{
		ActionQueComp.Duration(1.5, this, n"UpdateOverPassFall");
		Timer::SetTimer(this, n"DestroyGlass", 0.5);
		//PrintToScreenScaled("HIIIIIIIIIIIIIT", )
	}

	UFUNCTION()
	private void DestroyGlass()
	{
		for(auto GlassProp : GlassProps)
		{
			GlassProp.DestroyActor();
		}
	}

	UFUNCTION()
	private void UpdateOverPassFall(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		
		SceneComp.SetRelativeLocation(FVector(0.0, 0.0, Math::Lerp(0.0, -4500.0, AlphaValue)));
	}


	
};