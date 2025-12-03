
UCLASS(Meta = (NoSourceLink, DisplayName = "Post Process Volume", DefaultActorLabel = "Post Process Volume", HighlightPlacement))
class AHazePostProcessVolume : APostProcessVolume
{
	UPROPERTY(EditAnywhere, Category = "Post Process Preset")
	EPostProcessDistanceCheckType DistanceType = EPostProcessDistanceCheckType::Camera;

	UPROPERTY(EditAnywhere, Category = "Post Process Preset", Meta = (ShowOnlyInnerProperties))
	UHazePostProcessPreset Preset;

	// override which point is used for determining when the post process should be blend in.
	UFUNCTION(BlueprintEvent)
	float32 OverrideBlendWeight(FVector OriginalPoint, float OriginalRadius) const
	{
		return 0.f;
	}

	// return true or false depending on if we are overriding or not.
	UFUNCTION(BlueprintOverride)
	bool OverrideEncompassesPoint(bool& OutEncompassesPoint, float32& OutDistanceToPoint, FVector Point,
								  float SphereRadius)
	{
		// PLAYER
		if(DistanceType == EPostProcessDistanceCheckType::Player)
		{
			AHazePlayerCharacter Mio; AHazePlayerCharacter Zoe; 
			Game::GetMioZoe(Mio, Zoe);
			if(Mio != nullptr && Zoe != nullptr)
			{
				if(Mio.GetViewLocation().Equals(Point))
				{
					OutEncompassesPoint = EncompassesPoint(Mio.GetActorLocation(), SphereRadius, OutDistanceToPoint);
				}
				else
				{
					OutEncompassesPoint = EncompassesPoint(Zoe.GetActorLocation(), SphereRadius, OutDistanceToPoint);
				}
			}

			return true;
		}

		// CUSTOM
		if(DistanceType == EPostProcessDistanceCheckType::Custom)
		{
			float32 CustomBlendWeight = OverrideBlendWeight(Point, SphereRadius);
			CustomBlendWeight = Math::Clamp(CustomBlendWeight, 0.f, 1.f);
			CustomBlendWeight = 1.f - CustomBlendWeight;
			OutDistanceToPoint = CustomBlendWeight * BlendRadius;
			OutEncompassesPoint = CustomBlendWeight > 0.f;

			return true;
		}

		// CAMERA. Super:: will take care of it.
		OutEncompassesPoint = false;
		OutDistanceToPoint = 0.f;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Preset != nullptr)
			Settings = Preset.PostProcess;
	}
};

class UHazePostProcessPreset : UDataAsset
{
	UPROPERTY(EditAnywhere, Category = "Post Process")
	FPostProcessSettings PostProcess;
};

#if EDITOR
class UHazePostProcessVolumeDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AHazePostProcessVolume;

	UHazePostProcessPreset PrevPreset = nullptr;
	UHazeImmediateDrawer PresetDrawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		AHazePostProcessVolume Volume = Cast<AHazePostProcessVolume>(GetCustomizedObject());

		// Hide prop line settings if a preset is selected
		PrevPreset = Volume.Preset;
		if (Volume.Preset != nullptr)
		{
			HideCategory(n"Lens");
			HideCategory(n"Color Grading");
			HideCategory(n"Film");
			HideCategory(n"Global Illumination");
			HideCategory(n"Reflections");
			HideCategory(n"Rendering Features");
		}

		EditCategory(n"Post Process Preset", CategoryType =  EScriptDetailCategoryType::Important);
		AddAllCategoryDefaultProperties(n"Post Process Preset");

		if (PrevPreset == nullptr)
		{
			// If we don't have a preset, give the option to save settings
			PresetDrawer = AddImmediateRow(n"Post Process Preset", "Preset", false);
		}
		else
		{
			PresetDrawer = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AHazePostProcessVolume Volume = Cast<AHazePostProcessVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		// Refresh details if our preset changes
		if (Volume.Preset != PrevPreset)
		{
			PrevPreset = Volume.Preset;
			ForceRefresh();
			return;
		}

		// Draw button in the preset view
		if (PresetDrawer != nullptr && Volume.Preset == nullptr && PresetDrawer.IsVisible())
		{
			auto HorizBox = PresetDrawer.BeginHorizontalBox();
			HorizBox.SlotHAlign(EHorizontalAlignment::HAlign_Center);
			HorizBox.SlotFill();
			HorizBox.SlotPadding(2, 4, 2, 2);
			if (HorizBox.Button("Save Settings as Preset"))
				SavePreset();
		}
	}

	void SavePreset()
	{
		AHazePostProcessVolume Volume = Cast<AHazePostProcessVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		UHazePostProcessPreset TransientPreset = UHazePostProcessPreset();
		TransientPreset.PostProcess = Volume.Settings;

		UObject SavedAsset = Editor::SaveAssetAsNewPath(TransientPreset);
		if (SavedAsset == nullptr)
			return;

		{
			FScopedTransaction Transaction("Save Post Process Line Settings as Preset");
			Volume.Modify();
			Volume.Preset = Cast<UHazePostProcessPreset>(SavedAsset);
			NotifyPropertyModified(Volume, n"Preset");
			Volume.RerunConstructionScripts();
		}

		Editor::RedrawAllViewports();
		ForceRefresh();
	}
}
#endif