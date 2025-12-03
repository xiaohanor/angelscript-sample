class UGameShowArenaBombTossPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default TickGroup = EHazeTickGroup::Movement;

	default DebugCategory = n"GameShow";
	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerMovementComponent MoveComp;

	UGameShowArenaPlatformPlayerReactionComponent PreviousComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		UPlayerHealthComponent::Get(Player).OnFinishDying.AddUFunction(this, n"OnFinishDying");
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION()
	private void OnFinishDying()
	{
		BombTossPlayerComponent.RemoveBomb();
		BombTossPlayerComponent.bHasIncomingBomb = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.Mesh.RequestOverrideFeature(n"GameShowBombOverride", this);
		UGameShowArenaPlatformPlayerReactionComponent CurrentComp = nullptr;
		bool bLeftPreviousPlatform = false;
		if (MoveComp.HasGroundContact())
		{
			CurrentComp = UGameShowArenaPlatformPlayerReactionComponent::Get(MoveComp.GroundContact.Actor);
			if (CurrentComp != nullptr)
			{
				if (PreviousComp != CurrentComp)
					bLeftPreviousPlatform = true;
				CurrentComp.HandlePlayerOnPlatform(Player);
			}
			else
				bLeftPreviousPlatform = true;
		}
		else
		{
			bLeftPreviousPlatform = true;
		}
		if (bLeftPreviousPlatform && PreviousComp != nullptr)
			PreviousComp.HandlePlayerLeavePlatform(Player);

		PreviousComp = CurrentComp;
		//Debug::DrawDebugSphere(Player.Mesh.GetSocketLocation(n"Backpack"), 20, 12, FLinearColor::Yellow, 5);
	}
};