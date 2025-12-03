event void FDoneJumping();

class AMeltdownBossPhaseThreeWalkerSmash : AHazeCharacter
{
	UPROPERTY()
	bool bCanDamage;

	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	UPROPERTY(DefaultComponent)
	UDecalComponent Telelegraph;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY()
	FDoneJumping DoneJumping;

	UPROPERTY()
	FHazeTimeLike Portal;
	default Portal.Duration = 1;
	default Portal.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		StartScale = PortalMesh.RelativeScale3D;

		Telelegraph.SetHiddenInGame(true);


	}

	UFUNCTION()
	void StartAttack()
	{
		RemoveActorDisable(this);

		Portal.BindFinished(this, n"PortalOpen");
		Portal.BindUpdate(this, n"PortalOpening");

		Portal.Play();
	}

	UFUNCTION()
	private void PortalOpening(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalOpen()
	{
		if(Portal.IsReversed())
		return;
	
		Mesh.SetHiddenInGame(false);
		Timer::SetTimer(this, n"StartDrop", 3.0);
		Telelegraph.SetHiddenInGame(false);
	}

	
	UFUNCTION(BlueprintEvent)
	private void StartDrop()
	{
	
	}

	UFUNCTION(BlueprintCallable)
	void DoneWithJump()
	{
		DoneJumping.Broadcast();
	}
};