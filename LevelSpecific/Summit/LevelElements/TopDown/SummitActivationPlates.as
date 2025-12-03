event void FASummitActivationPlateSignature();
class ASummitActivationPlate : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PressurePlate;

    UPROPERTY(DefaultComponent)
	USceneComponent PressurePos;
    FVector PressureStartLocation;
    FVector PressureToLocation;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlateCollision;
	default PlateCollision.SetCollisionProfileName(n"OverlapAllDynamic");

	UPROPERTY()
	FASummitActivationPlateSignature OnPressured;

    UPROPERTY()
	FASummitActivationPlateSignature OnUnPressured;

    UPROPERTY()
	FASummitActivationPlateSignature OnActorLeft;

	UPROPERTY()
	ASummitActivationPlateListener Parent;

	UPROPERTY(EditAnywhere)
	float PressDuration = 0.5;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ButtonAnimation;
	default ButtonAnimation.Duration = 1.0;
	default ButtonAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ButtonAnimation.Curve.AddDefaultKey(1.0, 1.0);

    UPROPERTY(BlueprintReadOnly)
	bool bPressured;

	UPROPERTY(BlueprintReadOnly)
	bool bActivated;

	UPROPERTY(BlueprintReadOnly)
	bool bCompleted;

	UPROPERTY(EditAnywhere)
	FName Team = n"";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        PressureStartLocation = PressurePlate.GetRelativeLocation();
        PressureToLocation = PressurePos.GetRelativeLocation();
		ButtonAnimation.SetPlayRate(1.0 / PressDuration);
		ButtonAnimation.BindUpdate(this, n"OnUpdate");
		ButtonAnimation.BindFinished(this, n"OnFinished");

		PlateCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		if(Team != n"")
			JoinTeam(Team);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		PressurePlate.SetRelativeLocation(Math::Lerp(PressureStartLocation, PressureToLocation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bPressured = !ButtonAnimation.IsReversed();
		
		if(bPressured) 
        {
			OnPressured.Broadcast();
        } 
        else 
        {
			OnUnPressured.Broadcast();
        }
	}

	UFUNCTION()
	void Activated()
	{
        ButtonAnimation.Play();
	}

	UFUNCTION()
	void Deactivated()
	{
        OnActorLeft.Broadcast();
		ButtonAnimation.Reverse();
	}

	UFUNCTION()
	void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(bCompleted)
			return;

		if(OtherActor == Game::Mio || OtherActor == Game::Zoe)
		{

			if(bActivated)
			{
				bActivated = false;
			}
			else
			{
				bActivated = true;
				Activated();
			}
			
			Parent.CheckChildren();

		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinished()
	{
		
	}


}