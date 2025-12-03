class UTundraPlayerShapeshiftingInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingActivation);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComponent;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FShapeShiftTriggerData& Data) const
	{
		if(Time::GetGameTimeSince(ShapeshiftingComponent.TimeOfLastShapeshiftFail) < ShapeshiftingComponent.Settings.FailDelay)
			return false;

		// Sometimes we cannot request an override feature, like if we are in a cutscene, delay activation until we can again.
		if(!Player.Mesh.CanRequestOverrideFeature())
			return false;

		FShapeShiftTriggerData ShapeActivation;
		ShapeActivation.bUseEffect = true;

		float TimeSinceLastShapeshift = Time::GameTimeSeconds - ShapeshiftingComponent.TimeOfLastShapeshift;
		if(TimeSinceLastShapeshift >= ShapeshiftingComponent.Settings.InputDelay)
		{
			if(WasActionStarted(ActionNames::PrimaryLevelAbility) 
				&& ShapeshiftingComponent.CurrentShapeType < ETundraShapeshiftShape::Big)
			{
				ShapeActivation.Type = ETundraShapeshiftShape(int(ShapeshiftingComponent.CurrentShapeType) + 1);
			}
			else if(WasActionStarted(ActionNames::SecondaryLevelAbility) &&
				ShapeshiftingComponent.CurrentShapeType > ETundraShapeshiftShape::Small)
			{
				ShapeActivation.Type = ETundraShapeshiftShape(int(ShapeshiftingComponent.CurrentShapeType) - 1);
			}
		}

		if(ShapeActivation.Type == ETundraShapeshiftShape::None)
			return false;

		ETundraShapeshiftActiveShape ActiveShape = ShapeshiftingComponent.GetActiveShapeTypeFromShapeType(ShapeActivation.Type);
		float TimeOfLastShapeshiftFromThisShape = ShapeshiftingComponent.TimeOfLastShapeshiftFromShape[ActiveShape];
		float TimeSinceLastShapeshiftFromThisShape = Time::GetGameTimeSince(TimeOfLastShapeshiftFromThisShape);
		if(TimeSinceLastShapeshiftFromThisShape < ShapeshiftingComponent.Settings.SameShapeInputDelay)
			return false;

		// if(ShapeshiftingComponent.ShapeTypeIsBlocked(ShapeActivation.Type))
		// 	return false;

		if(ShapeshiftingComponent.CurrentShapeType == ShapeActivation.Type)
			return false;

		Data = ShapeActivation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FShapeShiftTriggerData Data)
	{
		ShapeshiftingComponent.InputShapeRequest = Data;
	}

	// Since capabilities have to be active for at least one frame, this wont be cleared until next frame so the shapeshift will still happen,
	// unless this capability gets blocked before the shapeshift has time to activate which is what we want.
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ShapeshiftingComponent.InputShapeRequest = FShapeShiftTriggerData();
	}
}