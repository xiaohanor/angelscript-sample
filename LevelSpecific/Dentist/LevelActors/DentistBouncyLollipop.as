UCLASS(Abstract)
class ADentistBouncyLollipop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;
	
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	float ImpulseStrength = 3000.0;

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
		FVector LaunchImpulse = ActorForwardVector * ImpulseStrength;

		bool bInFront = ActorForwardVector.DotProduct((Player.ActorLocation - ActorLocation).GetSafeNormal()) > 0.0;

		if (!bInFront)
			LaunchImpulse = -LaunchImpulse;

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp != nullptr)
			ResponseComp.OnImpulseFromObstacle.Broadcast(this, LaunchImpulse, RagdollSettings);

		RotateComp.ApplyImpulse(Player.ActorLocation, -LaunchImpulse);

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);

		BP_Audio_OnLaunchPlayer(Player);
	}

	/**
	 * AUDIO
	 */
	UFUNCTION(BlueprintEvent)
	private void BP_Audio_OnLaunchPlayer(AHazePlayerCharacter Player) {}
};