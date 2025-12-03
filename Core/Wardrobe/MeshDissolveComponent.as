
class UMeshDissolveComponent : UHazeMeshDissolveManagerComponent
{
	default bTickInEditor = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SeamVFXSystem;
	
	UNiagaraComponent Seam_VFX;
	bool bRunning = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Owner == nullptr)
			return;

		if (!bRunning)
			return;

		//auto StartMeshAsset = GetStartMesh() != nullptr ? GetStartMesh().GetSkeletalMeshAsset() : nullptr;
		//auto EndMeshAsset = GetEndMesh() != nullptr ? GetEndMesh().GetSkeletalMeshAsset() : nullptr;
		//PrintToScreen("Start " + StartMeshAsset + " To End " + EndMeshAsset + " | " + "ALpha: " + Alpha + " | " + Seam_VFX);
		// auto V = Seam_VFX.GetWorldLocation();
		// Debug::DrawDebugSphere(V, 200);

		if (DissolveType == EHazeDissolveType::Sphere)
		{
			UpdateAutomaticSphereDissolve();
		}
		else if (DissolveType == EHazeDissolveType::ManualSphere)
		{
			UpdateManualSphereDissolve();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnStartDissolve(bool bSpawnVFX, UNiagaraSystem VFXAssetOverride)
	{
		if(bSpawnVFX)
		{
			//Clean up
			if(Seam_VFX != nullptr)
			{
				Seam_VFX.DeactivateImmediately();
				if(Seam_VFX != nullptr)
				{
					Seam_VFX.DestroyComponent(Seam_VFX);
				}
			}

			// spawn new one
			const auto SocketName = GetAttachSocketNameForMesh(EndMesh);
			auto NiagaraAsset = VFXAssetOverride == nullptr ? SeamVFXSystem : VFXAssetOverride;
			Seam_VFX = Niagara::SpawnLoopingNiagaraSystemAttached(NiagaraAsset, EndMesh, SocketName);
		}

		bRunning = true;
		StartMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}

	UFUNCTION(BlueprintOverride)
	void OnEndDissolve()
	{
		if(Seam_VFX != nullptr)
			Seam_VFX.Deactivate();

		// Seam_VFX.DestroyComponent(Seam_VFX);

		EndMesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 0.0);
		bRunning = false;
	}

	void UpdateBoundsDissolve()
	{
	}

	void DebugResetBlends()
	{
		UpdateWhiteSpaceBlend(EndMesh, FVector::ZeroVector, 0, false);
		UpdateWhiteSpaceBlend(StartMesh, FVector::ZeroVector, 0, true);
	}

	void UpdateSphereDissolve(const FVector SphereCenter, const float SphereRadius)
	{
		// Set niagara values
		if(Seam_VFX != nullptr)
		{
			Seam_VFX.SetNiagaraVariableVec3("DissolveLocation", SphereCenter);
			Seam_VFX.SetNiagaraVariableFloat("DissolveRadius", SphereRadius + 25.0);
		}

		// Set shader values
		UpdateWhiteSpaceBlend(EndMesh, SphereCenter, SphereRadius, false);
		UpdateWhiteSpaceBlend(StartMesh, SphereCenter, SphereRadius, true);

		// PrintToScreen("DissolveRad: " + SphereRadius);
		// Debug::DrawDebugSphere(SphereCenter, SphereRadius, 64, Thickness = 0.1);
		// Debug::DrawDebugSphere(Seam_VFX.GetWorldLocation(), 50.0, 64, FLinearColor::Red, Thickness = 0.1);
	}

	const float DownDistance = 1000;
	const float PlayerRadius = 100;

	void UpdateAutomaticSphereDissolve()
	{
		auto SocketPosition = GetAttachTransform().Location;

		FVector SphereCenterOffset = DissolveDirection * DownDistance;

		FVector SphereCenter = SocketPosition - SphereCenterOffset;
		float SphereRadius = (DownDistance - PlayerRadius) + Alpha * PlayerRadius*2.0;

		UpdateSphereDissolve(SphereCenter, SphereRadius);
	}

	void UpdateManualSphereDissolve()
	{
		USphereComponent SphereComponent = GetManualSphereComponent();
		if (SphereComponent == nullptr)
			return;

		FVector SphereCenter = SphereComponent.Bounds.Origin;
		float SphereRadius = SphereComponent.GetScaledSphereRadius();

		UpdateSphereDissolve(SphereCenter, SphereRadius);
	}

	void UpdateWhiteSpaceBlend(UMeshComponent Mesh, FVector Center, float Radius, bool bFlip = true)
	{
		//Debug::DrawDebugSphere(Center, Radius, 32, FLinearColor::Red, 1);
		Mesh.SetVectorParameterValueOnMaterials(n"Glitch_Center", Center);
		Mesh.SetScalarParameterValueOnMaterials(n"Glitch_Radius", Radius);
		Mesh.SetScalarParameterValueOnMaterials(n"Glitch_Flip", bFlip ? 1.0 : 0.0);
		Mesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 1.0);
		Mesh.SetScalarParameterValueOnMaterials(n"Glitch_BorderWidth", 2.0);
	}

	FName GetAttachSocketNameForMesh(UHazeSkeletalMeshComponentBase Mesh) const
	{
		if(Mesh != nullptr)
		{
			if(Mesh.DoesSocketExist(n"Hips"))
			{
				return n"Hips";
			}
			else if(Mesh.DoesSocketExist(n"Base"))
			{
				return n"Base";
			}
		}
		return NAME_None;
	}

	FTransform GetAttachTransform() const
	{
		UHazeSkeletalMeshComponentBase Mesh = nullptr;
		if(StartMesh == nullptr)
		{
			if(EndMesh == nullptr)
			{
				devError("Wardrobe error in sequencer. No components to work with. Send a screenshot to sydney please");
				return FTransform::Identity;
			}

			Mesh = EndMesh;
		}

		Mesh = StartMesh;

		const FName SocketName = GetAttachSocketNameForMesh(Mesh);

		return Mesh.GetSocketTransform(SocketName);
	}
}