asset DarkCaveSpiritMetalShieldMeltingSettings of UNightQueenMetalMeltingSettings
{
	bOneShotMetal = true;
	MeltingSpeed = 0.3;
	DissolvingSpeed = 1.5;
}

class ADarkCaveSpiritMetalShield : ANightQueenMetal
{
	default CapabilityComp.DefaultCapabilities.Add(n"DarkCaveSpiritMetalMoveCapability");
	
	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UDarkCaveSpiritMetalShieldDud DudVisualizer;
#endif

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface EditorMaterial;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.7);
	default Curve.AddDefaultKey(0.5, 1.0);
	default Curve.AddDefaultKey(1.0, 0.4);

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	default MetalMeltingSettings = DarkCaveSpiritMetalShieldMeltingSettings;

	bool bSendToTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetShieldToStartPosition();
	}

	UFUNCTION(CallInEditor)
	void SetShieldToStartPosition()
	{
		ActorLocation = SplineActor.Spline.GetWorldLocationAtSplineDistance(0.0);
		ActorRotation = SplineActor.Spline.GetWorldRotationAtSplineDistance(0.0).Rotator();
	}
};

#if EDITOR
class UDarkCaveSpiritMetalShieldDud : UActorComponent {}

class UDarkCaveSpriritMetalShieldVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDarkCaveSpiritMetalShieldDud;
	
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UDarkCaveSpiritMetalShieldDud>(Component);
		if(Comp == nullptr)
			return;
		auto MetalShield = Cast<ADarkCaveSpiritMetalShield>(Comp.Owner);
		if(MetalShield == nullptr)
			return;
			
		UHazeSplineComponent SplineComp = MetalShield.SplineActor.Spline;
		FVector EndLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength);
		FRotator EndRotation = SplineComp.GetWorldRotationAtSplineDistance(SplineComp.SplineLength).Rotator();
		EndRotation += MetalShield.MeshRoot.RelativeRotation;
		DrawMeshWithMaterial(MetalShield.MeshComp.StaticMesh, MetalShield.EditorMaterial, EndLocation, EndRotation.Quaternion(), MetalShield.MeshComp.RelativeScale3D);
	}
}
#endif