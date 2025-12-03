enum EBloodGateCentipedeLegType
{
	Both,
	Left,
	Right
}

class ASanctuaryBloodGateCentipedeLeg : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftLegMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightLegMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBloodGateCentipedeLeg LinkedLeg;

	UPROPERTY(EditInstanceOnly)
	EBloodGateCentipedeLegType Type;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch (Type)
		{
			case EBloodGateCentipedeLegType::Both:;
			break;
			case EBloodGateCentipedeLegType::Left:
			RightLegMeshComp.SetHiddenInGame(true, true);
			break;
			case EBloodGateCentipedeLegType::Right:
			LeftLegMeshComp.SetHiddenInGame(true, true);
			break;
		}
	}

	void Activate()
	{
		if (LinkedLeg != nullptr)
			LinkedLeg.Activate();

		QueueComp.Duration(0.5, this, n"ExtendUpdate");
	}

	UFUNCTION()
	private void ExtendUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(-50.0, 50.0, Alpha, 2.0);
        FVector Scale = Math::Lerp(FVector(0.4, 0.4, 0.4), FVector::OneVector, Alpha);
        LeftLegMeshComp.SetRelativeLocation(FVector::RightVector * CurrentValue);
        RightLegMeshComp.SetRelativeLocation(FVector::RightVector * -CurrentValue);
        LeftLegMeshComp.SetRelativeScale3D(Scale);
        RightLegMeshComp.SetRelativeScale3D(Scale);
	}
};