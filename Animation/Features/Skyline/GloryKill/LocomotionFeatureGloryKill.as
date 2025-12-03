struct FLocomotionFeatureGloryKillAnimData
{
	UPROPERTY(Category = "GloryKill")
	TArray<FGravityBladeGloryKillAnimationLeftRightPair> GloryKillVariants;

	UPROPERTY(Category = "GloryKill")
	TArray<FGravityBladeGloryKillAnimationLeftRightPair> AirborneGloryKills;

	FGravityBladeGloryKillAnimationLeftRightPair GetAnimationFromName(FName AnimationName, bool bAirborne) const
	{
		const TArray<FGravityBladeGloryKillAnimationLeftRightPair>& GloryKills = bAirborne ? AirborneGloryKills : GloryKillVariants;

		if(GloryKills.Num() == 0)
		{
			Error("GloryKillVariants array in feature was empty!"); 
			return FGravityBladeGloryKillAnimationLeftRightPair();
		}

		for(int i = 0; i < GloryKills.Num(); i++)
		{
			if(GloryKills[i].AnimationName == AnimationName)
				return GloryKills[i];
		}

		Error(f"Glory kill animation with name: {AnimationName.ToString()} not found in array!");

		return GloryKills[0];
	}

	FGravityBladeGloryKillAnimationLeftRightPair GetAnimationFromIndex(int Index, bool bAirborne) const
	{
		const TArray<FGravityBladeGloryKillAnimationLeftRightPair>& GloryKills = bAirborne ? AirborneGloryKills : GloryKillVariants;

		if(GloryKills.Num() == 0)
		{			
			Error(f"GloryKillVariants array in feature was empty!");
			return FGravityBladeGloryKillAnimationLeftRightPair();
		}

		if(Index < 0 || Index >= GloryKills.Num())
		{
			Error(f"Glory kill index {Index} was out of range (Num: {GloryKills.Num()})!");
			return FGravityBladeGloryKillAnimationLeftRightPair();
		}

		return GloryKills[Index];
	}

	void SanityCheck()
	{
		if (GloryKillVariants.Num() == 0)
			PrintError(f"GloryKillVariants array in feature was empty!");
		// if (AirborneGloryKills.Num() == 0)
		// 	PrintError(f"AirborneGloryKills array in feature was empty!");
	}
}

struct FGravityBladeGloryKillAnimationLeftRightPair
{
	UPROPERTY(EditDefaultsOnly)
	FName AnimationName;

	UPROPERTY(EditDefaultsOnly)
	FGravityBladeGloryKillAnimationWithMetaData LeftAnimation;

	UPROPERTY(EditDefaultsOnly)
	FGravityBladeGloryKillAnimationWithMetaData RightAnimation;
}

struct FGravityBladeGloryKillAnimationWithMetaData
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySequenceData Animation;

	UPROPERTY(EditDefaultsOnly)
	FGravityBladeGloryKillAnimationMetaData MetaData;
}

struct FGravityBladeGloryKillAnimationMetaData
{
	// Duration of the attack and accompanying animation.
	UPROPERTY(EditDefaultsOnly)
	float Duration = 0.5;

	// Total amount of units we move over the animation length, temporary until root motion can be retrieved.
	UPROPERTY(EditDefaultsOnly)
	float MovementLength = 150.0;

	UPROPERTY(EditDefaultsOnly)
	FGravityBladeGloryKillAnimFeatureCameraSettings CameraSettings;

	UPROPERTY(EditDefaultsOnly, DisplayName = "POI Settings")
	FGravityBladeGloryKillAnimFeaturePOISettings POISettings;

	// Whether to allow the glory kill to happen even if it means falling off an edge
	UPROPERTY(EditDefaultsOnly)
	bool bAllowOverEdge = false;
	// Whether to allow the glory kill to happen even if it means running into a wall
	UPROPERTY(EditDefaultsOnly)
	bool bAllowIntoWall = true;

	// This glory kill should only be performed when target is farther away than this
	UPROPERTY(EditDefaultsOnly)
	float MinDistance = 0.0;
}

struct FGravityBladeGloryKillAnimFeatureCameraSettings
{
	// How fast camera settings blends in, -1 will mean it uses the default blend in time from the combat comp.
	UPROPERTY(EditDefaultsOnly)
	float BlendInTime = -1.0;

	// How fast camera settings blends out, -1 will mean it uses the default blend out time from the combat comp.
	UPROPERTY(EditDefaultsOnly)
	float BlendOutTime = -1.0;

	// Whether we should use the below pivot offset to override the pivot offset in the default camera settings from the combat comp.
	UPROPERTY(EditDefaultsOnly)
	bool bUsePivotOffset = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bUsePivotOffset"))
	FVector PivotOffset = FVector(100.0, -50.0, 100.0);

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUsePivotOffset"))
	bool bUseSeparatePivotOffsetIfEnforcerLeftOnScreen = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bUsePivotOffset && bUseSeparatePivotOffsetIfEnforcerLeftOnScreen"))
	FVector SeparatePivotOffset = FVector(100.0, 50.0, 100.0);

	UPROPERTY(EditDefaultsOnly)
	bool bUseFOV = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bUseFOV"))
	float FOV = 70.0;

	UPROPERTY(EditDefaultsOnly)
	bool bUseCameraOffset = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bUseCameraOffset"))
	FVector CameraOffset;
}

struct FGravityBladeGloryKillAnimFeaturePOISettings
{
	UPROPERTY(EditAnywhere)
	EGravityBladeGloryKillPOITargetType TargetType;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 0.5;

	UPROPERTY(EditAnywhere)
	FVector LocalOffset = FVector(150, 0, -20);

	UPROPERTY(EditAnywhere)
	bool bUseSeparateLocalOffsetIfEnforcerLeftOnScreen = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseSeparateLocalOffsetIfEnforcerLeftOnScreen"))
	FVector SeparateLocalOffset = FVector(150, 0, -20);
}

enum EGravityBladeGloryKillPOITargetType
{
	Player,
	Enforcer,
	PlayerAlignBone,
	PlayerHandBaseIK, 
	EnforcerAlignBone,
	InBetweenEnforcerPlayer,
	InBetweenPlayerAlignBonePlayer,
	InBetweenEnforcerAlignBonePlayer
}

class ULocomotionFeatureGloryKill : UHazeLocomotionFeatureBase
{
	default Tag = n"GloryKill";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGloryKillAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
