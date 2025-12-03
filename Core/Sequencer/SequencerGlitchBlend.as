struct FScalarParameter
{
	FScalarParameter(FName InName, float InValue)
	{
		this.Name = InName;
		this.Value = InValue;
	}
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	float Value;
}
struct FVectorParameter
{
	FVectorParameter(FName InName, FLinearColor InValue)
	{
		this.Name = InName;
		this.Value = InValue;
	}
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	FLinearColor Value;
}

UCLASS(Abstract, HideCategories = "Rendering Debug Activation Cooking Actor Tags LOD Collision")
class ASequencerGlitchBlend : AActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, ShowOnActor)
	USetMaterialParametersComponent SetMaterialParametersComponent;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SphereMaskMesh;

	UPROPERTY(EditAnywhere)
	UMaterial Char_Skin;

	UPROPERTY(EditAnywhere)
	UMaterial Char_Generic;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Char_Skin_Mio_TwoSided;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Char_Generic_Mio_TwoSided;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Char_Skin_Zoe_TwoSided;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Char_Generic_Zoe_TwoSided;
	
	UPROPERTY(EditAnywhere, Interp)
	AActor Mio;

	UPROPERTY(EditAnywhere, Interp)
	AActor Zoe;
	
	UPROPERTY(EditAnywhere, Interp)
	float BlendMio;

	UPROPERTY(EditAnywhere, Interp)
	float BlendZoe;

	UPROPERTY(EditAnywhere, Interp)
	float PlayerRadius = 120;

	UPROPERTY(EditAnywhere, Interp)
	float DownDistance = 1000;

	UPROPERTY(EditAnywhere, Interp)
	bool bOverrideBorderWidth = false;

	UPROPERTY(EditAnywhere, Interp)
	float BorderWidth = 20;
	
	UPROPERTY(EditAnywhere, Interp)
	AActor AdditionalMioActor;

	UPROPERTY(EditAnywhere, Interp)
	float BlendAdditionalMioActor;

	UPROPERTY(EditAnywhere, Interp)
	FVector BlendDirectionMio = FVector(0, 0, -1);

	UPROPERTY(EditAnywhere, Interp)
	FVector BlendDirectionZoe = FVector(0, 0, -1);

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SeamVFXSystem;
	UNiagaraComponent Seam_VFX_Mio;
	UNiagaraComponent Seam_VFX_Zoe;

	int counter = 0;

	// Called by SetMaterialParametersComponent
	void TickInEditor()
	{
		#if EDITOR

		if(Editor::IsPlaying())
			return;

		counter++;

		if(counter > 30) // hack
		{
			ResetMaterials();
			counter = 0;
		}

		if(BlendMio > 0 || BlendZoe > 0)
		{
			SetMeshParameters(Mio, BlendMio, BlendDirectionMio, Char_Skin_Mio_TwoSided, Char_Generic_Mio_TwoSided, true);
			SetMeshParameters(Zoe, BlendZoe, BlendDirectionZoe, Char_Skin_Zoe_TwoSided, Char_Generic_Zoe_TwoSided, false);
			
			if(AdditionalMioActor != nullptr)
				SetMeshParameters(AdditionalMioActor, BlendAdditionalMioActor, BlendDirectionMio, Char_Skin_Mio_TwoSided, Char_Generic_Mio_TwoSided, true);
			
		}
		else
		{
			Deactivate_VFX_Both();
		}

		#endif
	}

	void ResetMaterials()
	{
		if(Mio == nullptr)
			return;
		if(Zoe == nullptr)
			return;
		UHazeSkeletalMeshComponentBase SkinnedMeshComponentMio = Mio.GetComponentByClass(UHazeSkeletalMeshComponentBase);
		for (int i = 0; i < SkinnedMeshComponentMio.Materials.Num(); i++)
		{
			SkinnedMeshComponentMio.SetMaterial(i, SkinnedMeshComponentMio.GetSkeletalMeshAsset().Materials[i].MaterialInterface);
		}

		UHazeSkeletalMeshComponentBase SkinnedMeshComponentZoe = Zoe.GetComponentByClass(UHazeSkeletalMeshComponentBase);
		for (int i = 0; i < SkinnedMeshComponentZoe.Materials.Num(); i++)
		{
			SkinnedMeshComponentZoe.SetMaterial(i, SkinnedMeshComponentZoe.GetSkeletalMeshAsset().Materials[i].MaterialInterface);
		}
	}

	void InitNiagara()
	{
		if(Mio != nullptr)
		{
			if(Seam_VFX_Mio == nullptr)
			{
				Seam_VFX_Mio = UGlitchBlendNiagaraComponent::GetOrCreate(Mio);
				Seam_VFX_Mio.AttachToComponent(Mio.GetComponentByClass(UHazeSkeletalMeshComponentBase), n"Hips");
				Seam_VFX_Mio.SetAsset(SeamVFXSystem);
				Seam_VFX_Mio.Activate(true);
			}
			else
			{
				Seam_VFX_Mio.Activate();
			}
		}

		if(Zoe != nullptr)
		{
			if(Seam_VFX_Zoe == nullptr)
			{
				Seam_VFX_Zoe = UGlitchBlendNiagaraComponent::GetOrCreate(Zoe);
				Seam_VFX_Zoe.AttachToComponent(Zoe.GetComponentByClass(UHazeSkeletalMeshComponentBase), n"Hips");
				Seam_VFX_Zoe.SetAsset(SeamVFXSystem);
				Seam_VFX_Zoe.Activate(true);
			}
			else
			{
				Seam_VFX_Zoe.Activate();
			}
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResetMaterials();
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		ResetMaterials();
		Deactivate_VFX_Both();
	}

	void Deactivate_VFX_Mio()
	{
		if(Seam_VFX_Mio != nullptr)
		{
			Seam_VFX_Mio.Deactivate();
		}
	}

	void Deactivate_VFX_Zoe()
	{
		if(Seam_VFX_Zoe != nullptr)
		{
			Seam_VFX_Zoe.Deactivate();
		}
	}

	void Deactivate_VFX_Both()
	{
		Deactivate_VFX_Mio();
		Deactivate_VFX_Zoe();
	}

	void SetMeshParameters(AActor Target, float Blend, FVector BlendDirection, UMaterialInterface Char_Skin_TwoSided, UMaterialInterface Char_Generic_TwoSided, bool bIsMio = false, bool affectBorderWidth = true)
	{
		bool bBlending = Blend > 0.0 && Blend < 1.0;
		// Print("Blending." + bBlending);

		if(!bBlending)
			Deactivate_VFX_Both();

		if(Target == nullptr)
			return;
		
		TArray<UHazeSkeletalMeshComponentBase> MeshComponents;
		Target.GetComponentsByClass(UHazeSkeletalMeshComponentBase, MeshComponents);
		for (int k = 0; k < MeshComponents.Num(); k++)
		{
			UHazeSkeletalMeshComponentBase SkinnedMeshComponent = MeshComponents[k];
		
			if(SkinnedMeshComponent == nullptr)
				return;

			// Make the materials twosided.
			for (int i = 0; i < SkinnedMeshComponent.Materials.Num(); i++)
			{
				if(SkinnedMeshComponent.Materials[i] == nullptr)
					continue;

				UMaterialInstanceDynamic DynamicMat = Cast<UMaterialInstanceDynamic>(SkinnedMeshComponent.Materials[i]);

				if(Cast<UMaterialInstanceDynamic>(SkinnedMeshComponent.Materials[i]) != nullptr)
					continue;
				
				if(SkinnedMeshComponent.Materials[i].BaseMaterial == Char_Skin)
				{
					SkinnedMeshComponent.SetMaterial(i, Rendering::CreateRebasedDynamicMaterialInstance(SkinnedMeshComponent.Materials[i], Char_Skin_TwoSided));
				}

				if(SkinnedMeshComponent.Materials[i].BaseMaterial == Char_Generic)
				{
					SkinnedMeshComponent.SetMaterial(i, Rendering::CreateRebasedDynamicMaterialInstance(SkinnedMeshComponent.Materials[i], Char_Generic_TwoSided));
					
				}
			}
			
			FVector Center = SkinnedMeshComponent.GetSocketTransform(n"Hips").GetLocation() + BlendDirection * DownDistance;
			float Radius = (DownDistance - PlayerRadius) + (1.0 - Blend) * PlayerRadius * 2.0;

			//Debug::DrawDebugSphere(Center, Radius, 32, FLinearColor::Red, 1);

			SkinnedMeshComponent.SetVectorParameterValueOnMaterials(n"Glitch_Center", Center);
			SkinnedMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Radius", Radius);
			if(affectBorderWidth)
				SkinnedMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_BorderWidth", 20.0f);
			
			if(bOverrideBorderWidth)
				SkinnedMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_BorderWidth", BorderWidth);

			SkinnedMeshComponent.SetScalarParameterValueOnMaterials(n"Glitch_Blend", Blend);
			SkinnedMeshComponent.SetVectorParameterValueOnMaterials(n"Glitch_BlendDirection", BlendDirection);

			if(bBlending)
			{
				InitNiagara();
				UNiagaraComponent NiagaraComp = bIsMio ? Seam_VFX_Mio : Seam_VFX_Zoe;
				if(NiagaraComp != nullptr)
				{
					float InvBlend = Math::Pow(Math::Saturate(2.0 * (1.0 - Blend)), 1.0);
					FVector SphereCenter = NiagaraComp.GetWorldLocation();
					SphereCenter -= FVector(0, 0, DownDistance);
					float SphereRadius = (DownDistance - PlayerRadius) + InvBlend * PlayerRadius * 2.0;
					NiagaraComp.SetNiagaraVariableVec3("DissolveLocation", SphereCenter);
					NiagaraComp.SetNiagaraVariableFloat("DissolveRadius", SphereRadius);
					NiagaraComp.SetHiddenInGame(false);
					NiagaraComp.SetVisibility(true);
				}
			}
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(BlendMio > 0 || BlendZoe > 0)
		{
			SetMeshParameters(Mio, BlendMio, BlendDirectionMio, Char_Skin_Mio_TwoSided, Char_Generic_Mio_TwoSided, true);
			SetMeshParameters(Zoe, BlendZoe, BlendDirectionZoe, Char_Skin_Zoe_TwoSided, Char_Generic_Zoe_TwoSided, false);
		}
		else
		{
			SetMeshParameters(Mio, 0, BlendDirectionMio, Char_Skin_Mio_TwoSided, Char_Generic_Mio_TwoSided, true, false);
			SetMeshParameters(Zoe, 0, BlendDirectionZoe, Char_Skin_Zoe_TwoSided, Char_Generic_Zoe_TwoSided, false, false);
			Deactivate_VFX_Both();
		}
		
		if(AdditionalMioActor != nullptr)
			SetMeshParameters(AdditionalMioActor, BlendAdditionalMioActor, BlendDirectionMio, Char_Skin_Mio_TwoSided, Char_Generic_Mio_TwoSided, true);
	}
}

class USetMaterialParametersComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Cast<ASequencerGlitchBlend>(Owner).TickInEditor();
	}
};

class UGlitchBlendNiagaraComponent : UNiagaraComponent
{
	default bTickInEditor = true;
	default bAutoActivate = false;
};