class USandSharkPlayerHeightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);
	default CapabilityTags.Add(n"SandSharkOnSand");
	default CapabilityTags.Add(n"SandSharkHeight");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UHazeMovementComponent MoveComp;
	USandSharkPlayerComponent PlayerComp;
	UPlayerSlideComponent SlideComp;
	UAnimFootTraceComponent FootTraceComp;

	FHazeAcceleratedFloat AccHeightOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = USandSharkPlayerComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Lower)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Lower)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AccHeightOffset.SnapTo(0);
		Player.MeshOffsetComponent.SetRelativeLocation(FVector::ZeroVector);

		if (FootTraceComp != nullptr)
			FootTraceComp.UnBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.HasGroundContact())
		{
			if (PlayerComp.bHasTouchedSand && !SlideComp.IsSlideActive())
			{
				AccHeightOffset.AccelerateTo(-35, 0.5, DeltaTime);
			}
			else
				AccHeightOffset.SnapTo(0);
		}
		else
		{
			AccHeightOffset.AccelerateTo(0, 0.25, DeltaTime);
		}
		Player.MeshOffsetComponent.SetRelativeLocation(FVector::UpVector * AccHeightOffset.Value);

		if (Math::IsNearlyZero(AccHeightOffset.Value, 3.0))
			FootTraceComp.UnBlock(this);
		else
			FootTraceComp.Block(this);
	}
};