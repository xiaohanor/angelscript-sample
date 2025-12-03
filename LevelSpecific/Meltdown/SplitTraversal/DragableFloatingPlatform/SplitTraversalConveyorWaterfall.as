event void FSplitTraversalOnAttachedToTopWater();

class ASplitTraversalConveyorWaterfall : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent CurrentRoot;

	UPROPERTY(DefaultComponent, Attach = CurrentRoot)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent FloatingPlatformAttachmentRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UNiagaraComponent WaterfallVFXComp;

	UPROPERTY()
	UMaterialInterface WaterMaterial;

	UPROPERTY()
	UMaterialInterface ConveyorMaterial;

	UMaterialInstanceDynamic WaterMID;

	UMaterialInstanceDynamic ConveyorMID;

	UPROPERTY(EditInstanceOnly)
	APlayerSwimmingCurrentVolume CurrentVolume;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalWaterTop TopWater;

	FSplitTraversalOnAttachedToTopWater OnAttachedToTopWater;

	FHazeAcceleratedFloat AcceleratedPanningSpeed;
	float PanningSpeed = 0.0;

	bool bCurrentActivated = false;
	bool bCurrentReversed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FantasyRoot.SetHiddenInGame(true, true);

		WaterMID = Material::CreateDynamicMaterialInstance(this, WaterMaterial);
		ConveyorMID = Material::CreateDynamicMaterialInstance(this, ConveyorMaterial);

		TArray<USceneComponent> ScifiChildren;
		ScifiRoot.GetChildrenComponents(true, ScifiChildren);
		
		for (auto ChildComp : ScifiChildren)
		{
			auto Mesh = Cast<UStaticMeshComponent>(ChildComp);

			if (Mesh != nullptr)
				Mesh.SetMaterial(0, ConveyorMID);
		}

		TArray<USceneComponent> FantasyChildren;
		FantasyRoot.GetChildrenComponents(true, FantasyChildren);
		
		for (auto ChildComp : FantasyChildren)
		{
			auto Mesh = Cast<UStaticMeshComponent>(ChildComp);

			if (Mesh != nullptr)
				Mesh.SetMaterial(0, WaterMID);
		}

		WaterMID.SetScalarParameterValue(n"ScrollingSpeedTop", 0.0);
		ConveyorMID.SetScalarParameterValue(n"PanningY", 0.0);

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
			OnAttachedToTopWater.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//AcceleratedPanningSpeed.AccelerateTo(PanningSpeed, 2.0, DeltaSeconds);
		WaterMID.SetScalarParameterValue(n"ScrollingSpeedTop", PanningSpeed);
		ConveyorMID.SetScalarParameterValue(n"PanningY", PanningSpeed);
	}

	UFUNCTION()
	void FloatingPlatformAttached()
	{
		ForceComp.Force = FVector::ForwardVector * 1000.0;
	}

	UFUNCTION()
	void Activate()
	{
		BP_Activate();
		FantasyRoot.SetHiddenInGame(false, true);
		PanningSpeed = 0.3;
		WaterfallVFXComp.Activate();
	}

	UFUNCTION()
	void SwitchCurrent()
	{
		BP_SwitchCurrent();
		CurrentVolume.CurrentStrength = -500;
		PanningSpeed = -0.3;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate()
	{}

	UFUNCTION(BlueprintEvent)
	private void BP_SwitchCurrent()
	{}
};