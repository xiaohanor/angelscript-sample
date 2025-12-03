USTRUCT()
struct FCentipedeSplitMovingPlatformConstraintHitParams
{
	EFauxPhysicsTranslateConstraintEdge Edge;
}

UCLASS(Abstract)
class UCentipedeSplitMovingPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstraintHit(FCentipedeSplitMovingPlatformConstraintHitParams ConstraintHitParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}
}

class ACentipedeSplitMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(EditAnywhere)
	float ReverseDelay = 1.0;

	bool bCoolDown = false;

	UPROPERTY(EditAnywhere)
	APlayerTrigger EnableTrigger;

	UPROPERTY(EditAnywhere)
	APlayerTrigger DisableTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
		EnableTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnterEnablePlatforms");
		DisableTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnterDisablePlatforms");
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (!bCoolDown)
		{
			bCoolDown = true;
			Timer::SetTimer(this, n"InvertForce", ReverseDelay);

			FCentipedeSplitMovingPlatformConstraintHitParams Params;
			Params.Edge = Edge;

			UCentipedeSplitMovingPlatformEventHandler::Trigger_OnConstraintHit(this, Params);
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		}
	}

	UFUNCTION()
	private void HandlePlayerEnterDisablePlatforms(AHazePlayerCharacter Player)
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	private void HandlePlayerEnterEnablePlatforms(AHazePlayerCharacter Player)
	{
		RemoveActorDisable(DisableComp.StartDisabledInstigator);
	}

	UFUNCTION()
	private void InvertForce()
	{
		ForceComp.Force = ForceComp.Force * -1;
		bCoolDown = false;

		UCentipedeSplitMovingPlatformEventHandler::Trigger_OnStartMoving(this);
	}
	
};