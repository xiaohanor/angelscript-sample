class ASkylineSwingDrone : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Base;


	UPROPERTY(DefaultComponent, Attach = Base)
	USwingPointComponent SwingPoint;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		TimeLike.BindUpdate(this, n"AnimUpdate");
		TimeLike.Play();
	}


	UFUNCTION()
	private void AnimUpdate(float Value)
	{
		Base.RelativeLocation = FVector(0.0, 0.0, Value * 15);
	}



};