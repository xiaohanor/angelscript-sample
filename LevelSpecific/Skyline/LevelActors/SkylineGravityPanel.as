event void FSkylineGravityPanelSignature();

class ASkylineGravityPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleComponent GravityBladeGrappleComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleResponseComponent GravityBladeGrappleResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityBladeGravityShiftComponent;

	UPROPERTY(DefaultComponent)
	USkylinePlayerProximityComponent PlayerProximityComponent;
	default PlayerProximityComponent.bCanMioUse = true;
	default PlayerProximityComponent.ProximityRange = 3500.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	int ElementIndex = 0;

	UPROPERTY(EditAnywhere)
	FName MaterialParameter = n"EmissiveTint";

	FLinearColor InitialParamaterValue;

	UPROPERTY(EditAnywhere)
	float TransitionTime = 1.0;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	float TransitionTarget = 0.0;

	TArray<UMaterialInstanceDynamic> MIDs;

	FHazeAcceleratedFloat ParameterAlpha;

	UPROPERTY(EditAnywhere)
	AActor GrappleSurface;

	UPROPERTY()
	FSkylineGravityPanelSignature OnGravityShifted;

	UPROPERTY()
	FSkylineGravityPanelSignature OnPullStart;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	/*
		if (GravityBladeGrappleComponent.TargetShape.Type == EHazeShapeType::Box)
		{
			GravityBladeGrappleComponent.TargetShape.BoxExtents.Z = 1.0;
			GravityBladeGrappleComponent.RelativeLocation = FVector::UpVector * 10.0;
		}
	*/
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (GrappleSurface != nullptr)
		{
			PlayerProximityComponent = USkylinePlayerProximityComponent::Get(GrappleSurface);
			if (PlayerProximityComponent != nullptr)
			{
				PlayerProximityComponent.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnterProximity");
				PlayerProximityComponent.OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeaveProximity");
			}

			if (bStartDisabled)
				AddDisabler(this);
		}

		GravityBladeGrappleResponseComponent.OnPullStart.AddUFunction(this, n"HandlePullStart");
		GravityBladeGrappleResponseComponent.OnPullEnd.AddUFunction(this, n"HandlePullEnd");

		PlayerProximityComponent.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnterProximity");
		PlayerProximityComponent.OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeaveProximity");

		TMap<UMaterialInterface, UMaterialInstanceDynamic> MaterialMap;
		TArray<UStaticMeshComponent> StaticMeshComponents;
		GetComponentsByClass(StaticMeshComponents);
		for (auto StaticMeshComponent : StaticMeshComponents)
		{
			auto Material = StaticMeshComponent.GetMaterial(ElementIndex);

			UMaterialInstanceDynamic MID;
			if (!MaterialMap.Find(Material, MID))
			{
				MID = Material::CreateDynamicMaterialInstance(this, Material);
				MaterialMap.Add(Material, MID);
			}

			// Nja
			InitialParamaterValue = MID.GetVectorParameterValue(MaterialParameter);

			StaticMeshComponent.SetMaterial(ElementIndex, MID);
		}
	
		for (auto Elem : MaterialMap)
			MIDs.Add(Elem.Value);
	
		// Debug
	//	PrintToScreen("NumOfMIDs: " + MIDs.Num(), 3.0, FLinearColor::Green);	
	}

	UFUNCTION()
	private void HandlePullStart(UGravityBladeGrappleUserComponent GrappleComp)
	{
		OnPullStart.Broadcast();
	}

	UFUNCTION()
	private void HandlePullEnd(UGravityBladeGrappleUserComponent GrappleComp)
	{
		OnGravityShifted.Broadcast();
	}

	UFUNCTION()
	private void HandlePlayerEnterProximity(AHazePlayerCharacter Player)
	{
		// PrintToScreen("GravityPanel: " + Name + " in range.", 2.0, FLinearColor::Green);	
		TransitionTarget = 1.0;
	}

	UFUNCTION()
	private void HandlePlayerLeaveProximity(AHazePlayerCharacter Player)
	{
		// PrintToScreen("GravityPanel: " + Name + " out of range.", 2.0, FLinearColor::Green);	
		TransitionTarget = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ParameterAlpha.AccelerateTo(TransitionTarget, TransitionTime, DeltaSeconds);
	
		FLinearColor ParameterValue = Math::Lerp(InitialParamaterValue * 0.0, InitialParamaterValue * 30.0, ParameterAlpha.Value);

	//	ParameterValue = FLinearColor::Green * 500.0;

//		PrintToScreen("ParameterValue: " + ParameterValue, 0.0, FLinearColor::Green);	

		for (auto MID : MIDs)
			MID.SetVectorParameterValue(MaterialParameter, ParameterValue);
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		GravityBladeGrappleComponent.Disable(DisableInstigator);

		PlayerProximityComponent.bCanMioUse = false;

//		if (DisableInstigators.Num() == 0)

//		DisableInstigators.Add(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		GravityBladeGrappleComponent.Enable(DisableInstigator);

//		DisableInstigators.Remove(DisableInstigator);

//		if (DisableInstigators.Num() == 0)
	}

	UFUNCTION()
	void RemoveAllDisablers()
	{

//		if (DisableInstigators.Num() > 0)

//		DisableInstigators.Reset();
	}
}