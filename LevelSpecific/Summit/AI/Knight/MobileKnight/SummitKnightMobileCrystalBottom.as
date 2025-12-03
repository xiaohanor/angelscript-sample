class USummitKnightMobileCrystalBottom : UStaticMeshComponent
{
	bool bDeployed = true;
	bool bRetracting = false;
	bool bShattered = false;
	uint8 PendingDeployCountdown = 0;
	USceneComponent ParentComp;
	FTransform RelativePosition;
	AHazeActor HazeOwner;
	TArray<FInstigator> Retractors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		ParentComp = AttachParent;
		RelativePosition = RelativeTransform;
		bDeployed = false;
		RemoveComponentVisualsBlocker(this);
		RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION(DevFunction)
	void Deploy(FInstigator Deployer)
	{
		// Only deploy when all agree it can be deployed.
		// Note that when that happens we will recover from being shattered
		Retractors.RemoveSingleSwap(Deployer);
		if (Retractors.Num() > 0)
			return; 
		// Deploy soon, unless countermanded by subsequent retraction
		if (PendingDeployCountdown == 0)
			PendingDeployCountdown = 2;
	}

	UFUNCTION(DevFunction)
	void Retract(FInstigator Deployer)
	{
		Retractors.AddUnique(Deployer);
		PendingDeployCountdown = 0;
		if (!bDeployed)
			return;
		if (bRetracting)
			return;
		bRetracting = true;
		if (!bShattered)
			USummitKnightEventHandler::Trigger_OnCrystalBottomRetract(HazeOwner, FSummitKnightCrystalBottomParams(this));
	}

	UFUNCTION(DevFunction)
	void Shatter()
	{
		if (!bDeployed && (PendingDeployCountdown == 0))
			return;
		bDeployed = false;
		bShattered = true;

		AddComponentVisualsBlocker(this);
		AddComponentCollisionBlocker(this);
		USummitKnightEventHandler::Trigger_OnCrystalBottomShatter(HazeOwner, FSummitKnightCrystalBottomParams(this));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PendingDeployCountdown > 0)
		{
			PendingDeployCountdown--;
			if (PendingDeployCountdown == 0)
			{
				if (bDeployed)
				{
					if (bRetracting)
					{
						// Redeploy while retracting
						bRetracting = false;
						FVector CurScale = RelativeScale3D;
						//WorldTransform = RelativePosition * ParentComp.WorldTransform;
						RelativeScale3D = CurScale;
						USummitKnightEventHandler::Trigger_OnCrystalBottomDeploy(HazeOwner, FSummitKnightCrystalBottomParams(this));
					}
				}
				else
				{
					// New deployment
					bDeployed = true;
					bShattered = false;
					bRetracting = false;
					RemoveComponentVisualsBlocker(this);
					RemoveComponentCollisionBlocker(this);
					WorldTransform = RelativePosition * ParentComp.WorldTransform;
					RelativeScale3D = FVector(0.01);
					USummitKnightEventHandler::Trigger_OnCrystalBottomDeploy(HazeOwner, FSummitKnightCrystalBottomParams(this));
				}
			}
		}

		if (!bDeployed)
			return;

		if (bRetracting) 
		{
			// Withering away
			if (RelativeScale3D.IsNearlyZero(0.01))
			{
				bDeployed = false;
				AddComponentVisualsBlocker(this);
				AddComponentCollisionBlocker(this);
			}
			else
			{
				RelativeScale3D = Math::Lerp(RelativeScale3D, FVector(0.001), Math::Min(1.0, DeltaTime * 1.5));
			}
		}
		else
		{
			// Growing out
			if (!(RelativeScale3D - RelativePosition.Scale3D).IsNearlyZero())
				RelativeScale3D = Math::Lerp(RelativeScale3D, RelativePosition.Scale3D, Math::Min(1.0, DeltaTime * 0.8));
		}
	}
}
