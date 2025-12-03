
class ATestPortalWarpVolume : AHazePostProcessVolume
{
	default bEnabled = false;

	UPROPERTY(DefaultComponent)
	UHazeLevelSequenceResponseComponent SequenceResponseComponent;

	UPROPERTY(DefaultComponent)
	UTestPortalWarpVolumeInEditorComponent InEditorComp;

	/**
	 * By default we'll ignore meshes / actors that have the tag 'Floor'
	 * 
	 * This will invert that logic and only suck in meshes / actors with the tag 'Floor'
	 * 
	 * The tag can be added either on the Actor or on the MeshComponent
	 * 
	 */
	UPROPERTY(EditAnywhere)
	bool bInvertTagExclusion = false;

	// we use this bool to isolate the fix to levels that only have the rain 
	UPROPERTY(EditAnywhere)
	bool bSetHiddenInGameOnMeshes = false;

	UPROPERTY(EditAnywhere, Interp)
	AHazeActor PortalRef;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem NiagaraAsset;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SimplifiedNiagaraAsset;

	UPROPERTY(EditAnywhere)
	UMaterialInterface DissolveMat;
	
	// use the simplified version of the niagara to reduce CPU cost
	UPROPERTY(EditAnywhere)
	bool bUseSimplifiedNiagara = false;

	// runtime params
	FHazeAcceleratedFloat SuctionRadius;
	FHazeAcceleratedFloat SuctionStr;
	FHazeAcceleratedFloat SuctionExposure;

	// TArray<UStaticMeshComponent> MeshResets;
	TArray<FMeshResetData> MeshResets;

	TArray<UNiagaraComponent> NiagaraComponents;

	// want to disable the collision over time on all of these.
	TArray<UStaticMeshComponent> RemainingMeshesToDisable;

	float Time = 0.0;
	bool bWarpStarted = false;
	float TimeStampLastWarpStarted = -1.0;

	// settings
	UPROPERTY(EditAnywhere, Interp)
	bool bWarpDissolveEnabled = false;

	// a way to mute DevErrors
	UPROPERTY(EditAnywhere, Interp)
	bool bMuteDevErrors = true;

	bool bPreview = false;
	bool bHideMeshes = true;
	bool bLoop = false;
	float PauseTime = 2.0;
	float SuctionTime = 7.0;

	FHazeAcceleratedFloat AccShaderAlpha;

	UPROPERTY()
	UMaterialInstanceDynamic DynMat;

	bool bWarpHasTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SequenceResponseComponent.OnSequenceEnd.AddUFunction(this, n"SeqEnd");
		bWarpHasTriggered = false;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		EndWarp();
	}

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		EndWarp();
	}

	UFUNCTION()
	void SeqEnd()
	{
		EndWarp();
	}

	void EndWarp()
	{

#if !EDITOR
		// we need to consider skipping cutscenes, when the logic hasn't had time to even trigger yet.
		if(bWarpHasTriggered == false)
		{
			ResetToOriginalState();
			CacheOverlappingMeshesAndInitializeVFX(false);
			bWarpHasTriggered = true;
		}
#endif 

		ResetToOriginalState();

#if !EDITOR
		DisableAllRemainingMeshCollisions();
#endif 

	}

	void DisableAllRemainingMeshCollisions()
	{
		if(RemainingMeshesToDisable.Num() <= 0)
			return;

		for(auto IterMesh : RemainingMeshesToDisable)
		{
			IterMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		if(bSetHiddenInGameOnMeshes)
		{
			for(auto IterMesh : RemainingMeshesToDisable)
			{
				IterMesh.SetHiddenInGame(true);
			}
		}

		RemainingMeshesToDisable.Empty();
	}

	// revert mesh changes and kill niagara effects
	void ResetToOriginalState()
	{
		// reset mesh
		if(bHideMeshes)
		{
			for(auto& IterMeshData : MeshResets)
			{
				//IterMeshData.Mesh.SetVisibility(true, true);
				IterMeshData.ReapplyMaterials(bMuteDevErrors);
			}
		}

#if EDITOR
		for(auto& IterMeshData : MeshResets)
		{
			IterMeshData.ReapplyCollisionEnabled();
		}
#endif

		// disable Niagara
		for(int i = NiagaraComponents.Num()-1; i >= 0; --i)
		{
			auto IterNiagara = NiagaraComponents[i];

			if(IterNiagara == nullptr)
				continue;

			IterNiagara.DeactivateImmediately();

			// IterNiagara.DestroyComponent(IterNiagara);
			// NiagaraComponents.RemoveAt(i);
		}

		// reset params
		Time = 0.0;
		NiagaraComponents.Empty();
		MeshResets.Empty();
		bWarpStarted = false;
		SuctionExposure.SnapTo(1.0);
		SuctionRadius.SnapTo(0.0);
		SuctionStr.SnapTo(0.0);
		AccShaderAlpha.SnapTo(0.0);
	}

	void TickInEditor(float DeltaSeconds)
	{
		// FVector TraceExtents = GetActorLocalBoundingBox(false, false).Extent;
		// PrintToScreen("Trace Extents: " + TraceExtents);
		// PrintToScreenScaled("Warp Enabled " + bWarpDissolveEnabled, 0.0, bWarpDissolveEnabled ? FLinearColor::Green : FLinearColor::Red);

		if(HasActorBegunPlay())
		{
			if(bWarpDissolveEnabled == false && bPreview == false)
			{
				ResetToOriginalState();
				return;
			}
		}
		else
		{
			if(bWarpDissolveEnabled == false)
			{
				ResetToOriginalState();
				return;
			}
		}

		Time += DeltaSeconds;

		// PrintToScreenScaled("WarpTime: " + Time);

		if(PortalRef == nullptr)
		{
			devError("portal ref has not been set on the warp volume");
		}

		// INIT
		if(bWarpStarted == false)
		{
			ResetToOriginalState();
			CacheOverlappingMeshesAndInitializeVFX();
			bWarpHasTriggered = true;
		}

		// UPDATE
		const float TimeSinceStarted = Time::GetGameTimeSince(TimeStampLastWarpStarted);
		if(TimeSinceStarted < SuctionTime)
		{
			UpdateParamsTowardsTarget(DeltaSeconds);

			float Alpha = TimeSinceStarted/SuctionTime;

			// PrintToScreen("Alpha: " + Alpha);

			if(Alpha < 0.2)
			{
				AccShaderAlpha.AccelerateTo(1.0 , SuctionTime * 0.2, DeltaSeconds);
			}
			else
			{
				AccShaderAlpha.SpringTo(0.0, 1, 0.8, DeltaSeconds);
			}

			Alpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.4), FVector2D(0.0, 1.0), Alpha);
			// PrintToScreenScaled("WarpTimeALpha: " + Alpha);

			for(auto& MeshData : MeshResets)
			{
				MeshData.Mesh.SetScalarParameterValueOnMaterials(n"Blend", Alpha);
				MeshData.Mesh.SetScalarParameterValueOnMaterials(n"RawAlpha", AccShaderAlpha.Value);
				if(PortalRef != nullptr)
				{
					MeshData.Mesh.SetVectorParameterValueOnMaterials(n"Portal", PortalRef.GetActorLocation());
				}
			}
		}
		else
		{
			UpdateParamsTowardsZero(DeltaSeconds);
		}

		// space out the disabling of the collision for the meshes over several frames in order to avoid performance spikes. 
		if(RemainingMeshesToDisable.Num() > 0 && GetWorld().IsGameWorld())
		{
			int IterCounter = RemainingMeshesToDisable.Num() - 1;
			RemainingMeshesToDisable[IterCounter].SetCollisionEnabled(ECollisionEnabled::NoCollision);
			if(bSetHiddenInGameOnMeshes)
			{
				RemainingMeshesToDisable[IterCounter].SetHiddenInGame(true);
			}
			RemainingMeshesToDisable.RemoveAtSwap(IterCounter);
		}

		// RESET / LOOP
		if(bLoop)
		{
			if(Time > SuctionTime+PauseTime)
			{
				EndWarp();
			}
		}

	}

	FOverlapResultArray FindOverlaps()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		FVector TraceExtents = GetActorLocalBoundingBox(false, false).Extent;

		// if it doesn't work in sequencer.
		if(TraceExtents.IsZero())
			TraceExtents = FVector::OneVector * 100;

		TraceExtents *= GetActorScale3D();
		Trace.UseBoxShape(TraceExtents, GetActorQuat());
		// Trace.UseBoxShape(Math::Max(SuctionRadius.Value, 0.01));

		// FHazeTraceDebugSettings DebugSettings;
		// DebugSettings.Duration = SuctionTime;
		// DebugSettings.TraceColor = FLinearColor::Yellow;
		// DebugSettings.Thickness = 5.0;
		// Trace.DebugDraw(DebugSettings);

		auto Overlaps = Trace.QueryOverlaps(GetActorLocation());

		return Overlaps;
	}

	void CacheOverlappingMeshesAndInitializeVFX(bool bInitVFX = true)
	{		
		if (bUseSimplifiedNiagara)
		{
			if (PortalRef != nullptr && SimplifiedNiagaraAsset != nullptr)
			{
				auto NiagaraComp = Niagara::SpawnOneShotNiagaraSystemAtLocation(SimplifiedNiagaraAsset, PortalRef.GetActorLocation());
                NiagaraComp.SetVariablePosition(n"PortalPosition", PortalRef.GetActorLocation());
                NiagaraComp.SetVariablePosition(n"Center", GetActorLocation());
                NiagaraComp.ReinitializeSystem();
                NiagaraComp.Activate(true);
			}
			else
			{
				devError("simplified niagara mode is selected; let's set SimplifiedNiagaraAsset and PortalRef to use it");
			}
		}


		int MeshesProcessed = 0;
		for(auto IterOverlap : FindOverlaps())
		{				
			CacheMeshAndInitializeVFX(IterOverlap, bInitVFX, bUseSimplifiedNiagara);
			++MeshesProcessed;
			//break;
		}
		

		//PrintScaled("Trace. Objects processed: " + MeshesProcessed + "/" + Overlaps.Num());

		bWarpStarted = true;
		TimeStampLastWarpStarted = Time::GetGameTimeSeconds();
	}

	bool CacheMeshAndInitializeVFX(const FOverlapResult& Overlap, bool InitVFX = true, bool IsUsingSimplifiedNiagara = false)
	{
		if(Overlap.Actor == nullptr ||Overlap.Component == nullptr)
			return false;

		bool bHasTag = Overlap.Actor.ActorHasTag(n"Floor") || Overlap.Component.HasTag(n"Floor");
		if(bInvertTagExclusion)
		{
			if(bHasTag == false)
			{
				return false;
			}
		}
		else
		{
			if(bHasTag == true)
			{
				return false;
			}
		}

		UStaticMeshComponent SMesh = Cast<UStaticMeshComponent>(Overlap.Component);

		if(SMesh == nullptr)
			return false;

		bool bOwnerHidden = SMesh.Owner.bHidden;
		bool bMeshHidden = SMesh.bHiddenInGame || !SMesh.bVisible;
		if(bOwnerHidden || bMeshHidden)
			return false;

		RemainingMeshesToDisable.Add(SMesh);

		if(InitVFX == false)
			return true;

		FMeshResetData MeshResetData;
		MeshResetData.Mesh = SMesh;
		MeshResetData.OriginalCollisionEnabled = SMesh.CollisionEnabled;
		int NumMats = SMesh.GetNumMaterials();
		MeshResetData.OriginalMaterials.Reserve(NumMats);

		// Apply Dissolve mat to all the meshes
		if(DissolveMat != nullptr)
		{
			auto DynDissolveMat = Material::CreateDynamicMaterialInstance(SMesh, DissolveMat);
			for(int i = NumMats; i >= 0; --i)
			{
					
#if EDITOR
				if(bMuteDevErrors == false)
				{
					auto IterMat = SMesh.GetMaterial(i);
					if(IterMat != nullptr && IterMat.IsA(UMaterialInstanceDynamic))
					{
						devError(
						"Side portal suction VFX warning, when starting suction." +
						"\n " + 
						"\n This guy!! Has a dynamic material on the mesh, when it shouldn't have." + 
						"\n " + 
						"\n Actor: " + SMesh.Owner + 
						"\n " + 
						"\n Mesh: " + SMesh + 
						"\n " + 
						"\n Material: " + IterMat);
					}
				}
#endif

				MeshResetData.OriginalMaterials.Insert(SMesh.GetMaterial(i));
				SMesh.SetMaterial(i, DynDissolveMat);
			}
		}

		if (!IsUsingSimplifiedNiagara)
		{
			auto NiagaraComp = Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraAsset, GetActorLocation());

			if(NiagaraComp == nullptr)
				return false;

			NiagaraComponents.Add(NiagaraComp);

			// Niagara::OverrideSystemUserVariableStaticMeshComponent(NiagaraComp,"SMesh", SMesh);
			Niagara::OverrideSystemUserVariableStaticMeshComponent(NiagaraComp,"MEsh", SMesh);

			NiagaraComp.SetVariablePosition(n"Center", GetActorLocation());

			if(PortalRef == nullptr)
			{
				devError("portal ref has not been set on the warp volume");
			}
			else
			{
				NiagaraComp.SetVariablePosition(n"PortalPosition", PortalRef.GetActorLocation());
			}

			// Debug::DrawDebugPoint(PortalRef.GetActorLocation(), 50, FLinearColor::Yellow, 3.0);

			NiagaraComp.ReinitializeSystem();
			NiagaraComp.Activate(true);
		}

		MeshResets.AddUnique(MeshResetData);

		return true;
	}

	void MovePivot()
	{
		if(DynMat == nullptr)
			return;

		DynMat.SetVectorParameterValue(n"Pivot", FLinearColor(GetActorLocation()));
	}

	void UpdateParamsTowardsTarget(const float Dt)
	{
		SuctionStr.AccelerateTo(1.0, SuctionTime, Dt);
		SuctionRadius.AccelerateTo(5000, SuctionTime, Dt);
		SuctionExposure.AccelerateTo(20, SuctionTime, Dt);

		if(DynMat != nullptr)
		{
			DynMat.SetScalarParameterValue(n"Strength", SuctionStr.Value);
			DynMat.SetScalarParameterValue(n"Radius", SuctionRadius.Value);
		}

	}

	void UpdateParamsTowardsZero(const float Dt)
	{
		SuctionStr.SpringTo(0.0, 55.0, 0.4, Dt);
		SuctionRadius.SpringTo(0.0, 100.0, 0.4,Dt);

		if(DynMat != nullptr)
		{
			DynMat.SetScalarParameterValue(n"Strength", SuctionStr.Value);
			DynMat.SetScalarParameterValue(n"Radius", SuctionRadius.Value);
		}

		SuctionExposure.SpringTo(0, 1000.0, 1.0,Dt);

		// if(Math::IsNearlyZero(SuctionExposure.Value))
		// {
		// 	bResetDone = true;
		// }
	}

}

class UTestPortalWarpVolumeInEditorComponent : USceneComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ATestPortalWarpVolume OwnerVolume = Cast<ATestPortalWarpVolume>(Owner);
		OwnerVolume.TickInEditor(DeltaSeconds);
	}

}

struct FMeshResetData
{
	UStaticMeshComponent Mesh;
	TArray<UMaterialInterface> OriginalMaterials;
	ECollisionEnabled OriginalCollisionEnabled;

	void ReapplyCollisionEnabled()
	{
		Mesh.CollisionEnabled = OriginalCollisionEnabled;
	}

	void ReapplyMaterials(bool bMuteDevErrors = false)
	{
		// PrintToScreen("APPLY Materials", 3.0);
		for(int i = 0; i < OriginalMaterials.Num(); ++i)
		{
#if EDITOR
			if(bMuteDevErrors == false)
			{
				auto IterMat = OriginalMaterials[i];
				if(IterMat != nullptr && IterMat.IsA(UMaterialInstanceDynamic))
				{
					devError( 
					"Side portal suction VFX warning, when stopping suction."+ 
					"\n " + 
					"\n Dynamic material is being reapplied on mesh as original material " +
					"\n " + 
					"\n Actor: " + Mesh.Owner + 
					"\n " + 
					"\n Mesh: " + Mesh + 
					"\n " + 
					"\n Material: " + IterMat + 
					"\n " + 
					"\n probably because you saved level layers while in Sequencer." + 
					"\n Close sequencer and resave the layer to fix the problem...");
				}
			}
#endif

			Mesh.SetMaterial(i, OriginalMaterials[i]);
			Mesh.MarkRenderStateDirty();
		}
	}
}
