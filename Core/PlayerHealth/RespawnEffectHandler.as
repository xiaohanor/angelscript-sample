struct FRespawnEffectMaterialChange
{
	UMeshComponent MeshComp;
	TArray<UMaterialInterface> AppliedMaterials;
	TArray<UMaterialInterface> PreviousMaterials;
	UMaterialInterface AppliedOverlay;
}

class URespawnEffectHandler : UHazeEffectEventHandler
{
	// Player that respawned and caused this effect
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDeathRespawnEffectSettings EffectSettings;

	UPROPERTY(EditAnywhere, Category = "Effects")
    UNiagaraSystem DefaultRespawnParticleEffect;

	UPROPERTY(EditAnywhere, Category = "Materials")
	UMaterialInterface DefaultRespawnOverlayMaterial;

	UPlayerHealthComponent HealthComp;
	TArray<FRespawnEffectMaterialChange> ChangedMaterials;

	UFUNCTION(BlueprintOverride, Meta = (AutoCreateBPNode))
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			HealthComp = UPlayerHealthComponent::Get(Player);
		EffectSettings = UDeathRespawnEffectSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintPure)
	float GetRespawnFadedDuration() const
	{
		if(HealthComp == nullptr)
			return 0.0;

		if(HealthComp.HealthSettings == nullptr)
			return 0.0;

		return 	HealthComp.HealthSettings.RespawnBlackScreenDuration +
				// HealthComp.HealthSettings.RespawnFadeInDuration +
				HealthComp.HealthSettings.RespawnFadeOutDuration;
	}

	UFUNCTION()
	void HidePlayerForRespawnOverlayMaterial(UMaterialInterface OverlayMaterial)
	{
		if (ChangedMaterials.Num() != 0)
		{
			// Clear any material change we already had
			for (auto& MaterialChange : ChangedMaterials)
			{
				UMeshComponent MeshComp = MaterialChange.MeshComp;
				bool bAppliedAnyMaterial = false;
				for (int i = 0, Count = MeshComp.NumMaterials; i < Count; ++i)
				{
					if (!IsValid(MeshComp))
						continue;

					UMaterialInterface Material = MeshComp.GetMaterial(i);
					UMaterialInstanceDynamic DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
					if (Material != nullptr
						&& ((MaterialChange.AppliedMaterials.IsValidIndex(i) && (Material == MaterialChange.AppliedMaterials[i] || (DynamicMaterial != nullptr && DynamicMaterial.Parent == MaterialChange.AppliedMaterials[i])))
						|| (OverlayMaterial != nullptr && Material.BaseMaterial == OverlayMaterial.BaseMaterial))
					)
					{
						bAppliedAnyMaterial = true;
						if (MaterialChange.PreviousMaterials.IsValidIndex(i))
							MeshComp.SetMaterial(i, MaterialChange.PreviousMaterials[i]);
						else
							MeshComp.SetMaterial(i, nullptr);
					}
				}
			}
			ChangedMaterials.Reset();
		}

		TArray<UMeshComponent> AttachedMeshes;

		if (Player == nullptr)
		{
			auto BaseMesh = UHazeSkeletalMeshComponentBase::Get(Owner);
			if (BaseMesh != nullptr)
			{
				BaseMesh.GetChildrenComponentsByClass(UMeshComponent, true, AttachedMeshes);
				AttachedMeshes.Add(BaseMesh);
			}
		}
		else
		{
			auto SettingsComp = UPlayerVFXSettingsComponent::Get(Player);
			if (SettingsComp != nullptr && SettingsComp.RelevantAttachRoot.Get() != nullptr)
			{
				USceneComponent AttachRoot = SettingsComp.RelevantAttachRoot.Get();
				AttachRoot.GetChildrenComponentsByClass(UMeshComponent, true, AttachedMeshes);

				UMeshComponent AttachRootMesh = Cast<UMeshComponent>(AttachRoot);
				if (AttachRootMesh != nullptr)
					AttachedMeshes.Add(AttachRootMesh);
			}
			else
			{
				auto BaseMesh = Player.FindRelevantAttachMeshForNiagara();
				if (BaseMesh == nullptr)
					return;

				BaseMesh.GetChildrenComponentsByClass(UMeshComponent, true, AttachedMeshes);
				AttachedMeshes.Add(BaseMesh);
			}
		}

		for (auto MeshComp : AttachedMeshes)
		{
			if (!IsValid(MeshComp))
				continue;
			FRespawnEffectMaterialChange MaterialChange;
			MaterialChange.MeshComp = MeshComp;
			MaterialChange.PreviousMaterials = MeshComp.GetMaterials();
			MaterialChange.AppliedMaterials.SetNumZeroed(MaterialChange.PreviousMaterials.Num());
			MaterialChange.AppliedOverlay = nullptr;
			for (int i = 0, Count = MaterialChange.PreviousMaterials.Num(); i < Count; ++i)
			{
				UMaterialInterface Material = MeshComp.GetMaterial(i);
				if (Material == nullptr)
					continue;

				if(!EffectSettings.bAllowTranslucentMaterials)
				{
					EBlendMode BlendMode = Material.GetBlendMode();
					if (BlendMode == EBlendMode::BLEND_Translucent)
						continue;
					if (BlendMode == EBlendMode::BLEND_Additive)
						continue;
				}

				MeshComp.SetMaterial(i, OverlayMaterial);
				MaterialChange.AppliedMaterials[i] = OverlayMaterial;
			}
			ChangedMaterials.Add(MaterialChange);
		}
	}

	UFUNCTION()
	void ShowPlayerForRespawnOverlayMaterial(UMaterialInterface OverlayMaterial)
	{
		for (auto& MaterialChange : ChangedMaterials)
		{
			UMeshComponent MeshComp = MaterialChange.MeshComp;
			bool bAppliedAnyMaterial = false;
			for (int i = 0, Count = MeshComp.NumMaterials; i < Count; ++i)
			{
				if (!IsValid(MeshComp))
					continue;

				UMaterialInterface Material = MeshComp.GetMaterial(i);
				UMaterialInstanceDynamic DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
				if (Material != nullptr
					&& ((MaterialChange.AppliedMaterials.IsValidIndex(i) && (Material == MaterialChange.AppliedMaterials[i] || (DynamicMaterial != nullptr && DynamicMaterial.Parent == MaterialChange.AppliedMaterials[i])))
					|| (OverlayMaterial != nullptr && Material.BaseMaterial == OverlayMaterial.BaseMaterial))
				)
				{
					bAppliedAnyMaterial = true;
					if (MaterialChange.PreviousMaterials.IsValidIndex(i))
						MeshComp.SetMaterial(i, MaterialChange.PreviousMaterials[i]);
					else
						MeshComp.SetMaterial(i, nullptr);
					MaterialChange.AppliedMaterials[i] = nullptr;
				}
			}
			MaterialChange.PreviousMaterials.Reset();
			if (bAppliedAnyMaterial)
			{
				MeshComp.SetOverlayMaterial(OverlayMaterial);
				MaterialChange.AppliedOverlay = OverlayMaterial;
			}
		}
	}

	UFUNCTION()
	void RemovePlayerOverlayMaterial()
	{
		for (auto& MaterialChange : ChangedMaterials)
		{
			UMeshComponent MeshComp = MaterialChange.MeshComp;
			if (IsValid(MeshComp))
				MeshComp.SetOverlayMaterial(nullptr);
		}

		ChangedMaterials.Reset();
	}

	/**
	 * When the respawn sequence first starts (it will start fading to black)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnStarted(FRespawnLocationEventData Location) {}

	/**
	 * When the respawn has faded out fully.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnFadedOut(FRespawnLocationEventData Location) {}

	/**
	 * When the respawn is triggered (the screen will still be black)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnTriggered() {}

	/**
	 * When the respawn is fully finished, the screen is faded in, and the player has control.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnFinished() {}

	UFUNCTION(BlueprintPure)
	UNiagaraSystem GetCharacterRespawnEffect()
	{
		EffectSettings = UDeathRespawnEffectSettings::GetSettings(Owner);
		return EffectSettings.RespawnParticleEffect;
	}

	UFUNCTION(BlueprintPure)
	UMaterialInterface GetCharacterRespawnMaterials()
	{
		EffectSettings = UDeathRespawnEffectSettings::GetSettings(Owner);
		devCheck(EffectSettings.RespawnOverlayMaterial != nullptr, "Tried to get characters respawn materials but they are null! This will reset all the players attached meshes to their default materials");
		return EffectSettings.RespawnOverlayMaterial;
	}
}