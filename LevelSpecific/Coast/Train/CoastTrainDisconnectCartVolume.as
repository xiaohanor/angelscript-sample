class ACoastTrainDisconnectCartVolume : AActorTrigger
{
	default BrushComponent.LineThickness = 5;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineRef;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect BounceFF;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	ACoastTrainCart ExtraCartToAffect;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetActorLocation(SplineRef.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		// Commented out because we don't want to use this trigger right now, but should definitely be back soon
		// OnActorEnter.AddUFunction(this, n"CartEntered");
	}

	UFUNCTION()
	void CartEntered(AHazeActor Actor)
	{
		auto TrainCart = Cast<ACoastTrainCart>(Actor);

		if(!TrainCart.bCartDisconnected)
		{
			TrainCart.DisconnectCart();
			
			//Rewrite this to world shake and distance check for the FF if not in world also
			Game::GetMio().PlayForceFeedback(BounceFF, false, false, this, 1);
			Game::GetZoe().PlayForceFeedback(BounceFF, false, false, this, 1);
			Game::GetMio().PlayCameraShake(CameraShake, this, 1);
			Game::GetZoe().PlayCameraShake(CameraShake, this, 1);
		
			if(ExtraCartToAffect != nullptr)
				ExtraCartToAffect.DisconnectCart();
		}


	}
}