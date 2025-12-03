
// needed in order to tick whilte in editor (sequencer preview)
class USequencerWardrobeChangeRoot : USceneComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Owner == nullptr)
			return;

		ASequencerWardrobeChangeActor OwnerWardrobe =  Cast<ASequencerWardrobeChangeActor>(Owner);
		if(OwnerWardrobe != nullptr)
			OwnerWardrobe.TickInEditor(DeltaSeconds);

		ASequencerDissolveSkeletalMeshActor OwnerDissolveSkeletalMesh =  Cast<ASequencerDissolveSkeletalMeshActor>(Owner);
		if(OwnerDissolveSkeletalMesh != nullptr)
			OwnerDissolveSkeletalMesh.TickInEditor(DeltaSeconds);
	}
}

class ASequencerWardrobeChangeActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USequencerWardrobeChangeRoot RootComp;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh_Start;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh_End;

	UPROPERTY(DefaultComponent, Attach = Mesh_End)
	UNiagaraComponent Seam_VFX;

	// --------------------------

	UPROPERTY(EditAnywhere, Interp, Category = "Blend", Meta = (UIMin = 0, UIMax = 3))
	float BlendAlpha = 0;

	UPROPERTY(EditAnywhere, Interp, Category = "Blend")
	float BlendMaxRadius = 215;

	UPROPERTY(EditAnywhere, Interp, Category = "Blend")
	FVector BlendWorldLocationOffset = FVector(0, 0, -130);		// -100

	UPROPERTY(EditAnywhere, Interp, Category = "Blend")
	FVector BlendDirection = FVector(0, 0, 1);

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bWorldSpaceBlendDirection = false;

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bUpdateInEditor = true;

	void TickInEditor(const float Dt)
	{
		//PrintToScreen("BlendValue: " + BlendAlpha);

		if (bUpdateInEditor || World.IsGameWorld())
		{
			BlendAlpha = (Time::GetGameTimeSeconds() * 0.2333) % 2.0;
			UpdateBlendRadius();
		}

		// Mesh_Start.SetVisibility(BlendAlpha < 1.0);
		// Mesh_Start.SetHiddenInGame(BlendAlpha > 1.0);
	}

	void UpdateBlendRadius()
	{
		FBoxSphereBounds Bounds = Mesh_End.GetBounds();
		// Debug::DrawDebugBox(Bounds.Origin, Bounds.BoxExtent, LineColor = FLinearColor::Red);
		// Debug::DrawDebugSphere(Bounds.Origin, Bounds.SphereRadius, LineColor = FLinearColor::Blue);
		// Debug::DrawDebugPoint(Bounds.Origin, 200, FLinearColor::Red);

		FTransform DissolveTM = Mesh_Start.GetSocketTransform(n"Hips");
		DissolveTM.AddToTranslation(BlendWorldLocationOffset);

		// Mesh_Start.SetScalarParameterValueOnMaterials(n"DissolveRadius", 10000);
		// Mesh_End.SetScalarParameterValueOnMaterials(n"DissolveRadius", 10000);

		// START MESH
		// Mesh_Start.SetVectorParameterValueOnMaterials(n"DissolveEpicenter", DissolveTM.GetLocation());
		// Mesh_Start.SetScalarParameterValueOnMaterials(n"DissolveRadius", BlendRadius);
		// Mesh_Start.SetScalarParameterValueOnMaterials(n"DissolveHardness", -100.0);

		// END MESH
		// Mesh_End.SetVectorParameterValueOnMaterials(n"DissolveEpicenter", DissolveTM.GetLocation());
		// Mesh_End.SetScalarParameterValueOnMaterials(n"DissolveRadius", BlendRadius);
		// Mesh_End.SetScalarParameterValueOnMaterials(n"DissolveHardness", -100.0);

		//DebugResetBlends();

		// VFX between the blend
		Seam_VFX.SetWorldTransform(DissolveTM);
		Seam_VFX.SetNiagaraVariableFloat("DissolveRadius", Bounds.SphereRadius);
		Seam_VFX.SetNiagaraVariableVec3("DissolveLocation", Bounds.Origin);

		const float PoweredBlendAlpha = Math::Pow(BlendAlpha, 1.0) * 0.5;
		Seam_VFX.SetNiagaraVariableFloat("DissolveAlpha", PoweredBlendAlpha);

		FVector WhiteSpaceBlendDirection = BlendDirection;
		if(!bWorldSpaceBlendDirection)
			WhiteSpaceBlendDirection = Mesh_End.WorldTransform.TransformVector(BlendDirection);
		WhiteSpaceBlendDirection.Normalize();
		WhiteSpaceBlendDirection *= 1.0;

		Seam_VFX.SetNiagaraVariableVec3("DissolveBlendDirection", -WhiteSpaceBlendDirection);

		// BlendAlpha = 0;
		UpdateWhiteSpaceBlend(Mesh_End, false);
		UpdateWhiteSpaceBlend(Mesh_Start, true);
	}

	UFUNCTION()
	void UpdateWhiteSpaceBlend(UHazeCharacterSkeletalMeshComponent Mesh, bool bFlip = true)
	{
		// Mesh.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);
		// return;

		const float PoweredBlendAlpha = Math::Pow(BlendAlpha, 1.0) * 0.5;
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Blend", PoweredBlendAlpha);

		FBoxSphereBounds Bounds = Mesh_End.GetBounds();

		Mesh.SetVectorParameterValueOnMaterials(n"WardrobeEpicenter", Bounds.Origin);
		Mesh.SetScalarParameterValueOnMaterials(n"WardrobeRadius", Bounds.SphereRadius);

		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Flip", bFlip ? 1.0 : 0.0);

		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_GradientWidth", 0.1333);

		FVector WhiteSpaceBlendDirection = BlendDirection;
		if(!bWorldSpaceBlendDirection)
			WhiteSpaceBlendDirection = Mesh.WorldTransform.TransformVector(BlendDirection);
		WhiteSpaceBlendDirection.Normalize();
		WhiteSpaceBlendDirection *= 1.0;

		Mesh.SetVectorParameterValueOnMaterials(n"Whitespace_Direction", WhiteSpaceBlendDirection);

		Mesh.SetVectorParameterValueOnMaterials(n"Whitespace_Position", Mesh.GetBoundsOrigin());
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Radius", Mesh.GetBoundsRadius());



	}

	void DebugResetBlends()
	{
		Mesh_Start.SetVectorParameterValueOnMaterials(n"DissolveEpicenter", FVector::ZeroVector);
		Mesh_Start.SetScalarParameterValueOnMaterials(n"DissolveRadius", 0);
		Mesh_Start.SetScalarParameterValueOnMaterials(n"DissolveHardness", 0.0);

		// END MESH
		Mesh_End.SetVectorParameterValueOnMaterials(n"DissolveEpicenter", FVector::ZeroVector);
		Mesh_End.SetScalarParameterValueOnMaterials(n"DissolveRadius", 0);
		Mesh_End.SetScalarParameterValueOnMaterials(n"DissolveHardness", 0.0);
	}

}

class ASequencerDissolveSkeletalMeshActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USequencerWardrobeChangeRoot RootComp;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;
	
	UPROPERTY(EditAnywhere, Interp, Category = "Blend", Meta = (UIMin = 0, UIMax = 1))
	float BlendAlpha = 0;

	UPROPERTY(EditAnywhere, Interp, Category = "Blend")
	FVector BlendDirection = FVector(0, 0, 1);

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bWorldSpaceBlendDirection = false;

	void TickInEditor(const float Dt)
	{
		// const float Time = Time::GetGameTimeSeconds() * 0.1;
		// BlendAlpha = Math::Frac(Time);
		// PrintToScreen("BlendAlpha: " + BlendAlpha);

		UpdateBlendRadius();
	}

	void UpdateBlendRadius()
	{
		if(Mesh == nullptr)
			return;

		bool bFlip = false;
		const float PoweredBlendAlpha = Math::Pow(BlendAlpha, 1.0) * 0.5;
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Blend", PoweredBlendAlpha);
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Flip", bFlip ? 1.0 : 0.0);
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_GradientWidth", 0.1333);

		FVector WhiteSpaceBlendDirection = BlendDirection;
		if(!bWorldSpaceBlendDirection)
			WhiteSpaceBlendDirection = Mesh.WorldTransform.TransformVector(BlendDirection);
		WhiteSpaceBlendDirection.Normalize();
		WhiteSpaceBlendDirection *= 1.0;
		
		Mesh.SetVectorParameterValueOnMaterials(n"Whitespace_Direction", WhiteSpaceBlendDirection);
		Mesh.SetVectorParameterValueOnMaterials(n"Whitespace_Position", Mesh.GetBoundsOrigin());
		Mesh.SetScalarParameterValueOnMaterials(n"Whitespace_Radius", Mesh.GetBoundsRadius());
	}
}