UCLASS(Abstract)
class USkylineInnerCityLeverEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated()
	{
	}

};	
class ASkylineInnerCityLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp;
	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp2;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompReset;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompFinish;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompForceActivate;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	AKineticSplineFollowActor SplineActor;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SparkVFX;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect FF;

	UFUNCTION(BlueprintEvent)
	void BP_ConstraintHit() {};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		ForceCompFinish.AddDisabler(this);
		ForceCompForceActivate.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RotateComp.WorldRotation.Roll >= 90.0)
		{
			ForceCompFinish.RemoveDisabler(this);
			ForceCompReset.AddDisabler(this);
		}
	}

	UFUNCTION()
	private void HandleConstrainHit(float Strength)
	{
		ForceCompForceActivate.AddDisabler(this);
		InterfaceComp.TriggerActivate();
		SplineActor.ActivateFollowSpline();
		GravityWhipTargetComponent.Disable(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp.GetWorldLocation());
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp2.GetWorldLocation());
		USkylineInnerCityLeverEventHandler::Trigger_OnActivated(this);
		ForceFeedback::PlayWorldForceFeedback(FF, ActorLocation, false, this, 500, 700, 1.0, 1.0, EHazeSelectPlayer::Both);
		BP_ConstraintHit();
	}

	UFUNCTION(BlueprintCallable)
	void ForceActivate()
	{
		ForceCompForceActivate.RemoveDisabler(this);
	}
};