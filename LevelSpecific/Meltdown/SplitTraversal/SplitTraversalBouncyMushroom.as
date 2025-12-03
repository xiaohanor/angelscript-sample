UCLASS(Abstract)
class USplitTraversalBouncyMushroomEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {}
}

class ASplitTraversalBouncyMushroom : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MushroomRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	float BounceImpulse = 2000;

	UPROPERTY()
	FHazeTimeLike BounceTimeLike;
	default BounceTimeLike.UseSmoothCurveZeroToOne();
	default BounceTimeLike.Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		BounceTimeLike.BindUpdate(this, n"BounceTimeLikeUpdate");
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe())
		{
			Player.AddMovementImpulse(FVector(0, 0, BounceImpulse));
			BounceTimeLike.PlayFromStart();
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);

			USplitTraversalBouncyMushroomEventHandler::Trigger_OnBounce(this);
		}
	}

	UFUNCTION()
	private void BounceTimeLikeUpdate(float CurrentValue)
	{
		float ScaleMultiplier = Math::Lerp(1.0, 1.2, CurrentValue);
		MushroomRoot.SetRelativeScale3D(FVector(ScaleMultiplier, ScaleMultiplier, 1 / ScaleMultiplier));
	}
};