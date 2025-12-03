class UMoonMarketPolymorphPlayerCapability : UMoonMarketPlayerShapeshiftCapability
{
	default BlockExclusionTags.Add(n"PolymorphPotion");
	UPolymorphResponseComponent PolymorphComp;

	TSubclassOf<AHazeActor> MorphClass;

	UHazeCapabilitySheet CurrentSheet;

	UHazeMovementAudioComponent MoveAudioComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PolymorphComp = UPolymorphResponseComponent::Get(Player);
		UMoonMarketPolymorphAutoAimComponent::Get(Player).SetRelativeLocation(FVector::UpVector * 70);
		UMoonMarketPolymorphAutoAimComponent::Get(Player).OriginalRelativeLocation = FVector::UpVector * 70;

		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
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

	//Overriding ShouldDeactivate because polymorph should be able to switch forms in the same frame without caring about NetId being different
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShapeshiftComp.IsShapeshiftActive())
			return true;

		if(SwimComp.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if(HasControl())
			CrumbUpdateShape(PolymorphComp.DesiredMorphClass);

		Player.BlockCapabilities(PlayerMovementTags::Ladder, this);
		PolymorphComp.OnPolymorphTriggered.Broadcast();

		// Block breathing
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(CurrentSheet != nullptr)
		{
			Player.StopCapabilitySheet(CurrentSheet, this);
		}

		CurrentSheet = nullptr;
	

		Player.UnblockCapabilities(PlayerMovementTags::Ladder, this);

		// Unblock breathing
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);

		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();

		RemoveVisualBlocker();
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));

		MorphClass = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(PolymorphComp.DesiredMorphClass != nullptr && PolymorphComp.DesiredMorphClass != MorphClass)
			{
				CrumbUpdateShape(PolymorphComp.DesiredMorphClass);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbUpdateShape(TSubclassOf<AHazeActor> TargetMorphClass)
	{
		if(CurrentSheet != nullptr)
		{
			Player.StopCapabilitySheet(CurrentSheet, this);
			CurrentSheet = nullptr;
		}

		CurrentShape = ShapeshiftInto(TargetMorphClass);
		PolymorphComp.DesiredMorphClass = nullptr;

		auto ShapeComp = UMoonMarketPolymorphShapeComponent::Get(ShapeshiftComp.ShapeshiftShape.CurrentShape);
		if(ShapeComp != nullptr)
		{
			CurrentSheet = ShapeComp.Sheet;
			if(ShapeComp.Sheet != nullptr)
			{
				Player.StartCapabilitySheet(ShapeComp.Sheet, this);
			}
		}

		FVector CenterLocation = CurrentShape.ActorCenterLocation;
		UMoonMarketPolymorphAutoAimComponent::Get(Owner).SetWorldLocation(CenterLocation);
	}
};