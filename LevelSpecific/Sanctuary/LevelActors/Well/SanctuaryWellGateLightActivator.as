event void FSanctuaryWellGateActivatedSignature();

class ASanctuaryWellGateLightActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY()
	FSanctuaryWellGateActivatedSignature OnActivated;

	UPROPERTY(EditAnywhere)
	float Distance = 600.0;

	UPROPERTY()
	FHazeTimeLike LightProgressTimeLike;
	default LightProgressTimeLike.Duration = 2.0;

	UPROPERTY(EditAnywhere)
	FName ScalarParameter = n"Tiler_A_Specular";

	UPROPERTY(EditAnywhere)
	UMaterialInstance GateMI;
	UMaterialInstanceDynamic GateMID;

	UPROPERTY(EditInstanceOnly)
	TArray<AStaticMeshActor> GateMeshActors;

	FVector InitialLocation;
	UPROPERTY(BlueprintReadOnly)
	FHazeAcceleratedFloat AcceleratedLocation;

	bool bSocketed = false;
	bool bIlluminated = false;
	bool bActivated = false;
	bool bGrabbed = false;
	bool bWasLocationAtStart = true;

	FHazeAcceleratedFloat AcceleratedRotationSpeed;
	float TargetSpeed = 400.0;

	FHazeAcceleratedFloat AcceleratedLightProgress;

	private bool bTriggeredLateBeginPlay = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = ActorLocation;

		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnIlluminated");
		LightProgressTimeLike.BindUpdate(this, n"LightProgressTimeLikeUpdate");
		LightProgressTimeLike.BindFinished(this, n"LightProgressTimeLikeFinished");

		GateMID = Material::CreateDynamicMaterialInstance(this, GateMI);
	}

	private bool IsStreamedIn()
	{
		if (GateMeshActors.IsEmpty())
			return false;
		for (auto GateMeshActor : GateMeshActors)
		{
			if (GateMeshActor == nullptr)
				return false;
		}
		return true;
	}

	private void LateBeginPlay()
	{
		bTriggeredLateBeginPlay = true;
		for (auto GateMeshActor : GateMeshActors)
		{
			GateMeshActor.StaticMeshComponent.SetMaterial(0, GateMID);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bTriggeredLateBeginPlay && IsStreamedIn())
		{
			LateBeginPlay();
		}

		if (bActivated)
		{
			AcceleratedRotationSpeed.AccelerateTo(TargetSpeed, 4.0, DeltaSeconds);
			RotateRoot.AddRelativeRotation(FRotator(0.0, 0.0, AcceleratedRotationSpeed.Value * DeltaSeconds));
		}
		else
		{
			//Calculate Location
			if (bGrabbed)
			{
				bWasLocationAtStart = false;
				AcceleratedLocation.ThrustTo(1.0, 3.0, DeltaSeconds);

				if (!bSocketed && Math::IsNearlyEqual(AcceleratedLocation.Value, 1.0))
					HandleConstraintHit();
			}
			else
			{
				AcceleratedLocation.SpringTo(0.0, 3.0, 0.5, DeltaSeconds);

				bool bIsAtStartNow = Math::IsNearlyEqual(AcceleratedLocation.Value, 0.1, 0.3);
				bool bNotMoving = Math::IsNearlyEqual(AcceleratedLocation.Velocity, 0.1, 0.3);
				if (!bSocketed && !bWasLocationAtStart && bIsAtStartNow && bNotMoving)
				{
					bWasLocationAtStart = true;
					USanctuaryWellGateLightActivatorEventHandler::Trigger_SocketReturnedToStartPosition(this);
				}
			}

			SetActorLocation(InitialLocation + ActorForwardVector * Distance * AcceleratedLocation.Value);
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		bIlluminated = true;
	
		if (bSocketed)
		{
			USanctuaryWellGateLightActivatorEventHandler::Trigger_StartedActivation(this);
			LightProgressTimeLike.Play();
		}	
	}

	UFUNCTION()
	private void HandleUnIlluminated()
	{
		if (bActivated)
			return;

		bIlluminated = false;
		LightProgressTimeLike.Reverse();
	}

	UFUNCTION()
	private void HandleConstraintHit()
	{
		bSocketed = true;
		USanctuaryWellGateLightActivatorEventHandler::Trigger_SocketInDoor(this);

		if (bIlluminated)
			LightProgressTimeLike.Play();
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (HasControl())
			CrumbGrabbed();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbGrabbed()
	{
		bGrabbed = true;
		USanctuaryWellGateLightActivatorEventHandler::Trigger_SocketGrabbedMovingTowardsDoor(this);
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (HasControl())
			CrumbReleased();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReleased()
	{
		if (bActivated)
			return;
	
		USanctuaryWellGateLightActivatorEventHandler::Trigger_SocketReleasedMovingToStartPosition(this);
		bGrabbed = false;
		bSocketed = false;
		LightProgressTimeLike.Reverse();
	}

	UFUNCTION()
	private void LightProgressTimeLikeUpdate(float CurrentValue)
	{
		GateMID.SetScalarParameterValue(ScalarParameter, CurrentValue * 950.0);
	}

	UFUNCTION()
	private void LightProgressTimeLikeFinished()
	{
		if (!LightProgressTimeLike.IsReversed() && HasControl())
			CrumbDoorActivated();
		USanctuaryWellGateLightActivatorEventHandler::Trigger_LightProgressTimeLikeFinished(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDoorActivated()
	{
		bActivated = true;
		OnActivated.Broadcast();
		USanctuaryWellGateLightActivatorEventHandler::Trigger_BothAbilitiesActivatedSuccess(this);
	}
};