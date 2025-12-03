event void FonSpinningDone();

class AMeltdownBossFlyingSpinningAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PortalMesh;
	
	float PitchRotation;

	UPROPERTY(EditAnywhere)
	float Rotation;

	UPROPERTY(EditAnywhere)
	float OffsetDown;

	UPROPERTY(EditAnywhere)
	float OffsetUp;

	UPROPERTY(EditAnywhere)
	float Offset;
	
	UPROPERTY()
	float LifeTime;

	UPROPERTY(EditAnywhere)
	float StartDelay;

	UPROPERTY()
	FonSpinningDone AttackDone;

	UPROPERTY()
	FVector StartingLocation;

	FHazeTimeLike PitchModifier;
	default PitchModifier.Duration = 2.0;
	default PitchModifier.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		AddActorDisable(this);

		StartingLocation = ActorLocation;

		PitchModifier.BindFinished(this, n"OnDone");
		PitchModifier.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		PitchRotation = Math::Lerp(OffsetDown,OffsetUp, CurrentValue);
	}

	UFUNCTION()
	private void OnDone()
	{
		if(PitchModifier.IsReversed())
		{
			PitchModifier.PlayFromStart();
			return;
		}

		PitchModifier.ReverseFromEnd();
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{


		Timer::SetTimer(this, n"StartAttack", StartDelay);
	}

	UFUNCTION()
	private void StartAttack()
	{
		RemoveActorDisable(this);
		SetActorTickEnabled(true);
		StartAnim();
		Timer::SetTimer(this, n"FinishAttack", LifeTime);
	}

	UFUNCTION(BlueprintEvent)
	void StartAnim()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(Offset,Rotation,0) * DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent)
	private void FinishAttack()
	{
	}

	UFUNCTION(BlueprintCallable)
	void AnimComplete()
	{
		AttackDone.Broadcast();
		 ActorLocation = StartingLocation;
		AddActorDisable(this);
	}

};