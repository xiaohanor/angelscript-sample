enum EIslandGreenDangerShieldPivot
{
	Bottom,
	Center
}

UCLASS(Abstract)
class AIslandGreenDangerShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = CollisionProfile::NoCollision;
	default Mesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UIslandRedBlueStickyGrenadeKillTriggerComponent GrenadeKillTriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent PlayerKillTrigger;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly)
	FPlayerDeathDamageParams DeathDamageParams;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInterface SourceMaterial;

	UPROPERTY(NotVisible, BlueprintHidden)
	UMaterialInstanceDynamic DynMat;

	UPROPERTY(EditAnywhere)
	FVector2D ShieldSize = FVector2D(100.0, 100.0);

	UPROPERTY(EditAnywhere)
	EIslandGreenDangerShieldPivot Pivot;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	bool bEdgeGlowUseVertexColor = false;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Tiling = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Intensity = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Fresnel = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	bool bUseObjectScale = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DynMat = Mesh.CreateDynamicMaterialInstance(0, SourceMaterial);

		ActorScale3D = FVector::OneVector;

		FVector Min, Max;
		Mesh.GetLocalBounds(Min, Max);
		FBox LocalBox = FBox(Min, Max);
		Mesh.RelativeScale3D = FVector(ShieldSize.Y / (LocalBox.Extent.X * 2.0), ShieldSize.X / (LocalBox.Extent.Y * 2.0), 1.0);

		switch(Pivot)
		{
			case EIslandGreenDangerShieldPivot::Bottom:
				Mesh.RelativeLocation = FVector::UpVector * (ShieldSize.Y * 0.5);
				break;
			case EIslandGreenDangerShieldPivot::Center:
				Mesh.RelativeLocation = FVector::ZeroVector;
				break;
		}
			
		GrenadeKillTriggerComp.RelativeLocation = Mesh.RelativeLocation;
		PlayerKillTrigger.RelativeLocation = Mesh.RelativeLocation;

		FBox Box = Mesh.GetBoundingBoxRelativeToOwner();
		GrenadeKillTriggerComp.Shape = FHazeShapeSettings::MakeBox(Box.Extent);
		PlayerKillTrigger.Shape = FHazeShapeSettings::MakeBox(Box.Extent);

		Mesh.SetScalarParameterValueOnMaterials(FName(n"EdgeGlowVertexColor"), bEdgeGlowUseVertexColor ? 1 : 0);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Tiling"), Tiling);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Intensity"), Intensity);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Fresnel"), Fresnel);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"UseObjectScale"), bUseObjectScale ? 1 : 0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerKillTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		Mesh.SetScalarParameterValueOnMaterials(FName(n"EdgeGlowVertexColor"), bEdgeGlowUseVertexColor ? 1 : 0);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Tiling"), Tiling);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Intensity"), Intensity);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"Fresnel"), Fresnel);
		Mesh.SetScalarParameterValueOnMaterials(FName(n"UseObjectScale"), bUseObjectScale ? 1 : 0);
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(DeathDamageParams, DeathEffect);
	}
}