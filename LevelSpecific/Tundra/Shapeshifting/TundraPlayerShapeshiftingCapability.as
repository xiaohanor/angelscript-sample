struct FTundraShapeshiftingActivationData
{
	FShapeShiftTriggerData ShapeInfo;
	bool bFailed = false;
	bool bFailedBecauseOfBlock = false;
	bool bShouldOffsetLocation = false;
	FVector LocationOffset;
}

class UTundraPlayerShapeshiftingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingActivation);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	// Needs to be after tutorial in order for tutorial prompt to trigger action pressed
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComponent;
	UTundraPlayerShapeshiftingSettings Settings;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		Settings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(ShapeshiftingComponent.ForceShapeOverride.Type == ShapeshiftingComponent.CurrentShapeType)
			ShapeshiftingComponent.ForceShapeOverride = FShapeShiftTriggerData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraShapeshiftingActivationData& ActivationData) const
	{
		FShapeShiftTriggerData ShapeActivation;
		ShapeActivation.bUseEffect = true;

		// We have a external request
		if(ShapeshiftingComponent.ForceShapeOverride.Type != ETundraShapeshiftShape::None)
		{
			ShapeActivation = ShapeshiftingComponent.ForceShapeOverride;
		}
		// We have input request
		else if(ShapeshiftingComponent.InputShapeRequest.Type != ETundraShapeshiftShape::None)
		{
			ShapeActivation = ShapeshiftingComponent.InputShapeRequest;
		}

		if(ShapeActivation.Type == ETundraShapeshiftShape::None)
			return false;

		if(ShapeshiftingComponent.ShapeTypeIsBlocked(ShapeActivation.Type))
		{
			if(ShapeshiftingComponent.IsShapeBlockedShouldPlayFailEffectBlocked())
				return false;

			// If we are already fail morphing, don't bother starting a new fail morph!
			if(ShapeshiftingComponent.bIsFailMorphing)
				return false;

			ActivationData.bFailed = true;
			ActivationData.bFailedBecauseOfBlock = true;
			ActivationData.ShapeInfo = ShapeActivation;
			return true;
		}

		if(ShapeshiftingComponent.CurrentShapeType == ShapeActivation.Type)
			return false;

		bool bFailed = false;
		if(ShapeActivation.bCheckCollision)
		{
			bool bCollisionValid = ShapeshiftingComponent.IsCollisionValidForShapeshifting(ShapeshiftingComponent.CurrentShapeType, ShapeActivation.Type, ActivationData.bShouldOffsetLocation, ActivationData.LocationOffset);

			bFailed = !bCollisionValid;
			if(bFailed && ShapeshiftingComponent.bIsFailMorphing)
				return false;
		}

		ActivationData.bFailed = bFailed;
		ActivationData.ShapeInfo = ShapeActivation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraShapeshiftingActivationData ActivationData)
	{
		FShapeShiftTriggerData ShapeInfo = ActivationData.ShapeInfo;
		if(!Player.Mesh.CanRequestOverrideFeature())
			ShapeInfo.bUseEffect = false;

		if(!ActivationData.bFailed)
		{
			if(ActivationData.bShouldOffsetLocation)
			{
				Player.MeshOffsetComponent.FreezeLocationAndLerpBackToParent(this, Settings.MorphTime);
				Player.ActorLocation += ActivationData.LocationOffset;
				Player.ApplyBlendToCurrentView(1.0);
			}

			ShapeshiftingComponent.SetCurrentShape(ShapeInfo);
			ShapeshiftingComponent.TimeOfLastShapeshift = Time::GetGameTimeSeconds();
			ShapeshiftingComponent.FrameOfLastShapeshift = Time::FrameNumber;
			ShapeshiftingComponent.TimeOfLastShapeshiftFromShape[ShapeshiftingComponent.PreviousActiveShapeType] = Time::GetGameTimeSeconds();

			if(ShapeshiftingComponent.ShouldUseActivationEffect())
			{
				FTundraShapeshiftingEffectParams EffectParams;
				EffectParams.FromShape = ShapeshiftingComponent.PreviousShapeType;
				EffectParams.ToShape = ShapeshiftingComponent.CurrentShapeType;
				UTundraShapeshiftingEffectHandler::Trigger_OnShapeshift(Player, EffectParams);
			}

			if(ShapeInfo.Type != ETundraShapeshiftShape::Player &&
				ShapeshiftingComponent.GetShapeComponentForType(ShapeInfo.Type).ShouldConsumeShapeshiftInput())
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
				Player.ConsumeButtonInputsRelatedTo(ActionNames::SecondaryLevelAbility);
			}
		}
		else
		{
			ShapeshiftingComponent.ForceShapeOverride = FShapeShiftTriggerData();
			ShapeshiftingComponent.TimeOfLastShapeshiftFail = Time::GetGameTimeSeconds();

			if(ActivationData.bFailedBecauseOfBlock)
			{
				//Print("Heads up: Shapeshift failed because of the shape being blocked!", 5.f, FLinearColor::Yellow);
			}
			else
			{
				Print("Heads up: Shapeshift failed because of collision!", 5.f, FLinearColor::Yellow);
			}

			if(ShapeInfo.bUseEffect)
			{
				ShapeshiftingComponent.CurrentMorphFailShapeTarget = ShapeInfo.Type;
				ShapeshiftingComponent.PreviousMorphFailShapeTarget = ShapeshiftingComponent.CurrentShapeType;
			}
		}
	}
}