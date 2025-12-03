class UDroneOilCoatComponent : UActorComponent
{
	UDecalTrailComponent TrailComp;

	FLinearColor OilColor = FLinearColor(0.02, 0.02, 0.02,0.8);
	FLinearColor CurrentTint;
	FHazeAcceleratedFloat OilAlpha;
	float OilAlphaTarget = 0;

	bool bInitialized = false;
	bool bIsSwarm = false;
	private float OilLeft = 1;
	private const float OilDistance = 1000;
	float DistTraveled = 0;
	private FVector LocationLastFrame;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TrailComp = UDecalTrailComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		StopTrail();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(OilAlpha.Value == OilAlphaTarget)
			return;

		OilAlpha.AccelerateTo(OilAlphaTarget, 1, DeltaTime);
		UpdateMaterials();

		if(bIsSwarm)
			return;
		
		if(OilLeft > 0 && MoveComp != nullptr && MoveComp.HasGroundContact())
		{
			DistTraveled += Owner.ActorLocation.Dist2D(LocationLastFrame);
			OilLeft = 1 - Math::Saturate(DistTraveled / OilDistance);
			LocationLastFrame = Owner.ActorLocation;

			if(OilLeft == 0)
			{
				UDroneOilCoatComponent::Get(Owner).Clean();
			}
		}
	}

	UFUNCTION()
	private void SwarmTransitionStart(bool bSwarmifying)
	{
		if(bSwarmifying)
		{
			bIsSwarm = true;
			StopTrail();
		}
	}

	UFUNCTION()
	private void SwarmTransitionEnd(bool bSwarmActive)
	{
		if(!bSwarmActive)
		{
			bIsSwarm = false;
			if(OilLeft > 0)
				ResumeTrail();
		}
	}

	void ReplenishOil()
	{
		LocationLastFrame = Owner.ActorLocation;
		OilLeft = 1;
		DistTraveled = 0;
		
		if(!bIsSwarm)
			ResumeTrail();
	}

	void Initialize()
	{
		UPlayerSwarmDroneComponent SwarmDrone = UPlayerSwarmDroneComponent::Get(Owner);
		if(SwarmDrone != nullptr)
		{
			SwarmDrone.OnSwarmTransitionStartEvent.AddUFunction(this, n"SwarmTransitionStart");
			SwarmDrone.OnSwarmTransitionCompleteEvent.AddUFunction(this, n"SwarmTransitionEnd");
			bIsSwarm = SwarmDrone.bSwarmModeActive || SwarmDrone.bSwarmTransitionActive;
		}

		bInitialized = true;
	}
	
	void UpdateMaterials()
	{
		CurrentTint = FLinearColor::LerpUsingHSV(FLinearColor::White, OilColor, OilAlpha.Value);

		if(Cast<AHazePlayerCharacter>(Owner).IsMio())
		{
			UPlayerSwarmDroneComponent SwarmDrone = UPlayerSwarmDroneComponent::Get(Owner);
			SwarmDrone.SwarmGroupMeshComponent.SetColorParameterValueOnMaterials(n"Tint", CurrentTint);
		}
		else
		{
			UMagnetDroneComponent MagnetDrone = UMagnetDroneComponent::Get(Owner);
			MagnetDrone.DroneMesh.SetColorParameterValueOnMaterials(n"Tint", CurrentTint);
		}
	}

	void EnterOilPuddle()
	{
		OilAlphaTarget = 1;
		ReplenishOil();

		if(!bInitialized)
		{
			Initialize();
		}

		StopTrail();
	}

	void ExitOilPuddle()
	{
		DistTraveled = 0;
		LocationLastFrame = Owner.ActorLocation;

		if(!bIsSwarm)
			ResumeTrail();
	}

	UFUNCTION(BlueprintCallable)
	void Clean()
	{
		OilAlphaTarget = 0;
		StopTrail();
	}

	void StopTrail()
	{
		TrailComp.SetSpawningEnabled(false);
	}

	void ResumeTrail()
	{
		LocationLastFrame = Owner.ActorLocation;
		TrailComp.SetSpawningEnabled(true);
	}
};