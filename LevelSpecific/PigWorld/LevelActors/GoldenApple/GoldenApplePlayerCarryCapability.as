class UGoldenApplePlayerCarryCapability : UHazePlayerCapability
{
	//default CapabilityTags.Add(CapabilityTags::);
	default TickGroup = EHazeTickGroup::Gameplay;

	UGoldenApplePlayerComponent GoldenApplePlayerComp;
	UPlayerPigComponent PigComp;
	UPlayerMovementComponent PlayerMovementComp;

	AGoldenApple CurrentApple;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoldenApplePlayerComp = UGoldenApplePlayerComponent::Get(Player);
		PlayerMovementComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GoldenApplePlayerComp.CurrentApple == nullptr)
			return false;

		if (GoldenApplePlayerComp.bIsCarryingApple)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GoldenApplePlayerComp.CurrentApple == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (PigComp == nullptr) // PigComp gets added post Setup?
			PigComp = UPlayerPigComponent::Get(Player);

		CurrentApple = GoldenApplePlayerComp.CurrentApple;

		TListedActors<AHungryDoor> HungryDoors;
		for (AHungryDoor Door : HungryDoors)
			Door.EnableInteractionForPlayer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TListedActors<AHungryDoor> HungryDoors;
		for (AHungryDoor Door : HungryDoors)
		{
			Door.DisableInteractionForPlayer(Player);
		}

		GoldenApplePlayerComp.bIsCarryingApple = false;
		CurrentApple.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CurrentApple = nullptr;

		if (GoldenApplePlayerComp.bPlayingCarryingAnimation)
		{
			UAnimSequence OverrideAnimation = GoldenApplePlayerComp.AnimationData[Player].CarryJawOverrideAnimation;
			Player.StopOverrideAnimation(OverrideAnimation, 0.0);
			GoldenApplePlayerComp.bPlayingCarryingAnimation = false;

			// Play same animation in spring mesh
			UPlayerPigStretchyLegsComponent StretchyPigComponent = UPlayerPigStretchyLegsComponent::Get(Player);
			if (StretchyPigComponent != nullptr)
			{
				if (StretchyPigComponent.SpringyMeshComponent != nullptr)
				{
					FHazeStopOverrideAnimationParams StopOverrideParams;
					StopOverrideParams.Animation = OverrideAnimation;
					StopOverrideParams.BlendTime = 0.0;
					StretchyPigComponent.SpringyMeshComponent.StopOverrideAnimation(StopOverrideParams);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) {}
}