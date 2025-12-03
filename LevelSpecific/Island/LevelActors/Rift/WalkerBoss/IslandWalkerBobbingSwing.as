class AIslandWalkerBobbingSwing : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "BaseComp")
	USwingPointComponent SwingPoint;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	float AmbientMovementStartTime = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 10;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ClosestPlayerDistance = Game::GetDistanceFromLocationToClosestPlayer(ActorLocation);

		if (ClosestPlayerDistance < 10000.0)
		{
			float Time = Math::Wrap(Time::PredictedGlobalCrumbTrailTime - AmbientMovementStartTime, 0, AmbientMovementDuration);
			float SinMove = Math::Sin(Time/AmbientMovementDuration*PI*2)*AmbientMovementAmplitude * 1.5;
			BaseComp.SetRelativeLocation(FVector(BaseComp.RelativeLocation.X,BaseComp.RelativeLocation.Y,SinMove));
		}
	}

	UFUNCTION()
	void DisableBobbingSwing()
	{
		BP_DisableBobbingSwing();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DisableBobbingSwing()
	{

	}

}