class ADentistBouncyObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	float AwayImpulse = 1000;

	UPROPERTY(EditAnywhere)
	float MaxVerticalImpulse = 1000;

	UPROPERTY(EditAnywhere)
	bool bNeverLaunchDownwards = true;

	UPROPERTY(EditAnywhere)
	FDentistToothApplyRagdollSettings RagdollSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComponent.OnAnyImpactByPlayer.AddUFunction(this, n"HandlePlayerImpact");
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);
		FVector ClosestLocation = MoveIntoPlayerShapeComp.Shape.GetClosestPointToPoint(MoveIntoPlayerShapeComp.WorldTransform, Player.ActorCenterLocation);
		FVector DirectionToPlayer = (Player.ActorCenterLocation - ClosestLocation).GetSafeNormal();

		if(bNeverLaunchDownwards)
		{
			if(DirectionToPlayer.Z < 0.0)
				DirectionToPlayer.Z = 0.0;
		}

		FVector Impulse = (DirectionToPlayer * AwayImpulse);

		if (Impulse.Z > MaxVerticalImpulse)
			Impulse.Z = MaxVerticalImpulse;

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp != nullptr)
		{
			ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
		}

		BP_Audio_OnLaunchPlayer(Player);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Audio_OnLaunchPlayer(AHazePlayerCharacter Player) {}
};