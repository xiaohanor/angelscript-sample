class UMoonMarketNPCPolymorphCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;
	UPolymorphResponseComponent PolymorphComp;

	AHazeActor CurrentShape;
	TSubclassOf<AHazeActor> MorphClass;

	int MorphId = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PolymorphComp = UPolymorphResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PolymorphComp.DesiredMorphClass == nullptr)
			return false;

		if(PolymorphComp.DesiredMorphClass == MorphClass)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GetGameTimeSince(PolymorphComp.LastMorphTime) >= PolymorphComp.PolymorphDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
		
		if(HasControl())
			NetUpdateShape(PolymorphComp.DesiredMorphClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(CurrentShape != nullptr)
		{
			UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(CurrentShape, FMoonMarketPolymorphEventParams(PolymorphComp.ShapeshiftComp.ShapeData.ShapeTag, Owner));
			CurrentShape.DestroyActor();
		}

		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams(PolymorphComp.ShapeshiftComp.ShapeData.ShapeTag, Owner));
		PolymorphComp.ShapeshiftComp.UnsetShape();
		PolymorphComp.OnUnmorphed.Broadcast();
		Owner.RemoveActorVisualsBlock(this);
		Owner.RemoveActorCollisionBlock(this);
		MorphClass = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(PolymorphComp.DesiredMorphClass != nullptr && PolymorphComp.DesiredMorphClass != MorphClass)
		{
			NetUpdateShape(PolymorphComp.DesiredMorphClass);
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdateShape(TSubclassOf<AHazeActor> DesiredMorphClass)
	{
		if(CurrentShape != nullptr)
			CurrentShape.DestroyActor();

		PolymorphComp.LastMorphTime = Time::GameTimeSeconds;
		MorphClass = DesiredMorphClass;
		CurrentShape = SpawnActor(MorphClass);
		CurrentShape.MakeNetworked(this, MorphId);
		MorphId++;
		CurrentShape.AttachToActor(Owner);
		FMoonMarketShapeshiftShapeData ShapeData;

		auto ShapeComp = UMoonMarketPolymorphShapeComponent::Get(CurrentShape);
		if(ShapeComp != nullptr)
		{
			ShapeData = ShapeComp.ShapeData;
		}

		PolymorphComp.ShapeshiftComp.Shapeshift(CurrentShape);
		PolymorphComp.DesiredMorphClass = nullptr;

		FVector CenterLocation = CurrentShape.ActorCenterLocation;
		UMoonMarketPolymorphAutoAimComponent::Get(Owner).SetWorldLocation(CenterLocation);
	}
};