UCLASS(NotBlueprintable)
class ADesertVortexSpinningCenter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "T_Loft_Spline";
	default Billboard.WorldScale3D = FVector(10);
	#endif
	
	UPROPERTY(EditAnywhere)
	protected float SpinSpeed = 3;

	float TransitionAlpha = 1;

	UPROPERTY(EditAnywhere, Category = Transition)
	float TransitionTime = 10;

	UPROPERTY(EditAnywhere, Category = Transition)
	float TransitionExponent = 2;

	protected FRotator StartRelativeRotation;
	protected FRotator TargetRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRelativeRotation = ActorRelativeRotation;
		TargetRelativeRotation = ActorRelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldRotation(FRotator(0, SpinSpeed * DeltaSeconds, 0));

		if(TransitionAlpha < 1 - KINDA_SMALL_NUMBER)
		{
			TransitionAlpha += DeltaSeconds / TransitionTime;
			if(TransitionAlpha > 1)
				TransitionAlpha = 1;
			const float LerpAlpha = Math::EaseInOut(0, 1, TransitionAlpha, TransitionExponent);
			const FRotator RelativeRotation = Math::LerpShortestPath(StartRelativeRotation, TargetRelativeRotation, LerpAlpha);
			SetActorRelativeRotation(RelativeRotation);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetSpinSpeed(float InSpinSpeed)
	{
		if(!HasControl())
			return;

		CrumbSetSpinSpeed(InSpinSpeed);
	}

	float GetSpinSpeed() const
	{
		return SpinSpeed;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetSpinSpeed(float InSpinSpeed)
	{
		SpinSpeed = InSpinSpeed;
	}

	UFUNCTION()
	void ResetRotation()
	{
		if(!HasControl())
			return;

		CrumbResetRotation();
	}

	UFUNCTION(CrumbFunction)
	void CrumbResetRotation()
	{
		ActorRelativeRotation = StartRelativeRotation;
	}

	UFUNCTION(BlueprintCallable)
	void StartTransitionToRelativeRotation(FRotator InTargetRelativeRotation)
	{
		if(!HasControl())
			return;

		CrumbStartTransitionToRelativeRotation(InTargetRelativeRotation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartTransitionToRelativeRotation(FRotator InRelativeRotation)
	{
		TransitionAlpha = 0;
		StartRelativeRotation = ActorRelativeRotation;
		TargetRelativeRotation = InRelativeRotation;
	}
};