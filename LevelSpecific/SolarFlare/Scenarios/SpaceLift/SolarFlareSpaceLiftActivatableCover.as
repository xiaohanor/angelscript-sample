class ASolarFlareSpaceLiftActivatableCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CoverMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFlareCoverOverlapComponent CoverComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	float ZOffsetTarget = 350.0;

	FVector EndRelativeLoc;

	bool bCanBreak;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");	
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");

		EndRelativeLoc = MeshRoot.RelativeLocation + FVector(0.0, 0.0, ZOffsetTarget);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndRelativeLoc, DeltaSeconds, ZOffsetTarget * 2.5);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		SetActorTickEnabled(true);
		DoubleInteract.DisableDoubleInteraction(this);
		bCanBreak = true;
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (!bCanBreak)
			return;

		CoverMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CoverMesh.SetHiddenInGame(true);
		Timer::SetTimer(this, n"DelayedRemoveCover", 0.75);
	}

	UFUNCTION()
	void DelayedRemoveCover()
	{
		CoverComp.AddDisabler(this);
	}
}