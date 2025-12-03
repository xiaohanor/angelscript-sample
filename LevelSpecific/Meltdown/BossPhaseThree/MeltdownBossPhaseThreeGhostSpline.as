event void FOnGhostDone();

class AMeltdownBossPhaseThreeGhostSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LaserCutter;

	UPROPERTY(DefaultComponent, Attach = LaserCutter)
	UNiagaraComponent GhostFX;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float Speed = 2000;

	UPROPERTY()
	float CurrentSplineDistance;

	UPROPERTY()
	FOnGhostDone GhostDone;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;
	default PortalMesh.SetHiddenInGame(true);

	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	FHazeTimeLike PortalAnim;
	default PortalAnim.Duration = 1.0;
	default PortalAnim.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		AddActorDisable(this);
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);

		SplineComp = Spline.Spline;
		GhostFX.AttachToComponent(SplineComp);

		PortalAnim.BindFinished(this, n"OnPortalFinished");
		PortalAnim.BindUpdate(this, n"OnPortalUpdate");
	}

	UFUNCTION(BlueprintCallable)
	void StartAttack()
	{
		RemoveActorDisable(this);
		SetActorHiddenInGame(false);

		PortalAnim.Play();
		PortalMesh.SetHiddenInGame(false);

		Timer::SetTimer(this, n"StopSpawn", 15.0);
	}

	UFUNCTION()
	private void StopSpawn()
	{
	}

	UFUNCTION()
	private void OnPortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	private void OnPortalFinished()
	{
		if(PortalAnim.IsReversed())
		return;

		SetActorTickEnabled(true);
		PortalMesh.DetachFromComponent(EDetachmentRule::KeepWorld);
		PortalAnim.ReverseFromEnd();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);
		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

		GhostFX.WorldTransform = ActorTransform;

		float BaseWidth = 100.0;
		FVector2D Width = FVector2D(-1.0, 1.0);
		FVector2D Height = FVector2D(-0.5, 0.5);
		FVector2D Length = FVector2D(-500.0, 0.0);

		GhostFX.SetNiagaraVariableFloat("LifeTime", (Math::Abs(Length.X) / Speed) * 2.0);
		GhostFX.SetNiagaraVariableVec3("Size", FVector(500.0, (Width.Y - Width.X) * BaseWidth, (Height.Y - Height.X) * BaseWidth));

		// let niagara know where on the spline it is.
		GhostFX.SetNiagaraVariableFloat("CurrentSplineFraction", CurrentSplineDistance / SplineComp.SplineLength);
		GhostFX.SetNiagaraVariableFloat("WalkingSpeed", Speed);
		
	//	Debug::DrawDebugBox(DeathTrigger.WorldLocation, DeathTrigger.Shape.BoxExtents, DeathTrigger.WorldRotation, FLinearColor::Red, 10.0);

		if(CurrentSplineDistance >= SplineComp.SplineLength)
		{
			AddActorDisable(this);
			GhostDone.Broadcast();
		}
	}
	
};