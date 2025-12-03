class USpotlightVFXRoot : USceneComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ASpotlightVFX SpotlightActor = Cast<ASpotlightVFX>(Owner);
		if(SpotlightActor==nullptr)
		{
			return;
		}
		SpotlightActor.TickAnywhere(DeltaSeconds);
	}
}

class ASpotlightVFX : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USpotlightVFXRoot RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SpotlightMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly, Category = VFX)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere, Category = VFX)
	float Speed = 0.2;

	UPROPERTY(EditAnywhere, Category = VFX)
	float Pitch = 45.0;

	UPROPERTY(EditAnywhere, Category = VFX)
	float SkyHeight = 127500.0;

	UPROPERTY(EditAnywhere, Category = VFX)
	FVector Size = FVector(50.0, 50.0, 500.0);

	UPROPERTY(EditAnywhere, Category = VFX)
	FLinearColor Color = FLinearColor(0.83, 0.91, 0.36);

	UFUNCTION()
	void TickAnywhere(float DeltaTime)
	{
		float Alpha = (Math::Sin(Time::GetGameTimeSeconds() * Speed) + 1.0) * 0.5;
		FRotator LerpToRotation = Math::LerpShortestPath(FRotator(Pitch, 0.0, 0.0), FRotator(-Pitch, 0.0, 0.0), Alpha);
		SpotlightMesh.SetRelativeRotation(LerpToRotation);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SpotlightMesh.CreateDynamicMaterialInstance(0, Material);
		SpotlightMesh.SetVectorParameterValueOnMaterials(n"Color", FVector(Color.R, Color.G, Color.B));
		SpotlightMesh.SetScalarParameterValueOnMaterials(n"SkyOffset", SkyHeight);
		SpotlightMesh.SetRelativeScale3D(Size);
	}
}