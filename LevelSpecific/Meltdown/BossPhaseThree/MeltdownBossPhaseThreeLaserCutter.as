event void FOnLaserCutterComplete();

class AMeltdownBossPhaseThreeLaserCutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LaserCutter;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;
	default PortalMesh.SetHiddenInGame(true);
	
	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;
	
	FHazeTimeLike PortalAnim;
	default PortalAnim.Duration = 1.0;
	default PortalAnim.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	float Speed = 10;

	UPROPERTY()
	FOnLaserCutterComplete CutterComplete;

	float CurrentSplineDistance;

	float StartDistance;

	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		SetActorTickEnabled(false);

		SplineComp = Spline.Spline;

		PortalAnim.BindFinished(this, n"OnPortalFinished");
		PortalAnim.BindUpdate(this, n"OnPortalUpdate");
	}


	UFUNCTION(BlueprintCallable)
	void StartAttack()
	{
		RemoveActorDisable(this);
		LaserCutter.SetHiddenInGame(true);

		PortalAnim.Play();
		PortalMesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	void OnPortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	void OnPortalFinished()
	{
		if(PortalAnim.IsReversed())
		{
		PortalDone();
		return;
		}

		LaserCutter.SetHiddenInGame(false);
		PortalMesh.DetachFromComponent(EDetachmentRule::KeepWorld);
		PortalAnim.ReverseFromEnd();
	}

	UFUNCTION(BlueprintEvent)
	void PortalDone()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

		float BaseWidth = 100.0;
		FVector2D Width = FVector2D(-1.0, 1.0);
		FVector2D Height = FVector2D(-0.5, 0.5);
		FVector2D Length = FVector2D(-500.0, 0.0);

	//	Debug::DrawDebugBox(DeathTrigger.WorldLocation, DeathTrigger.Shape.BoxExtents, DeathTrigger.WorldRotation, FLinearColor::Red, 10.0);

		if(CurrentSplineDistance >= SplineComp.SplineLength)
		{
			CutterComplete.Broadcast();
		//	AddActorDisable(this);
		}
	}

};