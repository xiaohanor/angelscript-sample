// Trivia: Esca is the name of the "lightbulb" on anglerfishies
class ULightSeekerEmissiveEscaComponent : UActorComponent
{
	access CapabilityAccess = private, ULightSeekerEmissiveEscaCapability;
	access : CapabilityAccess FHazeAcceleratedFloat AccEmissiveEsca;
	access : CapabilityAccess UMaterialInstanceDynamic EmissiveEscaDynamicMaterial = nullptr;
	private ALightSeeker LightSeeker;
	// FLinearColor EscaColor = FLinearColor(1.0, 0.882004, 0.195376, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		SetupEmissiveEscaMaterial();
	}

	private void SetupEmissiveEscaMaterial()
	{
		if (LightSeeker.SkeletalMesh.NumMaterials == 0)
			return;
		EmissiveEscaDynamicMaterial = Material::CreateDynamicMaterialInstance(this, LightSeeker.SkeletalMesh.GetMaterial(0));
		LightSeeker.SkeletalMesh.SetMaterial(0, EmissiveEscaDynamicMaterial);
		EmissiveEscaDynamicMaterial.SetVectorParameterValue(n"EmissiveTint", FLinearColor::Black);
	}
};