
// holds data about a sphere mask attached to a mesh
struct FAcidImpactComponentParams
{
	// Attachment data
	UMeshComponent MeshRelativeTo;
	FName BoneName;

	// which is the Hit.ImpactLocation, for the acid projectile that hit the mesh.
	FVector RelativeLocation;

	// the normalized velocity of the projectile that hit the mesh and spawned this sphere mask
	FVector NormalizedImpactVelocity;

	/////////////////////////////////
	// Sphere mask expansion data
	FHazeAcceleratedFloat AccSphereMaskRadius;
	float MaxExpansionRadius;
	float ExpansionDuration;
	float CurrentExpansionSpeed;

	float DissolveDuration;
	/////////////////////////////////

	bool bNightQueenMetal = false;

	void UpdateSphereMask(const float Dt, const float MaxRadScaler)
	{
		const float Target = MaxExpansionRadius * MaxRadScaler;
		AccSphereMaskRadius.AccelerateToWithStop(Target, ExpansionDuration, Dt, 1.0);
		CurrentExpansionSpeed = AccSphereMaskRadius.Velocity;
		// DrawDebug();
	}

	FTransform GetRelativeBoneTransform() const
	{
		return MeshRelativeTo.GetSocketTransform(BoneName);
	}

	FVector GetWorldLocation () const
	{
		// return GetRelativeBoneTransform().TransformPositionNoScale(RelativeLocation);
		return GetRelativeBoneTransform().TransformPosition(RelativeLocation);
	}

	void DrawDebug()
	{
#if EDITOR
		Debug::DrawDebugSphere(GetWorldLocation (), AccSphereMaskRadius.Value, 12, FLinearColor::Yellow);
		// Debug::DrawDebugSphere(GetWorldLocation (), 200, 12, FLinearColor::Yellow);
#endif
	}

}

struct FAcidImpactActorParams
{
	// Sphere Masks currently affecting one (or more mesh components) on the actor
	TArray<FAcidImpactComponentParams> ComponentParams;

	void UpdateSphereMasks(const float DeltaTime, const float MaxRadScaler = 1.0)
	{
		devCheck(MeltRadiuses.Num() <= ComponentParams.Num());

		for(int i = 0; i < ComponentParams.Num(); ++i)
		{
			auto& CompMaskParams = ComponentParams[i];
			CompMaskParams.UpdateSphereMask(DeltaTime, MaxRadScaler);
		}
	}

	// ----------------------------------------------------------------------------
	// @TODO: Most of this data need to be be in the struct above  

	// Niagara melting acid VFX for this mesh component
	UNiagaraComponent EffectComponent;

	// Array of structs sent to niagara for all 8 sphere masks. 
	TArray<float32> MeltRadiuses;
	TArray<float32> MeltMaxRadiuses;
	TArray<float32> MeltDurations; 
	TArray<float32> MeltSpeeds; 
	TArray<float32> DissolveDurations; 
	TArray<FVector> RelativeAcidImpactLocations; 
	TArray<FVector> WorldAcidImpactLocations; 
	TArray<FVector> AcidImpactVelocityDirs; 
	// ----------------------------------------------------------------------------

	// Whether we are update the Overlay material on the mesh. 'The green goo shader'
	bool bUpdateOverlay = false;

	// boss fix hack 
	bool bSpawnFinisherVFX = true;

	// this makes sense atm because a night queen metal means that the entire actor only has 1 mesh.
	// if this assumption changes we'll have to put this bool in the ComponentParams.
	bool bNightQueenMetal = false;

	// keep track of when this actor was hit
	float TimeStampLastMeltHit = -1.0;

	float GetBlastRadius() const
	{
		float FinisherBlastRadius = 0.0;
		for(const auto& IterCompParam : ComponentParams)
		{
			if(IterCompParam.AccSphereMaskRadius.Value > FinisherBlastRadius)
			{
				FinisherBlastRadius = IterCompParam.AccSphereMaskRadius.Value;
			}
		}
		FinisherBlastRadius *= 2.0;
		// FinisherBlastRadius = 4000.0;

		return FinisherBlastRadius;
	}

	void SpawnMeltFinisher(UNiagaraSystem MeltFinisher_StaticMesh, UNiagaraSystem MeltFinisher_SkeletalMesh)
	{
		if(bSpawnFinisherVFX == false)
			return;

		if(bNightQueenMetal)
		{
			SpawnMeltFinisherForStaticMesh(MeltFinisher_StaticMesh);
		}
		else
		{
			SpawnMeltFinisherForSkeletalMesh(MeltFinisher_SkeletalMesh);
		}
	}

	private void SpawnMeltFinisherForStaticMesh(UNiagaraSystem MeltFinisher_StaticMesh)
	{
		if(MeltFinisher_StaticMesh == nullptr)
			return;

		// gather all static meshes for this actor.
		TArray<UStaticMeshComponent> StaticMeshes;
		for(const auto& CompParam : ComponentParams)
		{
			const auto StaticMesh = Cast<UStaticMeshComponent>(CompParam.MeshRelativeTo);
			if(StaticMesh != nullptr)
			{
				StaticMeshes.AddUnique(StaticMesh);
			}
		}

		// spawn finish vfx on affected meshes
		if(StaticMeshes.IsEmpty())
			return;

		const float BlastRad = GetBlastRadius();

		const float TimeSinceHit = Time::GetGameTimeSince(TimeStampLastMeltHit);
		const bool bSpraying = TimeSinceHit < 0.1;

		for(auto IterMesh : StaticMeshes)
		{
			auto VFX_DissolveStaticMeshFinish = Niagara::SpawnOneShotNiagaraSystemAttached(
				MeltFinisher_StaticMesh, 
				IterMesh
			);

			// Print("Spraying? " + bSpraying);
			VFX_DissolveStaticMeshFinish.SetVariableBool(n"Spraying", bSpraying);
			VFX_DissolveStaticMeshFinish.SetVariableFloat(n"InitialDissolveTargetRadius", BlastRad);
			// Debug::DrawDebugSphere( VFX_DissolveFinish.GetWorldLocation(), FinisherBlastRadius, Duration = 3.0);
		}
	}

	private void SpawnMeltFinisherForSkeletalMesh(UNiagaraSystem MeltFinisher_SkeletalMesh)
	{
		if(MeltFinisher_SkeletalMesh == nullptr)
			return;

		// gather all skellies for this actor.
		TArray<UHazeSkeletalMeshComponentBase> Skellies;
		for(const auto& CompParam : ComponentParams)
		{
			const auto Skelly = Cast<UHazeSkeletalMeshComponentBase>(CompParam.MeshRelativeTo);
			if(Skelly != nullptr)
			{
				Skellies.AddUnique(Skelly);
			}
		}

		// spawn finish vfx on affected skellies
		if(Skellies.IsEmpty())
			return;

		const float BlastRad = GetBlastRadius();

		for(UHazeSkeletalMeshComponentBase Skelly : Skellies)
		{
			auto VFX_DissolveSkellyFinish = Niagara::SpawnOneShotNiagaraSystemAttached(
				MeltFinisher_SkeletalMesh, 
				Skelly
			);

			VFX_DissolveSkellyFinish.SetVariableFloat(n"InitialDissolveTargetRadius", BlastRad);
			// Debug::DrawDebugSphere( VFX_DissolveFinish.GetWorldLocation(), FinisherBlastRadius, Duration = 3.0);
		}
	}

	void SendDataToNiagara(const float Dt, bool bBossHacks = false)
	{
		if(EffectComponent == nullptr)
			return;

		// airborne projectiles that might hit the target
		//bool bIncomingProjectiles = Acid::GetAcidManager().Projectiles.Num() > 0;

		// Reset every frame for now.
		MeltRadiuses.Reset();
		MeltMaxRadiuses.Reset();
		MeltDurations.Reset(); 
		MeltSpeeds.Reset(); 
		DissolveDurations.Reset(); 
		RelativeAcidImpactLocations.Reset(); 
		WorldAcidImpactLocations.Reset(); 
		AcidImpactVelocityDirs.Reset(); 

		devCheck(MeltRadiuses.Num() <= ComponentParams.Num());

		// consolodate the data into the form that niagara wants.
		for(int i = 0; i < ComponentParams.Num(); ++i)
		{
			auto& IterSphere = ComponentParams[i];
		
			MeltRadiuses.Add(IterSphere.AccSphereMaskRadius.Value);
			MeltMaxRadiuses.Add(float32(IterSphere.MaxExpansionRadius));
			MeltDurations.Add(float32(IterSphere.ExpansionDuration));
			MeltSpeeds.Add(float32(IterSphere.CurrentExpansionSpeed));
			DissolveDurations.Add(float32(IterSphere.DissolveDuration));
			RelativeAcidImpactLocations.Add(IterSphere.RelativeLocation);
			WorldAcidImpactLocations.Add(IterSphere.GetWorldLocation());
			AcidImpactVelocityDirs.Add(IterSphere.NormalizedImpactVelocity);
		}

		// temp: test out the system with only 1 sphere.
		if(MeltRadiuses.Num() > 0)
		{
			// determine if the target is continously being sprayed on or not.
			const float TimeSinceLastHit = Time::GetGameTimeSince(TimeStampLastMeltHit);
			if(TimeSinceLastHit > (Dt*Dt))
			{
				// Print("BeingSprayedOn", Color = FLinearColor::Red);
				EffectComponent.SetVariableFloat(n"SpraySign", 0.0);
			}
			else
			{
				// Print("BeingSprayedOn", Color = FLinearColor::Green);
				EffectComponent.SetVariableFloat(n"SpraySign", 1.0);
			}

			EffectComponent.SetVariableVec3(n"DissolveImpulse", AcidImpactVelocityDirs[0]);
			EffectComponent.SetVariablePosition(n"DissolveImpulseLocation", WorldAcidImpactLocations[0]);
			EffectComponent.SetVariablePosition(n"DissolvePos", WorldAcidImpactLocations[0]);

			const float MeltRad = MeltRadiuses[0];
			// const float MeltRad = MeltRadiuses[0] * MeltAlpha;

			EffectComponent.SetVariableFloat(n"DissolveRadius", MeltRad);
			EffectComponent.SetVariableFloat(n"InitialDissolveTargetRadius", MeltRad);

			EffectComponent.SetVariableFloat(n"DissolveMaxRadius", MeltMaxRadiuses[0]);
			EffectComponent.SetVariableFloat(n"DissolveDuration", MeltDurations[0]);
			EffectComponent.SetVariableFloat(n"DissolveSpeed", MeltSpeeds[0]);

			EffectComponent.SetVariableFloat(n"DissolveSpeed", MeltSpeeds[0]);

			if(bBossHacks)
			{
				EffectComponent.SetVariableFloat(n"DissolveSpeed", 3000);
				//PrintToScreenScaled("MeltRad: " + MeltRad);
			}

			//PrintToScreenScaled("MeltRadius: " + MeltRad);
			// Debug::DrawDebugPoint(WorldAcidImpactLocations[0], 20.0, FLinearColor::Yellow);
			// Debug::DrawDebugSphere(WorldAcidImpactLocations[0], MeltRad, 12, FLinearColor::White, 1.0);
			// PrintToScreenScaled("DissolveDuration: " + MeltDurations[0]);
			// PrintToScreenScaled("DissolveAlpha: " + MeltRad / MeltMaxRadiuses[0]);
			//PrintToScreenScaled("DissolveSpeed: " + MeltSpeeds[0] * 0.001);
			// PrintToScreenScaled("ExpandingRapidly: " + (MeltSpeeds[0] > 300), 0.0, (MeltSpeeds[0] > 300) ? FLinearColor::Green : FLinearColor::Red);
		}

		// send the data to niagara
		// NiagaraDataInterfaceArray::SetNiagaraArrayFloat(EffectComponent, n"MeltRadiuses", MeltRadiuses);
		// NiagaraDataInterfaceArray::SetNiagaraArrayFloat(EffectComponent, n"MeltMaxRadiuses", MeltMaxRadiuses);
		// NiagaraDataInterfaceArray::SetNiagaraArrayFloat(EffectComponent, n"MeltDurations", MeltDurations);
		// NiagaraDataInterfaceArray::SetNiagaraArrayFloat(EffectComponent, n"MeltSpeeds", MeltSpeeds);
		// NiagaraDataInterfaceArray::SetNiagaraArrayFloat(EffectComponent, n"DissolveDurations", DissolveDurations);
		// NiagaraDataInterfaceArray::SetNiagaraArrayVector(EffectComponent, n"RelativeAcidImpactLocations", RelativeAcidImpactLocations);
		// NiagaraDataInterfaceArray::SetNiagaraArrayVector(EffectComponent, n"WorldAcidImpactLocations", WorldAcidImpactLocations);
		// NiagaraDataInterfaceArray::SetNiagaraArrayVector(EffectComponent, n"AcidImpactVelocityDirs", AcidImpactVelocityDirs);
	}

	void CleanupOverlayMaterial()
	{
		for(int i = 0; i < ComponentParams.Num(); ++i)
		{
			auto& CompParams = ComponentParams[i];
			if(CompParams.MeshRelativeTo != nullptr)
			{
				CompParams.MeshRelativeTo.SetOverlayMaterial(nullptr);
			}
		}
	}

	void UpdateComponentOverlayMaterial(const float MeltAlpha)
	{
		if(bUpdateOverlay == false)
			return;

		for(int i = 0; i < ComponentParams.Num(); ++i)
		{
			auto& CompParams = ComponentParams[i];

			// first lets get the Material
			auto OverlayMat = CompParams.MeshRelativeTo.GetOverlayMaterial();

			if(OverlayMat == nullptr)
				continue;

			UMaterialInstanceDynamic DynOverlayMat = Cast<UMaterialInstanceDynamic>(OverlayMat);

			if(DynOverlayMat == nullptr)
				continue;

			// PrintToScreen("Overlay. RelativeLoc: " + CompParams.RelativeLocation);

			//Send the sphere location relative to the objects root, cause thats what the shader is limited to atm
			auto MeshTransform = CompParams.MeshRelativeTo.GetWorldTransform();
			const FVector SpherePos_World = CompParams.GetWorldLocation();

			// const FVector SphereLocalLocation = MeshTransform.InverseTransformPositionNoScale(SphereWorldLocation);
			const FVector SpherePos_Local = MeshTransform.InverseTransformPosition(SpherePos_World);

			DynOverlayMat.SetVectorParameterValue(
				FName(f"Bubble{i}Loc"),
				FLinearColor(SpherePos_Local)
				// FLinearColor(SphereWorldLocation)
			);

			DynOverlayMat.SetScalarParameterValue(
				FName(f"Bubble{i}Radius"),
				CompParams.AccSphereMaskRadius.Value
			);

			DynOverlayMat.SetScalarParameterValue(
				FName(f"MeltAlpha"),
				MeltAlpha
			);

			// FVector DebugPos = MeshTransform.TransformPositionNoScale(SphereLocalLocation);
			// FVector DebugPos = MeshTransform.TransformPosition(SpherePos_Local);

			// Debug::DrawDebugPoint(
			// 	DebugPos,
			// 	24.0,
			// 	FLinearColor::Red
			// );

			// Debug::DrawDebugSphere(
			// 	DebugPos,
			// 	CompParams.AccSphereMaskRadius.Value,
			// 	32,
			// 	FLinearColor::Red,
			// 	1.0,
			// 	0.0
			// );
		}
	}

}