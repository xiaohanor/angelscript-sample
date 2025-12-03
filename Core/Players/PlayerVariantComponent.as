
/**
 * Manages which variant (RealWorld,Scifi,Fantasy) is currently active for the player.
 */
class UPlayerVariantComponent : UHazeBasePlayerVariantComponent
{
	private TInstigated<UHazePlayerVariantAsset> AppliedVariant;
	private UHazePlayerVariantAsset ActiveVariant;
	private UPlayerAudioMaterialComponent AudioMaterialComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AudioMaterialComponent = UPlayerAudioMaterialComponent::Get(Owner);

#if EDITOR
		// Apply the editor variant, so we have a variant before we start a progress point
		ApplyPlayerVariantOverride(
			AHazeLevelScriptActor::GetEditorPlayerVariant(),
			n"EditorVariant", EInstigatePriority::Level);
#endif

		UpdateVariant();
	}

	UFUNCTION(BlueprintOverride)
	void ApplyPlayerVariantOverride(UHazePlayerVariantAsset Variant, FInstigator Instigator, EInstigatePriority Priority)
	{
		AppliedVariant.Apply(Variant, Instigator, Priority);
		UpdateVariant();
	}

	UFUNCTION(BlueprintOverride)
	void ClearPlayerVariantOverride(FInstigator Instigator)
	{
		AppliedVariant.Clear(Instigator);
		UpdateVariant();
	}

	UFUNCTION(BlueprintOverride)
	void ClearAllPlayerVariantOverrides()
	{
		AppliedVariant.Empty();
		UpdateVariant();
	}

	UFUNCTION(BlueprintOverride)
	bool HasPlayerVariantOverride() const
	{
		return !AppliedVariant.IsDefaultValue();
	}

	EHazePlayerVariantType GetPlayerVariantType() const
	{
		return ActiveVariant.VariantType;
	}

	FHazeArmswingAudioEvents GetPlayerVariantArmswingEvents(const AHazePlayerCharacter Player) const
	{
		if(Player.IsMio())
			return ActiveVariant.AudioAsset.MioArmswingEvents;

		return ActiveVariant.AudioAsset.ZoeArmswingEvents;	
	}

	private void UpdateVariant()
	{
		if (AppliedVariant.Get() != ActiveVariant)
		{
			if(ActiveVariant != nullptr)
			{
				auto Player = Cast<AHazePlayerCharacter>(Owner);

				if(Player.IsMio())
				{
					// Remove previously added SoundDefs
					for (auto& SoundDefRef : ActiveVariant.MioVariantSoundDefs)
						Player.RemoveSoundDef(SoundDefRef);

					// Remove previously added effect handlers
					auto EffectEventComp = UHazeEffectEventHandlerComponent::GetOrCreate(Player);
					for (auto EffectHandlerClass : ActiveVariant.MioVariantEffectHandlers)
						EffectEventComp.RemoveEventHandler(EffectHandlerClass, ActiveVariant);

					// Remove presets
					for (auto Preset : ActiveVariant.MioVariantPresets)
						ClearPreset(ActiveVariant, Preset);
				}
				else
				{
					// Remove previously added SoundDefs
					for (auto& SoundDefRef : ActiveVariant.ZoeVariantSoundDefs)
						Player.RemoveSoundDef(SoundDefRef);

					// Remove previously added effect handlers
					auto EffectEventComp = UHazeEffectEventHandlerComponent::GetOrCreate(Player);
					for (auto EffectHandlerClass : ActiveVariant.ZoeVariantEffectHandlers)
						EffectEventComp.RemoveEventHandler(EffectHandlerClass, ActiveVariant);

					// Remove presets
					for (auto Preset : ActiveVariant.ZoeVariantPresets)
						ClearPreset(ActiveVariant, Preset);
				}
			}

			ActiveVariant = AppliedVariant.Get();
			ApplyVariant(ActiveVariant);		
		}
	}

	private void ApplyPreset(UHazePlayerVariantAsset VariantAsset, UHazePlayerVariantPreset Preset)
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		// Effect Handlers
		auto EffectEventComp = UHazeEffectEventHandlerComponent::GetOrCreate(Player);
		for (auto EffectHandlerClass : Preset.EffectHandlers)
			EffectEventComp.AddEventHandler(EffectHandlerClass, VariantAsset);
	}

	private void ClearPreset(UHazePlayerVariantAsset VariantAsset, UHazePlayerVariantPreset Preset)
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		// Effect Handlers
		auto EffectEventComp = UHazeEffectEventHandlerComponent::GetOrCreate(Player);
		for (auto EffectHandlerClass : Preset.EffectHandlers)
			EffectEventComp.RemoveEventHandler(EffectHandlerClass, VariantAsset);
	}
	
	private void ApplyVariant(UHazePlayerVariantAsset VariantAsset)
	{
		if (VariantAsset == nullptr)
			return;

		auto Player = Cast<AHazePlayerCharacter>(Owner);

		// Reset all override materials
		int MaterialCount = Player.Mesh.NumMaterials;
		for (int i = 0; i < MaterialCount; ++i)
			Player.Mesh.SetMaterial(i, nullptr);

		// Change the skeletal mesh
		if (Player.IsMio())
			Player.Mesh.SetSkeletalMeshAsset(VariantAsset.MioSkeletalMesh);
		else
			Player.Mesh.SetSkeletalMeshAsset(VariantAsset.ZoeSkeletalMesh);

		Player.Mesh.bAllowPreShadowsFromShadowProxy = VariantAsset.bAllowPreShadowsFromShadowProxy;

		// Add new effect handlers
		auto EffectEventComp = UHazeEffectEventHandlerComponent::GetOrCreate(Player);
		if (Player.IsMio())
		{
			for (auto EffectHandlerClass : VariantAsset.MioVariantEffectHandlers)
				EffectEventComp.AddEventHandler(EffectHandlerClass, VariantAsset);
		}
		else
		{
			for (auto EffectHandlerClass : VariantAsset.ZoeVariantEffectHandlers)
				EffectEventComp.AddEventHandler(EffectHandlerClass, VariantAsset);
		}

		// Add new presets
		if (Player.IsMio())
		{
			for (auto Preset : VariantAsset.MioVariantPresets)
				ApplyPreset(VariantAsset, Preset);
		}
		else
		{
			for (auto Preset : VariantAsset.ZoeVariantPresets)
				ApplyPreset(VariantAsset, Preset);
		}

		// Skip if no audio data is required at all.
		if (VariantAsset.MioVariantSoundDefs.Num() == 0 &&
			VariantAsset.ZoeVariantSoundDefs.Num() == 0 &&
			VariantAsset.AudioAsset == nullptr)
		{
			return;
		}

		if(!devEnsure(VariantAsset.AudioAsset != nullptr, f"{VariantAsset.GetName()} has missing audio asset! Player movement audio will not function properly"))
			return;

		// Set audio
		TMap<FName, UHazeAudioMaterialReferenceAsset> MaterialAssets;

		if (Player.IsMio())
		{
			for(auto& SoundDefRef : VariantAsset.MioVariantSoundDefs)
			{
				SoundDefRef.SpawnSoundDefAttached(Player);
			}

			for(UHazeAudioMaterialReferenceAsset Asset : VariantAsset.AudioAsset.MioAssets)
			{
				MaterialAssets.Add(Asset.MaterialName, Asset);
			}
		}
		else
		{
			for(auto& SoundDefRef : VariantAsset.ZoeVariantSoundDefs)
			{
				SoundDefRef.SpawnSoundDefAttached(Player);
			}
							
			for(UHazeAudioMaterialReferenceAsset Asset : VariantAsset.AudioAsset.ZoeAssets)
			{
				MaterialAssets.Add(Asset.MaterialName, Asset);
			}			
		}

		AudioMaterialComponent.SetMaterials(MaterialAssets);
	}

};