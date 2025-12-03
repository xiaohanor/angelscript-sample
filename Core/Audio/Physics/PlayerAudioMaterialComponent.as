struct FFootstepMaterialOverride
{
	FInstigator Instigator;
	UPhysicalMaterialAudioAsset Material;
}
class UPlayerAudioMaterialComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	private TMap<FName, UHazeAudioMaterialReferenceAsset> MaterialAssets;

	UPROPERTY()
	bool bInRain = false;
	// Changed to a more general material override.
	private FInstigator OverrideMaterialInstigator;
	private UPhysicalMaterialAudioAsset OverrideMaterial;

	private TArray<FFootstepMaterialOverride> MovementMaterialOverrides;
	// Slide, FootSteps Left and Right, Hand
	default MovementMaterialOverrides.SetNum(4);

	void SetAllMaterialOverride(UPhysicalMaterialAudioAsset InOverrideMaterial, FInstigator Instigator)
	{
		OverrideMaterial = InOverrideMaterial;
		OverrideMaterialInstigator = Instigator;
	}

	// Re-use EFootType - Slide, FootSteps Left and Right, Hand
	void SetMovementMaterialOverride(EFootType Foot, UPhysicalMaterialAudioAsset InOverrideMaterial, FInstigator Instigator)
	{
		auto Index = int(Foot) + 1;
		if (!MovementMaterialOverrides.IsValidIndex(Index))
		{
			return;
		}

		MovementMaterialOverrides[Index].Instigator = Instigator;
		MovementMaterialOverrides[Index].Material = InOverrideMaterial;
	}

	bool CheckMovementOverrideMaterialTag(const EFootType InFoot, FName& OutMaterialTag)
	{
		// Check first for a general override.
		if (CheckOverrideMaterialTag(OutMaterialTag))
		{
			return true;
		}

		auto Index = int(InFoot) + 1;
		if (!MovementMaterialOverrides.IsValidIndex(Index))
		{
			return false;
		}

		auto& MaterialOverride = MovementMaterialOverrides[Index];
		if(MaterialOverride.Material != nullptr)
		{
			if(MaterialOverride.Instigator.IsValid())
			{
				OutMaterialTag = MaterialOverride.Material.FootstepData.FootstepTag;
				return true;
			}
			else
			{
				MaterialOverride.Material = nullptr;
				MaterialOverride.Instigator = FInstigator();				
			}
		}

		return false;
	}

	bool HasOverrideMaterial() const
	{
		return OverrideMaterial != nullptr && OverrideMaterialInstigator.IsValid();
	}

	bool CheckOverrideMaterialTag(FName& OutMaterialTag)
	{
		if(OverrideMaterial != nullptr)
		{
			if(OverrideMaterialInstigator.IsValid())
			{
				OutMaterialTag = OverrideMaterial.FootstepData.FootstepTag;
				return true;
			}
			else
			{
				OverrideMaterial = nullptr;
				OverrideMaterialInstigator = FInstigator();				
			}
		}

		return false;
	}

	void SetMaterials(const TMap<FName, UHazeAudioMaterialReferenceAsset>& InMaterialAssets)
	{
		MaterialAssets = InMaterialAssets;
	}

	bool GetMaterialEvent(const FName InMaterialTag, const FName& InMovementType, const EFootType FootMaterialType, const EFootType InFoot, UHazeAudioEvent&out FootstepEvent)
	{
		FName MaterialTag = InMaterialTag;
		CheckMovementOverrideMaterialTag(FootMaterialType, MaterialTag);
		
		// Get material asset by tag (FootstepTag set i audio physmat)
		UHazeAudioMaterialReferenceAsset MaterialAsset;
		if(!MaterialAssets.Find(MaterialTag, MaterialAsset))
		{
			// No material found, fallback to default
			auto DefaultMat = Game::GetHazeGameInstance().GlobalAudioDataAsset.DefaultAudioPhysMat;
			if(!MaterialAssets.Find(DefaultMat.FootstepData.FootstepTag, MaterialAsset))
			{
				// Could not get default footstep for some reason, check asset in BP_GameInstance
				return false;				
			}
		}
		
		// Get FootSet by movement type
		FHazeMaterialSet FootstepMaterialSet;
		if(MaterialAsset.FootSets.Find(InMovementType, FootstepMaterialSet))
		{
			// Get correct event by step type (0 = Left, 1 = Right, 2 = Release/Stop)
			// For movement types that don't use Left/Right i.e sliding or jumping Left/Right steps hold the same event

			if(FootstepMaterialSet.MaterialSet.Num() < int(InFoot) + 1)
			{					
				return false;
			}

			FootstepEvent = FootstepMaterialSet.MaterialSet[InFoot];
			return FootstepEvent != nullptr;
		}		

		return false;
	}

	bool GetMaterialEvent(const FName InMaterialTag, const FName& InMovementType,const EFootType FootMaterialType, const EFootType InFoot, UHazeAudioEvent&out FootstepEvent, bool& bOutIsBothFeet)
	{
		FName MaterialTag = InMaterialTag;
		CheckMovementOverrideMaterialTag(FootMaterialType, MaterialTag);

		// Get material asset by tag (FootstepTag set i audio physmat)
		UHazeAudioMaterialReferenceAsset MaterialAsset;
		if(!MaterialAssets.Find(MaterialTag, MaterialAsset))
		{
			// No material found, fallback to default
			if(!GetDefaultMaterial(MaterialAsset))
				return false;
		}
		
		FootstepEvent = GetMaterialMovementAudioEvent(MaterialAsset, InMovementType, InFoot, bOutIsBothFeet);
		return FootstepEvent != nullptr;
	}

	bool GetMaterialEvent(const FName InMaterialTag, const FName& InMovementType, const EHandTraceAction InHandAction, UHazeAudioEvent&out OutHandEvent)
	{
		FName MaterialTag = InMaterialTag;
		// Release in this case means hand.
		CheckMovementOverrideMaterialTag(EFootType::Release, MaterialTag);

		// Get material asset by tag (FootstepTag set i audio physmat)
		UHazeAudioMaterialReferenceAsset MaterialAsset;
		if(MaterialAssets.Find(MaterialTag, MaterialAsset))
		{
			// Get HandSet by movement type
			FHazeMaterialSet HandMaterialSet;
			if(MaterialAsset.HandSets.Find(InMovementType, HandMaterialSet))
			{
				// Get correct event by step type (0 = Plant/Start, 1 = Release/Stop
				OutHandEvent = HandMaterialSet.MaterialSet[InHandAction];
				return OutHandEvent != nullptr;
			}
		}

		return false;
	}

	private bool GetDefaultMaterial(UHazeAudioMaterialReferenceAsset& OutDefaultMaterial)
	{
		auto DefaultMat = Game::GetHazeGameInstance().GlobalAudioDataAsset.DefaultAudioPhysMat;

		if(DefaultMat == nullptr)
		{
			devCheck(false, "Failed to get default audio material! Check asset in BP_GameInstance");
			return false;	
		}

		if(!MaterialAssets.Find(DefaultMat.FootstepData.FootstepTag, OutDefaultMaterial))
			return false;

		return true;
	}

	private UHazeAudioEvent GetMaterialMovementAudioEvent(const UHazeAudioMaterialReferenceAsset& MaterialAsset, const FName& InMovementType, const EFootType InFoot, bool& bOutIsBothFeet)
	{
		UHazeAudioEvent FootstepEvent = nullptr;

		// Get FootSet by movement type
		FHazeMaterialSet FootstepMaterialSet;
		if(MaterialAsset.FootSets.Find(InMovementType, FootstepMaterialSet))
		{
			// Early out if material set is not using release
			if(InFoot == EFootType::Release && !FootstepMaterialSet.bHasRelease)
				return nullptr;

			// Get correct event by step type (0 = Left, 1 = Right, 2 = Release/Stop)
			// For movement types that don't use Left/Right i.e sliding or jumping Left/Right steps hold the same event

			if(FootstepMaterialSet.MaterialSet.Num() >= int(InFoot) + 1)
			{				
				bOutIsBothFeet = !FootstepMaterialSet.bIsLeftRight;
				FootstepEvent = FootstepMaterialSet.MaterialSet[InFoot];
			}
		}		

		// If we had a valid material reference asset, but there was no event set for this movement type, fallback to default
		if(FootstepEvent == nullptr)
		{				
			UHazeAudioMaterialReferenceAsset DefaultMat;
			if(GetDefaultMaterial(DefaultMat))
			{
				if(DefaultMat.FootSets.Find(InMovementType, FootstepMaterialSet))
				{
					// Get correct event by step type (0 = Left, 1 = Right, 2 = Release/Stop)
					// For movement types that don't use Left/Right i.e sliding or jumping Left/Right steps hold the same event

					if(FootstepMaterialSet.MaterialSet.Num() >= int(InFoot) + 1)
					{				
						bOutIsBothFeet = !FootstepMaterialSet.bIsLeftRight;
						FootstepEvent = FootstepMaterialSet.MaterialSet[InFoot];
					}
				}	
			}
		}

		return FootstepEvent;
	}
}