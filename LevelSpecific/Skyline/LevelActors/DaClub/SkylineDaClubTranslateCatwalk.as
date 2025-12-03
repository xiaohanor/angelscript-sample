class ASkylineDaClubTranslateCatwalk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 1.0;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -500.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 3000.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	TArray<AActor> ActivationActors;
	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		ActivationActors = InterfaceComp.ListenToActors;
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ActivationActors.Remove(Caller);
		USkylineDaClubTranslateCatwalkEventHandler::Trigger_OnRopeCut(this);

		if (!bIsActivated && ActivationActors.Num() == 0)
			Activate();
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		ForceComp.RemoveDisabler(this);
		USkylineDaClubTranslateCatwalkEventHandler::Trigger_OnFall(this);
	}
};

class USkylineDaClubTranslateCatwalkEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnRopeCut() {}

	UFUNCTION(BlueprintEvent)
	void OnFall() {}
}