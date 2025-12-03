struct FPrefabData
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabProp> Props;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabSpotLight> SpotLights;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabPointLight> PointLights;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabChildPrefab> ChildPrefabs;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabNiagaraSystem> NiagaraSystems;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabHazeSphere> HazeSpheres;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabPropLine> PropLines;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabSpotSoundData> SpotSounds;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabDecalData> Decals;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePropSettings MergedMeshSettings;

	UPROPERTY(EditAnywhere, EditConst, BlueprintReadOnly)
	FTransform MergedMeshTransform;

	bool IsChanged(FPrefabData Other) const
	{
		if (Props.Num() != Other.Props.Num())
			return true;
		if (ChildPrefabs.Num() != Other.ChildPrefabs.Num())
			return true;
		if (SpotLights.Num() != Other.SpotLights.Num())
			return true;
		if (PointLights.Num() != Other.PointLights.Num())
			return true;
		if (NiagaraSystems.Num() != Other.NiagaraSystems.Num())
			return true;
		if (HazeSpheres.Num() != Other.HazeSpheres.Num())
			return true;
		if (PropLines.Num() != Other.PropLines.Num())
			return true;
		if (SpotSounds.Num() != Other.SpotSounds.Num())
			return true;
		if (Decals.Num() != Other.Decals.Num())
			return true;

		for (int i = 0, Count = Props.Num(); i < Count; ++i)
		{
			if (Props[i].IsChanged(Other.Props[i]))
				return true;
		}

		for (int i = 0, Count = ChildPrefabs.Num(); i < Count; ++i)
		{
			if (ChildPrefabs[i].IsChanged(Other.ChildPrefabs[i]))
				return true;
		}

		for (int i = 0, Count = SpotLights.Num(); i < Count; ++i)
		{
			if (SpotLights[i].IsChanged(Other.SpotLights[i]))
				return true;
		}

		for (int i = 0, Count = PointLights.Num(); i < Count; ++i)
		{
			if (PointLights[i].IsChanged(Other.PointLights[i]))
				return true;
		}

		for (int i = 0, Count = NiagaraSystems.Num(); i < Count; ++i)
		{
			if (NiagaraSystems[i].IsChanged(Other.NiagaraSystems[i]))
				return true;
		}

		for (int i = 0, Count = HazeSpheres.Num(); i < Count; ++i)
		{
			if (HazeSpheres[i].IsChanged(Other.HazeSpheres[i]))
				return true;
		}

		for (int i = 0, Count = PropLines.Num(); i < Count; ++i)
		{
			if (PropLines[i].IsChanged(Other.PropLines[i]))
				return true;
		}

		for (int i = 0, Count = SpotSounds.Num(); i < Count; ++i)
		{
			if (SpotSounds[i].IsChanged(Other.SpotSounds[i]))
				return true;
		}

		for (int i = 0, Count = Decals.Num(); i < Count; ++i)
		{
			if (Decals[i].IsChanged(Other.Decals[i]))
				return true;
		}

		if (!UHazePropComponent::AreSettingsEqual(MergedMeshSettings, Other.MergedMeshSettings))
			return true;
		if (!MergedMeshTransform.Equals(Other.MergedMeshTransform))
			return true;

		return false;
	}
};

class UPrefabAsset : UHazeBasePrefabAsset
{
#if EDITORONLY_DATA
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bAutoGenerateMergedMesh = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FPrefabData Data;

	UPROPERTY(EditAnywhere, EditConst, BlueprintReadOnly)
	TArray<FGuid> ChildPrefabChangeIds;

	UPROPERTY(EditAnywhere, EditConst, BlueprintReadOnly)
	FGuid ChangeId;
#endif
};

struct FPrefabProp
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FString Label;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePropSettings PropSettings;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	uint64 StaticComponentTags = 0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	bool IsChanged(FPrefabProp Other) const
	{
		return Guid != Other.Guid
			|| Label != Other.Label
			|| !Transform.Equals(Other.Transform)
			|| !UHazePropComponent::AreSettingsEqual(PropSettings, Other.PropSettings)
			|| StaticComponentTags != Other.StaticComponentTags
			|| AttachedTo != Other.AttachedTo;
	}
};

struct FPrefabChildPrefab
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FString Label;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UPrefabAsset PrefabAsset;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	bool IsChanged(FPrefabChildPrefab Other) const
	{
		return Guid != Other.Guid
			|| Label != Other.Label
			|| !Transform.Equals(Other.Transform)
			|| PrefabAsset != Other.PrefabAsset
			|| AttachedTo != Other.AttachedTo;
	}
};

struct FPrefabLightData
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float Intensity;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float IndirectLightingIntensity;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float VolumetricScatteringIntensity;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float Temperature;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MaxDrawDistance;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MaxDistanceFadeRange;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float DynamicShadowFadeStartDistance;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float DynamicShadowFadeEndDistance;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FLinearColor LightColor;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bAffectsWorld;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bCastShadows;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bCastStaticShadows;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bCastDynamicShadows;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bAffectTranslucentLighting;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bCastVolumetricShadow;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bUseTemperature;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float ShadowBias;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float ShadowSlopeBias;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SpecularScale;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float ShadowResolutionScale;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float AttenuationRadius;

	void SetFromLight(ULocalLightComponent Light)
	{
		Intensity = Light.Intensity;
		IndirectLightingIntensity = Light.IndirectLightingIntensity;
		VolumetricScatteringIntensity = Light.VolumetricScatteringIntensity;
		Temperature = Light.Temperature;
		MaxDrawDistance = Light.MaxDrawDistance;
		MaxDistanceFadeRange = Light.MaxDistanceFadeRange;
		DynamicShadowFadeStartDistance = Light.DynamicShadowFadeStartDistance;
		DynamicShadowFadeEndDistance = Light.DynamicShadowFadeEndDistance;
		LightColor = Light.LightColor;
		bAffectsWorld = Light.bAffectsWorld;
		bCastShadows = Light.CastShadows;
		bCastStaticShadows = Light.CastStaticShadows;
		bCastDynamicShadows = Light.CastDynamicShadows;
		bAffectTranslucentLighting = Light.bAffectTranslucentLighting;
		bCastVolumetricShadow = Light.bCastVolumetricShadow;
		bUseTemperature = Light.bUseTemperature;
		ShadowBias = Light.ShadowBias;
		ShadowSlopeBias = Light.ShadowSlopeBias;
		SpecularScale = Light.SpecularScale;
		ShadowResolutionScale = Light.ShadowResolutionScale;
		AttenuationRadius = Light.AttenuationRadius;
	}

#if EDITOR
	void Editor_AssignToLight(ULocalLightComponent Light) const
	{
		Light.SetIntensity(Intensity);
		Light.SetIndirectLightingIntensity(IndirectLightingIntensity);
		Light.SetVolumetricScatteringIntensity(VolumetricScatteringIntensity);
		Light.Temperature = Temperature;
		Light.MaxDrawDistance = MaxDrawDistance;
		Light.MaxDistanceFadeRange = MaxDistanceFadeRange;
		Light.DynamicShadowFadeStartDistance = DynamicShadowFadeStartDistance;
		Light.DynamicShadowFadeEndDistance = DynamicShadowFadeEndDistance;
		Light.LightColor = LightColor;
		Light.bAffectsWorld = bAffectsWorld;
		Light.CastShadows = bCastShadows;
		Light.CastStaticShadows = bCastStaticShadows;
		Light.CastDynamicShadows = bCastDynamicShadows;
		Light.bAffectTranslucentLighting = bAffectTranslucentLighting;
		Light.bCastVolumetricShadow = bCastVolumetricShadow;
		Light.bUseTemperature = bUseTemperature;
		Light.ShadowBias = ShadowBias;
		Light.ShadowSlopeBias = ShadowSlopeBias;
		Light.SpecularScale = SpecularScale;
		Light.ShadowResolutionScale = ShadowResolutionScale;
		Light.AttenuationRadius = AttenuationRadius;
	}
#endif

	bool IsChanged(FPrefabLightData Other) const
	{
		return
			Intensity != Other.Intensity
			|| IndirectLightingIntensity != Other.IndirectLightingIntensity
			|| VolumetricScatteringIntensity != Other.VolumetricScatteringIntensity
			|| Temperature != Other.Temperature
			|| MaxDrawDistance != Other.MaxDrawDistance
			|| MaxDistanceFadeRange != Other.MaxDistanceFadeRange
			|| DynamicShadowFadeStartDistance != Other.DynamicShadowFadeStartDistance
			|| DynamicShadowFadeEndDistance != Other.DynamicShadowFadeEndDistance
			|| LightColor != Other.LightColor
			|| bAffectsWorld != Other.bAffectsWorld
			|| bCastShadows != Other.bCastShadows
			|| bCastStaticShadows != Other.bCastStaticShadows
			|| bCastDynamicShadows != Other.bCastDynamicShadows
			|| bAffectTranslucentLighting != Other.bAffectTranslucentLighting
			|| bCastVolumetricShadow != Other.bCastVolumetricShadow
			|| bUseTemperature != Other.bUseTemperature
			|| ShadowBias != Other.ShadowBias
			|| ShadowSlopeBias != Other.ShadowSlopeBias
			|| SpecularScale != Other.SpecularScale
			|| ShadowResolutionScale != Other.ShadowResolutionScale
			|| AttenuationRadius != Other.AttenuationRadius
		;
	}
};

struct FPrefabSpotLight
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FPrefabLightData LightData;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bUseInverseSquaredFalloff;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float LightFalloffExponent;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SourceRadius;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SoftSourceRadius;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SourceLength;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float InnerConeAngle;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float OuterConeAngle;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float EditorBillboardScale;

	bool IsChanged(FPrefabSpotLight Other) const
	{
		return Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| InnerConeAngle != Other.InnerConeAngle
			|| OuterConeAngle != Other.OuterConeAngle
			|| LightData.IsChanged(Other.LightData)
			|| bUseInverseSquaredFalloff != Other.bUseInverseSquaredFalloff
			|| LightFalloffExponent != Other.LightFalloffExponent
			|| SourceRadius != Other.SourceRadius
			|| SoftSourceRadius != Other.SoftSourceRadius
			|| SourceLength != Other.SourceLength
			|| EditorBillboardScale != Other.EditorBillboardScale
		;
	}

	void SetFromLight(USpotLightComponent Light)
	{
		LightData.SetFromLight(Light);
		InnerConeAngle = Light.InnerConeAngle;
		OuterConeAngle = Light.OuterConeAngle;
		bUseInverseSquaredFalloff = Light.bUseInverseSquaredFalloff;
		LightFalloffExponent = Light.LightFalloffExponent;
		SourceRadius = Light.SourceRadius;
		SoftSourceRadius = Light.SoftSourceRadius;
		SourceLength = Light.SourceLength;
	}

#if EDITOR
	void Editor_AssignToLight(USpotLightComponent Light) const
	{
		LightData.Editor_AssignToLight(Light);
		Light.InnerConeAngle = InnerConeAngle;
		Light.OuterConeAngle = OuterConeAngle;
		Light.bUseInverseSquaredFalloff = bUseInverseSquaredFalloff;
		Light.LightFalloffExponent = LightFalloffExponent;
		Light.SourceRadius = SourceRadius;
		Light.SoftSourceRadius = SoftSourceRadius;
		Light.SourceLength = SourceLength;
	}
#endif
};

struct FPrefabPointLight
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FPrefabLightData LightData;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bUseInverseSquaredFalloff;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float LightFalloffExponent;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SourceRadius;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SoftSourceRadius;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SourceLength;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float EditorBillboardScale;

	bool IsChanged(FPrefabPointLight Other) const
	{
		return Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| bUseInverseSquaredFalloff != Other.bUseInverseSquaredFalloff
			|| LightFalloffExponent != Other.LightFalloffExponent
			|| SourceRadius != Other.SourceRadius
			|| SoftSourceRadius != Other.SoftSourceRadius
			|| SourceLength != Other.SourceLength
			|| LightData.IsChanged(Other.LightData)
			|| EditorBillboardScale != Other.EditorBillboardScale
		;
	}

	void SetFromLight(UPointLightComponent Light)
	{
		LightData.SetFromLight(Light);
		bUseInverseSquaredFalloff = Light.bUseInverseSquaredFalloff;
		LightFalloffExponent = Light.LightFalloffExponent;
		SourceRadius = Light.SourceRadius;
		SoftSourceRadius = Light.SoftSourceRadius;
		SourceLength = Light.SourceLength;
	}

#if EDITOR
	void Editor_AssignToLight(UPointLightComponent Light) const
	{
		LightData.Editor_AssignToLight(Light);
		Light.bUseInverseSquaredFalloff = bUseInverseSquaredFalloff;
		Light.LightFalloffExponent = LightFalloffExponent;
		Light.SourceRadius = SourceRadius;
		Light.SoftSourceRadius = SoftSourceRadius;
		Light.SourceLength = SourceLength;
	}
#endif
};

struct FPrefabNiagaraSystem
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UNiagaraSystem NiagaraSystem;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FHazeNiagaraPrimitiveVariable> Variables;

	bool IsChanged(FPrefabNiagaraSystem Other) const
	{
		return Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| NiagaraSystem != Other.NiagaraSystem
			|| Variables != Other.Variables
		;
	}
};

struct FPrefabHazeSphere
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
    EFogVolume Type;

	UPROPERTY(EditAnywhere)
    float Opacity;
    
    UPROPERTY(EditAnywhere)
    float Softness;
    
    UPROPERTY(EditAnywhere)
    EColorType ColorType;

    UPROPERTY(EditAnywhere)
    bool bLinear;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Temperature", EditConditionHides))
    FLinearColor ColorA;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Gradient", EditConditionHides))
    FLinearColor ColorB;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MinTemperature;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MaxTemperature;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Contrast;
	
    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Offset;

    UPROPERTY(EditAnywhere)
    bool bApplyFog;

    UPROPERTY(EditAnywhere)
	int TranslucencyPriority;

    UPROPERTY(EditAnywhere)
	float CullingDistanceMultiplier;

    UPROPERTY(EditAnywhere)
	float EditorBillboardScale;

    UPROPERTY(EditAnywhere)
    bool bBackgroundOnly;

	bool IsChanged(FPrefabHazeSphere Other) const
	{
		return Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| Type != Other.Type
			|| Opacity != Other.Opacity
			|| Softness != Other.Softness
			|| bLinear != Other.bLinear
			|| ColorType != Other.ColorType
			|| ColorA != Other.ColorA
			|| ColorB != Other.ColorB
			|| MinTemperature != Other.MinTemperature
			|| MaxTemperature != Other.MaxTemperature
			|| Contrast != Other.Contrast
			|| Offset != Other.Offset
			|| bApplyFog != Other.bApplyFog
			|| TranslucencyPriority != Other.TranslucencyPriority
			|| CullingDistanceMultiplier != Other.CullingDistanceMultiplier
			|| EditorBillboardScale != Other.EditorBillboardScale
			|| bBackgroundOnly != Other.bBackgroundOnly
		;
	}
};

struct FPrefabPropLine
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UPropLinePreset Preset = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPropLineMergedMeshData> MergedMeshes;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FPropLineSettings Settings;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EPropLineType Type = EPropLineType::StaticMeshes;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EPropLineDistributionType MeshDistribution = EPropLineDistributionType::DistributePerSegment;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EPropLineStretchType MeshStretching = EPropLineStretchType::StretchLastMeshInSegment;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPropLineSegment> Segments;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	int RandomizeTweak = 0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MaximumMergedMeshSize = 100000.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazeSplineSettings SplineSettings;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FHazeSplinePoint> SplinePoints;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabPropLineStaticMeshElement> StaticMeshElements;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FPrefabPropLineSplineMeshElement> SplineMeshElements;

	bool IsChanged(FPrefabPropLine Other) const
	{
		if (StaticMeshElements.Num() != Other.StaticMeshElements.Num())
			return true;

		for (int i = 0, Count = StaticMeshElements.Num(); i < Count; ++i)
		{
			if (StaticMeshElements[i].IsChanged(Other.StaticMeshElements[i]))
				return true;
		}

		if (SplineMeshElements.Num() != Other.SplineMeshElements.Num())
			return true;

		for (int i = 0, Count = SplineMeshElements.Num(); i < Count; ++i)
		{
			if (SplineMeshElements[i].IsChanged(Other.SplineMeshElements[i]))
				return true;
		}

		return Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| Preset != Other.Preset
			|| MergedMeshes != Other.MergedMeshes
			|| Settings != Other.Settings
			|| Type != Other.Type
			|| MeshDistribution != Other.MeshDistribution
			|| MeshStretching != Other.MeshStretching
			|| RandomizeTweak != Other.RandomizeTweak
			|| MaximumMergedMeshSize != Other.MaximumMergedMeshSize
			|| Segments != Other.Segments
			|| SplineSettings != Other.SplineSettings
			|| SplinePoints != Other.SplinePoints
		;
	}
}

struct FPrefabPropLineStaticMeshElement
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName ElementName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePropSettings PropSettings;

	bool IsChanged(FPrefabPropLineStaticMeshElement Other) const
	{
		return !Transform.Equals(Other.Transform)
			|| !UHazePropComponent::AreSettingsEqual(PropSettings, Other.PropSettings)
		;
	}

	int opCmp(FPrefabPropLineStaticMeshElement Other) const
	{
		return ElementName.Compare(Other.ElementName);
	}
};

struct FPrefabPropLineSplineMeshElement
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName ElementName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePropSettings PropSettings;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector2D StartScale;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector2D EndScale;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector StartLocation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector EndLocation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector StartTangent;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector EndTangent;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float EndRoll;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector SplineUpDir;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	ESplineMeshAxis ForwardAxis;

	bool IsChanged(FPrefabPropLineSplineMeshElement Other) const
	{
		if (!Transform.Equals(Other.Transform))
			return true;
		if (!UHazePropComponent::AreSettingsEqual(PropSettings, Other.PropSettings))
			return true;
		if (!StartScale.Equals(Other.StartScale))
			return true;
		if (!EndScale.Equals(Other.EndScale))
			return true;
		if (!StartLocation.Equals(Other.StartLocation))
			return true;
		if (!EndLocation.Equals(Other.EndLocation))
			return true;
		if (!StartTangent.Equals(Other.StartTangent))
			return true;
		if (!EndTangent.Equals(Other.EndTangent))
			return true;
		if (EndRoll != Other.EndRoll)
			return true;
		if (!SplineUpDir.Equals(Other.SplineUpDir))
			return true;
		if (ForwardAxis != Other.ForwardAxis)
			return true;
		return false;
	}

	int opCmp(FPrefabPropLineSplineMeshElement Other) const
	{
		return ElementName.Compare(Other.ElementName);
	}
};

struct FPrefabSpotSoundData
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UObject Asset;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float AttenuationScale;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TMap<UHazeAudioRtpc, float> DefaultRtpcs;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<FHazeAudioNodePropertyParam> NodeProperties;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bLinkedToZone = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bFollowRelevance = false;

	bool IsChanged(FPrefabSpotSoundData Other) const
	{
		if (Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| Asset != Other.Asset
			|| AttenuationScale != Other.AttenuationScale
			|| NodeProperties != Other.NodeProperties
			|| bLinkedToZone != Other.bLinkedToZone
			|| bFollowRelevance != Other.bFollowRelevance
		)
		{
			return true;
		}

		if (DefaultRtpcs.Num() != Other.DefaultRtpcs.Num())
			return true;
		for (auto Elem : DefaultRtpcs)
		{
			if (!Other.DefaultRtpcs.Contains(Elem.Key))
				return true;
			if (Other.DefaultRtpcs[Elem.Key] != Elem.Value)
				return true;
		}

		return false;
	}
};

struct FPrefabDecalData
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid Guid;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FTransform Transform;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FGuid AttachedTo;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector DecalSize;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FLinearColor DecalColor;

	bool IsChanged(FPrefabDecalData Other) const
	{
		if (Guid != Other.Guid
			|| !Transform.Equals(Other.Transform)
			|| AttachedTo != Other.AttachedTo
			|| Material != Other.Material
			|| DecalSize != Other.DecalSize
			|| DecalColor != Other.DecalColor
		)
		{
			return true;
		}

		return false;
	}
};