class UMoonMarketPlayerShapeshiftCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MoonMarketShapeShift");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketShapeshiftComponent ShapeshiftComp;

	UPlayerSwimmingComponent SwimComp;

	UPlayerMovementAudioComponent MovementAudioComp;

	AHazeActor CurrentShape;
	int ShapeId = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UMoonMarketShapeshiftComponent::GetOrCreate(Player);
		SwimComp = UPlayerSwimmingComponent::Get(Player);
		MovementAudioComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShapeshiftComp.IsShapeshiftActive())
			return true;

		if(ShapeId != ShapeshiftComp.NetId)
			return true;

		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(SwimComp.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShapeId = ShapeshiftComp.NetId + 1;
		Player.ShowCancelPrompt(this);

		MovementAudio::RequestBlock(this, MovementAudioComp, EMovementAudioFlags::Breathing);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//CurrentShape is set automatically in ShapeshiftInto but if that function is not being used make sure to set it manually
		check(CurrentShape != nullptr);

		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(CurrentShape, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
		
		if(ShapeshiftComp.IsShapeshiftActive() && CurrentShape == ShapeshiftComp.ShapeshiftShape.CurrentShape)
			ShapeshiftComp.ShapeshiftShape.StopInteraction(Player);

		auto PotionComp = UMoonMarketPotionInteractionComponent::Get(Player);
		PotionComp.StopCurrentInteraction();

		Player.RemoveCancelPromptByInstigator(this);
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));

		MovementAudio::RequestUnBlock(this, MovementAudioComp, EMovementAudioFlags::Breathing);
	}

	AHazeActor ShapeshiftInto(TSubclassOf<AHazeActor> ShapeClass)
	{
		AHazeActor Shape = SpawnActor(ShapeClass, bDeferredSpawn = true);
		Shape.MakeNetworked(this, ShapeshiftComp.NetId);
		FinishSpawningActor(Shape);
		CurrentShape = Shape;
		Shape.AttachToComponent(Player.MeshOffsetComponent, NAME_None, EAttachmentRule::SnapToTarget);
		ShapeshiftComp.Shapeshift(Shape);
		Player.Mesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
		
		return Shape;
	}

	void RemoveVisualBlocker()
	{
		Player.Mesh.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};