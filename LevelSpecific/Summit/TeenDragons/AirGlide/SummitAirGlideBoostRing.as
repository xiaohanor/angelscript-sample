struct FSummitAirGlideBoostRingParams
{
	// Normalized 1 - 0 of velocity & boost duration
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve BoostCurve;

	// The maximum additional velocity of the boost (1 in the curve value axle)
	UPROPERTY(EditAnywhere)
	float MaxBoostSpeed = 5000.0;

	// Seconds of boost
	UPROPERTY(EditAnywhere)
	float BoostDuration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bStopDownwardsSpeed = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bStopDownwardsSpeed", EditConditionHides))
	float DownwardsSpeedStopDuration = 1.2;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bStopDownwardsSpeed", EditConditionHides))
	float DownwardsSpeedStopAcceleration = 2.0;

	UPROPERTY(EditAnywhere)
	float ForceGlideDuration = 1.0;

	float BoostTimer = 0.0;

	ASummitAirGlideBoostRing BoostRing;
};

class ASummitAirGlideBoostRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent OverlapCollisionMesh;

	UPROPERTY(EditAnywhere)
	FSummitAirGlideBoostRingParams BoostParams;
	default BoostParams.BoostCurve.AddDefaultKey(0, 0);
	default BoostParams.BoostCurve.AddDefaultKey(0.5, 1.0);	
	default BoostParams.BoostCurve.AddDefaultKey(1, 0.0);	

	UPROPERTY()
	UForceFeedbackEffect BoostFeedback;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		Player = Cast<AHazePlayerCharacter>(OtherActor); 
		if(Player == nullptr)
			return;

		UTeenDragonAirGlideComponent AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		if(AirGlideComp == nullptr)
			return;

		// if(!AirGlideComp.bIsAirGliding && !AirGlideComp.bInAirCurrent)
		// 	return;

		BoostParams.BoostRing = this;
		
		AirGlideComp.RequestRingBoost(BoostParams);
		Player.PlayForceFeedback(BoostFeedback, false, false, this);
	}
};