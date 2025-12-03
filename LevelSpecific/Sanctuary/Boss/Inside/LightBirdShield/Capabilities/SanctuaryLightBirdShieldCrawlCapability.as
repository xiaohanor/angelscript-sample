class USanctuaryLightBirdShieldCrawlCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	USanctuaryLightBirdShieldUserComponent UserComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

//		if (!UserComp.bIsCrawling.Get())
//			return false;

		if (!IsSelectedPlayer())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

		if (!IsSelectedPlayer())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"SanctuaryDarknessSlow", this);

		for (auto Settings : UserComp.Settings.DarknessCrawlSettings)
			Player.ApplySettings(Settings, this);
	
//		Player.PlaySlotAnimation(Animation = UserComp.DarknessCrawlAnim, bLoop = true, BlendTime = 0.5);

//		Player.ApplyCrouch(this);

		FVector ToOtherPlayerDirection = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).SafeNormal;
//		Player.SetMovementFacingDirection(ToOtherPlayerDirection.ToOrientationQuat());

//		for (auto Tag : UserComp.Settings.BlockTagsInDarkness)
//			Player.BlockCapabilities(Tag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"SanctuaryDarknessSlow", this);

		Player.ClearSettingsByInstigator(this);

//		Player.StopSlotAnimationByAsset(UserComp.DarknessCrawlAnim);

//		Player.ClearCrouch(this);

//		for (auto Tag : UserComp.Settings.BlockTagsInDarkness)
//			Player.UnblockCapabilities(Tag, this);

		MoveComp.ClearMovementInput(this);
	}

	bool IsSelectedPlayer() const
	{
		return Game::GetPlayersSelectedBy(UserComp.Settings.CrawlingPlayer).Contains(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"DarknessCrawl", this);
		
		FVector ToOtherPlayerDirection = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).SafeNormal;

		FVector MovementInput = ToOtherPlayerDirection.SafeNormal * Math::Max(0.0, GetAttributeVector2D(AttributeVectorNames::MovementRaw).X);

		FVector Up = ToOtherPlayerDirection.CrossProduct(Player.ActorRightVector).SafeNormal;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		FVector MovementDirection = Player.ActorTransform.TransformVectorNoScale(FVector(Input.X, Input.Y, 0.0));

		MovementInput = MovementDirection.ClampInsideCone(ToOtherPlayerDirection, 30.0).SafeNormal;

//		Player.SetMovementFacingDirection(MovementInput.ToOrientationQuat());
//		FVector MovementInput = ToOtherPlayerDirection.SafeNormal * Math::Max(0.0, GetAttributeVector2D(AttributeVectorNames::MovementRaw).X);
		MoveComp.ApplyMovementInput(MovementInput, this, EInstigatePriority::Override);
		PrintToScreen("Movement: " +  MoveComp.GetMovementInput(), 0.0, FLinearColor::Green);

	}
};