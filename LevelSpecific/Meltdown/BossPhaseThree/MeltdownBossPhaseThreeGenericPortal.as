event void FOnPortalOpen();

class AMeltdownBossPhaseThreeGenericPortal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	FVector StartScale;

	UPROPERTY(EditAnywhere)
	FVector EndScale;

	FHazeTimeLike OpenGenericPortal;
	default OpenGenericPortal.Duration = 2.0;
	default OpenGenericPortal.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FOnPortalOpen PortalOpen;

	UPROPERTY(EditAnywhere)
	bool bShouldClose;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenGenericPortal.BindFinished(this, n"PortalFinshed");
		OpenGenericPortal.BindUpdate(this, n"PortalUpdate");

		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintCallable)
	void ActivatePortal()
	{
		SetActorHiddenInGame(false);
		OpenGenericPortal.Play();
	}

	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	private void PortalFinshed()
	{
		if(OpenGenericPortal.IsReversed())
		{
		AddActorDisable(this);
		return;
		}

		PortalOpen.Broadcast();

		if(bShouldClose)
		OpenGenericPortal.Reverse();

	}
};