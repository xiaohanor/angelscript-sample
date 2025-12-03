class UTundraPlayerShapeshiftingMorphFailCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingMorph);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingMorphFail);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 2;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerShapeshiftingSettings Settings;

	ETundraShapeshiftShape FromShape = ETundraShapeshiftShape::None;
	ETundraShapeshiftShape ToShape = ETundraShapeshiftShape::Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		Settings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Currently displayed mesh is not 
		if(ShapeshiftingComp.CurrentMorphFailShapeTarget == ETundraShapeshiftShape::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerShapeshiftingMorphFailDeactivatedParams& Params) const
	{
		if(!ShapeshiftingComp.bIsFailMorphing)
			return true;

		if(ActiveDuration > Settings.MorphTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FromShape = ShapeshiftingComp.PreviousMorphFailShapeTarget;
		ToShape = ShapeshiftingComp.CurrentMorphFailShapeTarget;

		Player.Mesh.RequestOverrideFeature(n"ShapeshiftFail", this);
		Player.SetAnimIntParam(n"MorphDir", GetShapeshiftDirectionForShapes(FromShape, ToShape));

		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingMorph, this);
		FTundraShapeshiftingEffectParams EffectParams;
		EffectParams.FromShape = FromShape;
		EffectParams.ToShape = ToShape;
		UTundraShapeshiftingEffectHandler::Trigger_OnShapeshiftFail(Player, EffectParams);

		ShapeshiftingComp.bIsFailMorphing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerShapeshiftingMorphFailDeactivatedParams Params)
	{
		ShapeshiftingComp.bIsFailMorphing = false;
		ShapeshiftingComp.CurrentMorphFailShapeTarget = ETundraShapeshiftShape::None;
		ShapeshiftingComp.PreviousMorphFailShapeTarget = ETundraShapeshiftShape::None;
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingMorph, this);
	}

	int GetShapeshiftDirectionForShapes(ETundraShapeshiftShape From, ETundraShapeshiftShape To) const
	{
		return Math::Sign(int(To) - int(From));
	}
}

struct FTundraPlayerShapeshiftingMorphFailDeactivatedParams
{
	bool bShouldMorphOtherDirection = false;
}