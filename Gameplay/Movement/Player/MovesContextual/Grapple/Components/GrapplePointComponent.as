UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/GrapplePointIconBillboardGradient.GrapplePointIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=65"))
class UGrapplePointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default GrappleType = EGrapplePointVariations::GrapplePoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	//Should players always perform an aerial flip exit regardless of tracing
	UPROPERTY(EditInstanceOnly, Category = "Settings", AdvancedDisplay)
	bool bForceAerialExit = false;

	//How far from ledge top do we allow a GrappleTo
	const float MaxHeightOffsetToLedge = 105;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if(ForwardVectorCutOffAngle > 75)
			ForwardVectorCutOffAngle = 75;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
}

struct FGrapplePointTargetableSettings
{
	UPROPERTY(Category = "Grapple Settings", Meta = (ShowOnlyInnerProperties))
	FContextualMovesTargetableSettings ContextualSettings;

	UPROPERTY(Category = "Grapple Settings")
	EGrappleImpactType ImpactType;

	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (MakeEditWidget = true))
	FVector PointOfInterestOffset;

	UPROPERTY(Category = "Grapple Settings", EditAnywhere, meta = (ClampMin="0.0"))
	float ActivationCooldown = 0.5;

	//Should players always perform an aerial flip exit regardless of tracing
	UPROPERTY(Category = "Grapple Settings", EditAnywhere, AdvancedDisplay)
	bool bForceAerialExit = false;

	void ApplyToTargetable(UGrapplePointComponent Component)
	{
		ContextualSettings.ApplyToTargetable(Component);
		Component.ActivationCooldown = ActivationCooldown;
		Component.bForceAerialExit = bForceAerialExit;
		Component.ImpactEffectType = ImpactType;
	}

	void GatherFromTargetable(UGrapplePointComponent Component)
	{
		ContextualSettings.GatherFromTargetable(Component);
		ActivationCooldown = Component.ActivationCooldown;
	}
}

#if EDITOR
class UGrapplePointComponentDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UGrapplePointComponent;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Settings", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Visuals", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable", CategoryType = EScriptDetailCategoryType::Important);
	}
}
#endif
