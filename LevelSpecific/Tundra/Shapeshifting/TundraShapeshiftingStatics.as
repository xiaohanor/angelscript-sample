namespace TundraShapeshiftingTags
{
	const FName Shapeshifting = n"Shapeshifting";
	const FName ShapeshiftingActivation = n"ShapeshiftingActivation";
	const FName ShapeshiftingInput = n"ShapeshiftingInput";
	const FName ShapeshiftingMorph = n"ShapeshiftingMorph";
	const FName ShapeshiftingMorphFail = n"ShapeshiftingMorphFail";
	const FName ShapeshiftingShape = n"ShapeshiftingShape";

	const FName TreeGuardian = n"TreeGuardian";
	const FName Fairy = n"Fairy";
	const FName Otter = n"Otter";
	const FName SnowMonkey = n"SnowMonkey";

	const FName SnowMonkeyThrow = n"SnowMonkeyThrow";
	const FName SnowMonkeyMovement = n"SnowMonkeyMovement";
	const FName SnowMonkeyGroundedGroundSlam = n"SnowMonkeyGroundedGroundSlam";
	const FName SnowMonkeyAirborneGroundSlam = n"SnowMonkeyAirborneGroundSlam";
	const FName SnowMonkeyCeilingClimb = n"SnowMonkeyCeilingClimb";
	const FName SnowMonkeyBossPunch = n"SnowMonkeyBossPunch";
	const FName SnowMonkeyBossPunching = n"SnowMonkeyBossPunching";
	const FName SnowMonkeyPunchInteract = n"SnowMonkeyPunchInteract";
	const FName SnowMonkeySinglePunchInteract = n"SnowMonkeySinglePunchInteract";
	const FName SnowMonkeyMultiPunchInteract = n"SnowMonkeyMultiPunchInteract";

	const FName TundraLifeGiving = n"TundraLifeGiving";

	const FName TundraLeap = n"TundraLeap";
	const FName TundraLeapCamera = n"TundraLeapCamera";
}

namespace TundraShapeshiftingStatics
{
	const FVector2D TreeGuardianCollisionSize = FVector2D(100,300);
	const FVector2D FairyCollisionSize = FVector2D(25,50);
	const FVector2D OtterCollisionSize = FVector2D(30,40);
	const FVector2D SnowMonkeyCollisionSize = FVector2D(100,135);

	const FHazeDevToggleCategory Shapeshifting = FHazeDevToggleCategory(n"Shapeshifting");
	const FHazeDevToggleBool StayInLifeGiving = FHazeDevToggleBool(Shapeshifting, n"Stay In Life Giving", "Will bring back the old behavior of staying in life giving if you let go of RT, and having to cancel out of it");

	UFUNCTION()
	float TundraGetGravityAmountForShape(AHazePlayerCharacter Player, ETundraShapeshiftShape Shape)
	{
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		return ShapeshiftComp.GetGravityAmountForShape(Shape);
	}

	UFUNCTION()
	float TundraGetTerminalVelocityForShape(AHazePlayerCharacter Player, ETundraShapeshiftShape Shape)
	{
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		return ShapeshiftComp.GetTerminalVelocityForShape(Shape);
	}

	UFUNCTION(BlueprintPure)
	bool TundraIsTreeGuardianBlocked()
	{
		return Game::Zoe.IsCapabilityTagBlocked(TundraShapeshiftingTags::TreeGuardian);
	}

	UFUNCTION(BlueprintPure)
	bool TundraIsFairyBlocked()
	{
		return Game::Zoe.IsCapabilityTagBlocked(TundraShapeshiftingTags::Fairy);
	}

	UFUNCTION(BlueprintPure)
	bool TundraIsMonkeyBlocked()
	{
		return Game::Mio.IsCapabilityTagBlocked(TundraShapeshiftingTags::SnowMonkey);
	}

	UFUNCTION(BlueprintPure)
	bool TundraIsOtterBlocked()
	{
		return Game::Mio.IsCapabilityTagBlocked(TundraShapeshiftingTags::Otter);
	}


	UFUNCTION()
	void TundraForceEnterCeilingClimb(AActor Actor)
	{
		auto CeilingClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
		devCheck(CeilingClimbComp != nullptr, "Can't call TundraForceEnterCeilingClimb on an actor without a CeilingClimb component");

		CeilingClimbComp.ForceEnterCeilingClimb();
	}

	UFUNCTION()
	void TundraOtterAddForceJumpOutOfInstigator(FInstigator Instigator)
	{
		auto OtterComp = UTundraPlayerOtterComponent::Get(Game::Mio);
		devCheck(OtterComp != nullptr, "Tried to get otter comp but wasn't able to!");
		OtterComp.AddForceJumpOutOfInstigator(Instigator);
	}

	UFUNCTION()
	void TundraOtterRemoveForceJumpOutOfInstigator(FInstigator Instigator)
	{
		auto OtterComp = UTundraPlayerOtterComponent::Get(Game::Mio);
		devCheck(OtterComp != nullptr, "Tried to get otter comp but wasn't able to!");
		OtterComp.RemoveForceJumpOutOfInstigator(Instigator);
	}

	UFUNCTION()
	void TundraAddGravityLerpBlocker(AHazePlayerCharacter Player, FInstigator Instigator, bool bRemoveWhenGravityCanBeSnapped = true)
	{
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.AddGravityLerpBlocker(Instigator, bRemoveWhenGravityCanBeSnapped);
	}

	UFUNCTION()
	void TundraRemoveGravityLerpBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.RemoveGravityLerpBlocker(Instigator);
	}

	UFUNCTION()
	void TundraShapeshiftingAddShapeBlockedShouldPlayFailEffectBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftingComp.AddShapeBlockedShouldPlayFailEffectBlocker(Instigator);
	}

	UFUNCTION()
	void TundraShapeshiftingRemoveShapeBlockedShouldPlayFailEffectBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftingComp.RemoveShapeBlockedShouldPlayFailEffectBlocker(Instigator);
	}
	
	UFUNCTION()
	AHazeCharacter TundraGetShapeshiftingActor(AHazePlayerCharacter Player, ETundraShapeshiftShape Shape)
	{
		if(Shape == ETundraShapeshiftShape::Player)
			return Player;

		return UTundraPlayerShapeshiftingComponent::Get(Player).GetShapeComponentForType(Shape).GetShapeActor();
	}

	/**
	 * For replaceables in cutscene renders too work, we need a BP function to call that doesn't take any parameters
	 */
	UFUNCTION(BlueprintPure)
	AHazeCharacter TundraGetShapeshiftActorMioBigShape()
	{
		return UTundraPlayerShapeshiftingComponent::Get(Game::Mio).GetShapeComponentForType(ETundraShapeshiftShape::Big).GetShapeActor();
	}

	UFUNCTION(BlueprintPure)
	AHazeCharacter TundraGetShapeshiftActorZoeBigShape()
	{
		return UTundraPlayerShapeshiftingComponent::Get(Game::Zoe).GetShapeComponentForType(ETundraShapeshiftShape::Big).GetShapeActor();
	}

	UFUNCTION(BlueprintPure)
	AHazeCharacter TundraGetShapeshiftActorZoeSmallShape()
	{
		return UTundraPlayerShapeshiftingComponent::Get(Game::Zoe).GetShapeComponentForType(ETundraShapeshiftShape::Small).GetShapeActor();
	}

	UFUNCTION(BlueprintPure)
	ETundraShapeshiftShape TundraGetCurrentShapeshiftShape(AHazePlayerCharacter Player)
	{
		return UTundraPlayerShapeshiftingComponent::Get(Player).GetCurrentShapeType();
	}

	UFUNCTION(BlueprintPure)
	AHazeCharacter TundraGetCurrentShapeshiftActor(AHazePlayerCharacter Player)
	{
		ETundraShapeshiftShape Shape = TundraGetCurrentShapeshiftShape(Player);

		if(Shape == ETundraShapeshiftShape::Player)
			return Player;

		return UTundraPlayerShapeshiftingComponent::Get(Player).GetShapeComponentForType(Shape).GetShapeActor();
	}
}