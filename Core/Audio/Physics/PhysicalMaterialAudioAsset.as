
enum EHazeAudioPhysicalMaterialHardnessType
{
	Soft,
	Hard
}

enum EHazeAudioPhysicalMaterialFrictionType
{
	Smooth,
	Rough
}

enum EHazeAudioPhysicalMaterialDebrisType
{
	AbilityBlastDebris,
	AbilityProjectileDebris,
	ExplosionDebris
}

enum EHazeAudioPhysicalMaterialTagType
{
	Footstep,
	ProjectileBulletImpact,
	AbilityProjectileDebris,
	AbilityBlastDebris,
	ExplosionDebris
}


namespace AudioPhysMaterial
{
	UFUNCTION(BlueprintPure)
	bool CanCauseRicochets(UPhysicalMaterialAudioAsset AudioPhysMat)
	{
		return AudioPhysMat != nullptr && AudioPhysMat.CanCauseRicochets();
	}

	UFUNCTION(BlueprintPure)
	bool CanCauseDebris(UPhysicalMaterialAudioAsset AudioPhysMat, const EHazeAudioPhysicalMaterialDebrisType DebrisType)
	{	
		return AudioPhysMat != nullptr && AudioPhysMat.CanCauseDebris(DebrisType);
	}

	UFUNCTION(BlueprintPure)
	bool CanCauseCloseProximity(UPhysicalMaterialAudioAsset AudioPhysMat)
	{
		return AudioPhysMat != nullptr && AudioPhysMat.CanCauseCloseProximity();
	}

	UFUNCTION(BlueprintPure)
	float GetProjectileImpactAttenuationScale(UPhysicalMaterialAudioAsset AudioPhysMat)
	{
		if (AudioPhysMat == nullptr)
			return 0;

		return AudioPhysMat.GetProjectileImpactAttenuationScale();
	}

	UFUNCTION(BlueprintPure, Meta)
	FName GetMaterialTag(UPhysicalMaterialAudioAsset AudioPhysMat,const EHazeAudioPhysicalMaterialTagType TagType)
	{
		if (AudioPhysMat == nullptr)
			return NAME_None;

		return AudioPhysMat.GetMaterialTag(TagType);
	}
}

class UPhysicalMaterialAudioAsset : UHazePhysicalMaterialAudioAsset
{
	UPROPERTY(EditDefaultsOnly)
	EHazeAudioPhysicalMaterialHardnessType HardnessType;

	UPROPERTY(EditDefaultsOnly)
	EHazeAudioPhysicalMaterialFrictionType FrictionType;

	bool CanCauseRicochets()
	{
		return WeaponProjectileData.bCanCauseRicochets;
	}

	bool CanCauseDebris(const EHazeAudioPhysicalMaterialDebrisType DebrisType)
	{	
		switch(DebrisType)
		{
			case(EHazeAudioPhysicalMaterialDebrisType::AbilityBlastDebris):
				return ForceDebrisData.bCanCauseDebris;

			case(EHazeAudioPhysicalMaterialDebrisType::AbilityProjectileDebris):
				return AbilityProjectileData.bCanCauseDebris;

			case(EHazeAudioPhysicalMaterialDebrisType::ExplosionDebris):
				return ExplosionDebrisData.bCanCauseDebris;

			default:
				return false;			
		}
	}

	bool CanCauseCloseProximity()
	{
		return ExplosionDebrisData.bCanCauseCloseProximity;
	}

	float GetProjectileImpactAttenuationScale()
	{
		return WeaponProjectileData.MaterialImpactAttenuationScale;
	}

	FName GetMaterialTag(const EHazeAudioPhysicalMaterialTagType TagType)
	{
		switch(TagType)
		{
			case(EHazeAudioPhysicalMaterialTagType::Footstep):
				return FootstepData.FootstepTag;
			case(EHazeAudioPhysicalMaterialTagType::ProjectileBulletImpact):
				return WeaponProjectileData.ProjectileTag;
			case(EHazeAudioPhysicalMaterialTagType::AbilityProjectileDebris):
				return AbilityProjectileData.AbilityProjectileTag;
			case(EHazeAudioPhysicalMaterialTagType::AbilityBlastDebris):
				return ForceDebrisData.ForceTag;
			case(EHazeAudioPhysicalMaterialTagType::ExplosionDebris):
				return ExplosionDebrisData.DebrisTag;
		}
	}
}