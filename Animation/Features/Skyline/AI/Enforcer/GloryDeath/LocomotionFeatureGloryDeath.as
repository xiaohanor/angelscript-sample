struct FLocomotionFeatureGloryDeathAnimData
{
	UPROPERTY(Category = "GloryDeath")
	TArray<FGravityBladeGloryDeathAnimationWithMetaData> GloryDeathVariants;

	UPROPERTY(Category = "GloryDeath")
	TArray<FGravityBladeGloryDeathAnimationWithMetaData> MioAirborneGloryDeaths;

	FGravityBladeGloryDeathAnimationWithMetaData GetAnimationFromName(FName AnimationName, bool bMioAirborne) const
	{
		const TArray<FGravityBladeGloryDeathAnimationWithMetaData>& GloryDeaths = bMioAirborne ? MioAirborneGloryDeaths : GloryDeathVariants;
		if(GloryDeaths.Num() == 0)
		{
			PrintError("GloryDeathVariants array in feature was empty!");
			return FGravityBladeGloryDeathAnimationWithMetaData();
		}

		for(int i = 0; i < GloryDeaths.Num(); i++)
		{
			if(GloryDeaths[i].AnimationName == AnimationName)
				return GloryDeaths[i];
		}

		PrintError(f"Glory death animation with name: {AnimationName.ToString()} not found in array!");

		return GloryDeaths[0];
	}

	FGravityBladeGloryDeathAnimationWithMetaData GetAnimationFromIndex(int Index, bool bMioAirborne) const
	{
		const TArray<FGravityBladeGloryDeathAnimationWithMetaData>& GloryDeaths = bMioAirborne ? MioAirborneGloryDeaths : GloryDeathVariants;
		if(GloryDeaths.Num() == 0)
		{
			Error(f"GloryDeathVariants array in feature was empty!");
			return FGravityBladeGloryDeathAnimationWithMetaData();
		}

		if(Index < 0 || Index >= GloryDeaths.Num())
		{
			Error(f"Glory death index {Index} was out of range (Num: {GloryDeaths.Num()})!");
			return FGravityBladeGloryDeathAnimationWithMetaData();
		}

		return GloryDeaths[Index];
	}

	void SanityCheck()
	{
		if (GloryDeathVariants.Num() == 0)
			PrintError(f"GloryDeathVariants array in feature was empty!");
		// if (MioAirborneGloryDeaths.Num() == 0)
		// 	PrintError(f"MioAirborneGloryDeaths array in feature was empty!");
	}
}

struct FGravityBladeGloryDeathAnimationWithMetaData
{
	UPROPERTY(EditDefaultsOnly)
	FName AnimationName;

	/* The animation that will be played when Mio's left foot animation is played */
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData MioLeftFootAnimation;

	/* The animation that will be played when Mio's right foot animation is played */
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData MioRightFootAnimation;

	// UPROPERTY(EditDefaultsOnly)
	// FGravityBladeGloryDeathAnimationMetaData MetaData;
}

struct FGravityBladeGloryDeathAnimationMetaData
{
	// Duration of the attack and accompanying animation.
	UPROPERTY(EditDefaultsOnly)
	float Duration = 0.5;

	// Total amount of units we move over the animation length, temporary until root motion can be retrieved.
	UPROPERTY(EditDefaultsOnly)
	float MovementLength = 150.0;
}

class ULocomotionFeatureGloryDeath : UHazeLocomotionFeatureBase
{
	default Tag = n"GloryDeath";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGloryDeathAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
