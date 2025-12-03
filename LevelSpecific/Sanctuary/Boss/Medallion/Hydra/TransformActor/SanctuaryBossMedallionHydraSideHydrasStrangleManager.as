class ASanctuaryBossMedallionHydraSideHydrasStrangleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftHydra;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightHydra;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	const float StartSidewaysOffset = 10000.0;
	const float StartForwardssOffset = 5000.0;

	FRotator StartWorldRotation;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra HydraLeft;
	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra HydraRight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void SlideInHydras(FRotator InitialWorldRotation)
	{
		StartWorldRotation = InitialWorldRotation;
		SetActorRotation(StartWorldRotation);

		LeftHydra.SetRelativeLocation(FVector::RightVector * StartSidewaysOffset); 
		RightHydra.SetRelativeLocation(FVector::RightVector * -StartSidewaysOffset); 
		//QueueComp.Idle(3.0);
		QueueComp.Duration(2.5, this, n"SlideInHydrasUpdate");

		if (HydraLeft != nullptr)
			HydraLeft.EnterMhAnimation(EFeatureTagMedallionHydra::Cheerlead);
		if (HydraRight != nullptr)
			HydraRight.EnterMhAnimation(EFeatureTagMedallionHydra::Cheerlead);
	}

	UFUNCTION()
	private void SlideInHydrasUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		FRotator LerpedRotation = Math::LerpShortestPath(StartWorldRotation, FRotator::ZeroRotator, CurrentValue);

		float SidewaysOffset = Math::Lerp(StartSidewaysOffset, 0.0, CurrentValue);
		FVector ForwardsLocation = FVector::ForwardVector * Math::Lerp(StartForwardssOffset, 0.0, CurrentValue);

		LeftHydra.SetRelativeLocation(FVector::RightVector * SidewaysOffset + ForwardsLocation); 
		RightHydra.SetRelativeLocation(FVector::RightVector * -SidewaysOffset + ForwardsLocation); 

		SetActorRotation(LerpedRotation);
	}

	UFUNCTION()
	void StopCheerleading()
	{
		if (HydraLeft != nullptr)
		{
			HydraLeft.ExitMhAnimation(EFeatureTagMedallionHydra::Cheerlead);
			HydraLeft.AppendIdleAnimation();
		}
		if (HydraRight != nullptr)
		{
			HydraRight.ExitMhAnimation(EFeatureTagMedallionHydra::Cheerlead);	
			HydraRight.AppendIdleAnimation();
		}
	}
};