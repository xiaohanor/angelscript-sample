
UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/LaunchPointIconBillboardGradient.LaunchPointIconBillboardGradient", EditorSpriteOffset=""))
class UGrappleLaunchPointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default GrappleType = EGrapplePointVariations::LaunchPoint;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchVelocity = 2500.0;

	/*
	 * This is the position the center of the player will travel through when launched
	 * Value is relative to component up vector
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchHeightOffset = 0.0;
	
	/*
	 *	Should we consume AirDash/AirJump when launch is initiated 
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bConsumeAirActions = false;

	UPROPERTY()
	bool bUsePreferredDirection = false;

	/*
	 * Launch direction for player as long as they are inside the assigned acceptance range
	 * Length of vector is irrelevant as it will be normalised upon use
	 * > 0 to enable use / visualization
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector PreferredDirection;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bConstrainInput = false;

	/*
	* This is the total input constrain duration
	* If you want it blocked completely for 1 second with 1 second blend in after then set the BlockDuration = 2 and Blend in = 1
	*/
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bConstrainInput", EditConditionHides))
	float BlockInputDuration = 1;

	/**
	 * How long it takes to get full input back
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bConstrainInput", EditConditionHides))
	float InputBlendInDuration = 0;

	/*
	 *	Entry Angle range for direction assistance to kick in 
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUsePreferredDirection", EditConditionHides, ClampMin = "0.0", ClampMax = "180", UIMin = "0.0", UIMax = "180"), Category = "Settings")
	float AcceptanceDegrees = 30.0;

	/**
	 * Do you want to block specifically the camera lookat during launch
	 */
	UPROPERTY(EditInstanceOnly, Category = "Settings", AdvancedDisplay)
	bool BlockLaunchLookAt = false;

#if EDITOR
	/**
	 * Whether to visualize the player's launch trajectory from this launch point.
	 */
	UPROPERTY(EditAnywhere, Category = "Editor Visualization", Meta = (EditConditionHides, EditCondition = "bUsePreferredDirection"))
	bool bVisualizeLaunchTrajectory = true;

	/**
	 * How long the trajectory to visualize should be.
	 */
	UPROPERTY(EditAnywhere, Category = "Editor Visualization", Meta = (EditConditionHides, EditCondition = "bVisualizeLaunchTrajectory && bUsePreferredDirection"))
	float VisualizeLaunchTrajectoryDuration = 2.0;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(PreferredDirection.IsNearlyZero())
			bUsePreferredDirection = false;
		else
			bUsePreferredDirection = true;
	}
}

struct FGrappleLaunchPointTargetableSettings
{
	UPROPERTY(Category = "Grapple Settings", Meta = (ShowOnlyInnerProperties))
	FContextualMovesTargetableSettings ContextualSettings;

	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (MakeEditWidget = true))
	FVector PointOfInterestOffset;

	UPROPERTY(Category = "Grapple Settings", EditAnywhere, meta = (ClampMin="0.0"))
	float ActivationCooldown = 0.5;

	UPROPERTY(EditAnywhere, Category = "Grapple Settings")
	float LaunchVelocity = 2500.0;

	UPROPERTY(Category = "Grapple Settings")
	EGrappleImpactType ImpactType;

	/*
	 * This is the position the center of the player will travel through when launched
	 * Value is relative to component up vector
	 */
	UPROPERTY(EditAnywhere, Category = "Grapple Settings")
	float LaunchHeightOffset = 0.0;
	
	UPROPERTY(EditAnywhere, Category = "Grapple Settings")
	bool bUsePreferedDirection = false;

	/*
	 * Launch direction for player as long as they are inside the assigned acceptance range
	 * Length of vector is irrelevant as it will be normalised upon use
	 * > 0 to enable use / visualization
	 */
	UPROPERTY(EditAnywhere, Category = "Grapple Settings")
	FVector PreferedDirection;

	/*
	 *	Entry Angle range for direction assistance to kick in 
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUsePreferedDirection", EditConditionHides, ClampMin = "0.0", ClampMax = "180", UIMin = "0.0", UIMax = "180"), Category = "Grapple Settings")
	float AcceptanceDegrees = 30.0;

	void ApplyToTargetable(UGrappleLaunchPointComponent Component)
	{
		ContextualSettings.ApplyToTargetable(Component);
		Component.PointOfInterestOffset = PointOfInterestOffset;
		Component.ActivationCooldown = ActivationCooldown;
		Component.LaunchVelocity = LaunchVelocity;
		Component.LaunchHeightOffset = LaunchHeightOffset;
		Component.bUsePreferredDirection = bUsePreferedDirection;
		Component.PreferredDirection = PreferedDirection;
		Component.AcceptanceDegrees = AcceptanceDegrees;
		Component.ImpactEffectType = ImpactType;
	}

	void GatherFromTargetable(UGrappleLaunchPointComponent Component)
	{
		ContextualSettings.GatherFromTargetable(Component);
		PointOfInterestOffset = Component.PointOfInterestOffset;
		ActivationCooldown = Component.ActivationCooldown;
		LaunchVelocity = Component.LaunchVelocity;
		LaunchHeightOffset = Component.LaunchHeightOffset;
		bUsePreferedDirection = Component.bUsePreferredDirection;
		PreferedDirection = Component.PreferredDirection;
		AcceptanceDegrees = Component.AcceptanceDegrees;
	}
}

#if EDITOR
class UGrappleLaunchPointDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UGrappleLaunchPointComponent;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Settings", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Visuals", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable", CategoryType = EScriptDetailCategoryType::Important);
	}
}
#endif
