class ATundra_River_BridgeTreeInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraGroundedLifeReceivingTargetableComponent LifeReceivingTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RootsMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ClimbRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RootsGrowTimeLike;

	UPROPERTY(EditInstanceOnly)
	ASplineFollowCameraActor SplineCamera;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> BridgeElements;

	bool bIsBeingInteractedWith;
	bool bUpInteractionsActive = false;
	bool bDownInteractionsActive = false;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_River_BridgeObstacles> UpInteractions;
	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_River_BridgeObstacles> DownInteractions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeReceivingComp.OnInteractStart.AddUFunction(this, n"HandleInteractionStart");
		LifeReceivingComp.OnInteractStop.AddUFunction(this, n"HandleInteractionStopped");
		RootsGrowTimeLike.BindUpdate(this, n"RootsGrowUpdate");
		RootsGrowTimeLike.BindFinished(this, n"RootsGrowFinished");

		RootsMesh.SetRelativeScale3D(FVector(1,0.001,0.001));
		ClimbRoot.SetRelativeScale3D(FVector(0.001,0.001,0.001));
		
		ToggleBridgeElements(false);
	}

	UFUNCTION()
	private void RootsGrowFinished()
	{
		if(RootsGrowTimeLike.Position == 1)
		{
			ToggleBridgeElements(true);
		}
		else
		{
			ToggleBridgeElements(false);
			ClimbRoot.SetRelativeScale3D(FVector(0.001,0.001,0.001));
		}
	}

	UFUNCTION()
	private void RootsGrowUpdate(float CurrentValue)
	{
		RootsMesh.SetRelativeScale3D(FVector(1, CurrentValue, CurrentValue));
		ClimbRoot.SetRelativeScale3D(FVector(1, 1, CurrentValue));
	}

	UFUNCTION()
	private void ToggleBridgeElements(bool bEnable)
	{
		if(bEnable)
		{
			for(auto Element : BridgeElements)
			{
				Element.RemoveActorDisable(this);
			}
		}
		else
		{
			for(auto Element : BridgeElements)
			{
				Element.AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	private void HandleInteractionStopped(bool bForced)
	{
		Game::GetZoe().DeactivateCameraByInstigator(this, 2);

		RootsGrowTimeLike.Reverse();
		
		CrumbDeactivateDownInteractions();
		CrumbDeactivateUpInteractions();

		bIsBeingInteractedWith = false;
	}

	UFUNCTION()
	private void HandleInteractionStart(bool bForced)
	{
		Game::GetZoe().ActivateCamera(SplineCamera, 5, this, EHazeCameraPriority::High);

		RootsGrowTimeLike.Play();

		bIsBeingInteractedWith = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl() && bIsBeingInteractedWith)
		{
			if(LifeReceivingComp.RawVerticalInput > 0.5 && !bUpInteractionsActive)
			{
				bUpInteractionsActive = true;
				CrumbActivateUpInteractions();
			}
			else if(LifeReceivingComp.RawVerticalInput <= 0.5 && bUpInteractionsActive)
			{
				bUpInteractionsActive = false;
				CrumbDeactivateUpInteractions();
			}

			if(LifeReceivingComp.RawVerticalInput < -0.5 && !bDownInteractionsActive)
			{
				bDownInteractionsActive = true;
				CrumbActivateDownInteractions();
			}
			else if(LifeReceivingComp.RawVerticalInput >= -0.5 && bDownInteractionsActive)
			{
				bDownInteractionsActive = false;
				CrumbDeactivateDownInteractions();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateUpInteractions()
	{
		for(auto Interaction : UpInteractions)
		{
			Interaction.Grow();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactivateUpInteractions()
	{
		for(auto Interaction : UpInteractions)
		{
			Interaction.Shrink();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateDownInteractions()
	{
		for(auto Interaction : DownInteractions)
		{
			Interaction.Grow();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactivateDownInteractions()
	{
		for(auto Interaction : DownInteractions)
		{
			Interaction.Shrink();
		}
	}
};