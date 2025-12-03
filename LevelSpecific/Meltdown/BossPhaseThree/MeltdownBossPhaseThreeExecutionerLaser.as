class AMeltdownBossPhaseThreeExecutionerLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Head;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;
	default PortalMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CylinderPortalMesh;
	
	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	UPROPERTY()
	FVector CylinderEndScale;

	FHazeTimeLike PortalAnim;
	default PortalAnim.Duration = 1.0;
	default PortalAnim.UseSmoothCurveZeroToOne();


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PortalAnim.BindFinished(this, n"OnPortalFinished");
		PortalAnim.BindUpdate(this, n"OnPortalUpdate");

		StartScale = PortalMesh.RelativeScale3D;

		AddActorDisable(this);

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void StartAttack()
	{
		RemoveActorDisable(this);

		PortalAnim.Play();
		PortalMesh.SetHiddenInGame(false);

		Timer::SetTimer(this, n"StopAttack", 10.0);
	}

	UFUNCTION()
	private void StopAttack()
	{
		PortalAnim.ReverseFromEnd();
		PokeDown();
	}

	UFUNCTION(BlueprintEvent)
	void PokeDown()
	{

	}

	UFUNCTION()
	private void OnPortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
		CylinderPortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,CylinderEndScale, CurrentValue));
	}

	UFUNCTION()
	private void OnPortalFinished()
	{
		if(PortalAnim.IsReversed())
		AddActorDisable(this);

		StartLaser();
	}

	UFUNCTION(BlueprintEvent)
	void StartLaser()
	{

	}
};