event void FASanctuaryPressurePlateSignature();
class ASanctuaryPressurePlate : AHazeActor
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
	FASanctuaryPressurePlateSignature OnPressured;

    UPROPERTY()
	FASanctuaryPressurePlateSignature OnUnPressured;

    UPROPERTY()
	FASanctuaryPressurePlateSignature OnActorLeft;

    UPROPERTY(EditAnywhere)
    ASanctuaryPressurePlate Sibling;
    bool bHasSibling;
    bool bSiblingActivated;

	UPROPERTY(EditAnywhere)
	float PressDuration = 0.5;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ButtonAnimation;
	default ButtonAnimation.Duration = 1.0;
	default ButtonAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ButtonAnimation.Curve.AddDefaultKey(1.0, 1.0);

    UPROPERTY(BlueprintReadOnly)
	bool bPressured;
	
    UPROPERTY(EditAnywhere)
	bool bOneOff;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        PressureStartLocation = PressurePlate.GetRelativeLocation();
        PressureToLocation = PressurePos.GetRelativeLocation();
		ButtonAnimation.SetPlayRate(1.0 / PressDuration);
		ButtonAnimation.BindUpdate(this, n"OnUpdate");
		ButtonAnimation.BindFinished(this, n"OnFinished");

        if (Sibling != nullptr)
            bHasSibling = true;
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
            if (bHasSibling)
            {
                if (Sibling.bPressured)
			        OnPressured.Broadcast();
            }
            else
            {
                OnPressured.Broadcast();
            }
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

}