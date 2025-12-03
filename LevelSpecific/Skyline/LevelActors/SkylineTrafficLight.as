event void FTrafficLightStop();
class ASkylineTrafficLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
		
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent RedLight;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent GreenLight;

	UPROPERTY()
	FTrafficLightStop TrafficStop;

	UPROPERTY()
	FTrafficLightStop TrafficStart;

	UPROPERTY(EditInstanceOnly)
	AActorTrigger CarTrigger;
	
	UPROPERTY(EditAnywhere)
	bool bCanStop = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CarTrigger.OnActorBeginOverlap.AddUFunction(this, n"TestCarHit");
		TimeLike.BindUpdate(this, n"AnimUpdate");
		TimeLike.Play();
	}


	UFUNCTION()
	private void AnimUpdate(float Value)
	{
		Base.RelativeLocation = FVector(0.0, 0.0, Value * 30);
	}

	UFUNCTION()
	private void TestCarHit(AActor OverlappedActor, AActor OtherActor)
	{
		if(bCanStop==true)
		{
		ChangeMaterial();
		TimeToStop();
		bCanStop=false;
		}
		
	}

	UFUNCTION(DevFunction)
	void TimeToStop(){
		TrafficStop.Broadcast();
	}

	UFUNCTION(DevFunction)
	void TimeToStart(){
		TrafficStart.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void ChangeMaterial(){

	}
};