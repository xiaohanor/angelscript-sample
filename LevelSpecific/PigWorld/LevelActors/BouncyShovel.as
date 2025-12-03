UCLASS(Abstract)
class ABouncyShovel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent ShovelRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditAnywhere)
	float BounceImpulse = 2200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		FVector Velocity = Player.ActorForwardVector + (FVector::UpVector * BounceImpulse);
		Player.SetActorVelocity(Velocity);

		auto FartComponent = UPlayerPigRainbowFartComponent::Get(Player);
		if (FartComponent != nullptr) 
			FartComponent.InterruptFart();

		ShovelRoot.ApplyAngularImpulse(-5.0);

		BP_Bounce();

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Bounce() {}
}