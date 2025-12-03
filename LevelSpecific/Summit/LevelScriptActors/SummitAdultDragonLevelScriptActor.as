const FConsoleVariable CVar_SummitFreeflyEnabled("Summit.FreeflyEnabled", 0);
const FConsoleCommand Command_SummitActivateFreefly("Summit.ActivateFreefly", n"SummitActivateFreefly");
const FConsoleCommand Command_SummitDeactivateFreefly("Summit.DeactivateFreefly", n"SummitDeactivateFreefly");
const FConsoleCommand Command_SummitToggleFreefly("Summit.ToggleFreefly", n"SummitToggleFreefly");

local void SummitActivateFreefly(TArray<FString> Arguments)
{
	Console::SetConsoleVariableInt("Summit.FreeflyEnabled", 1, "", true);
	auto ClosestPlayerSpline = AdultDragonFreeFlying::FindClosestFreeFlySplineToLocation(Game::Mio.ActorCenterLocation);
	for (auto Player : Game::Players)
	{
		UPlayerAdultDragonComponent::Get(Player).SetFlightMode(EAdultDragonFlightMode::FreeFlying);
		UAdultDragonFreeFlyingComponent::Get(Player).SetRubberBandSpline(ClosestPlayerSpline);
	}
}

local void SummitDeactivateFreefly(TArray<FString> Arguments)
{
	Console::SetConsoleVariableInt("Summit.FreeflyEnabled", 0, "", true);
	for (auto Player : Game::Players)
	{
		UPlayerAdultDragonComponent::Get(Player).SetFlightMode(EAdultDragonFlightMode::Strafing);
	}
}

local void SummitToggleFreefly(TArray<FString> Arguments)
{
	if (Console::GetConsoleVariableInt("Summit.FreeflyEnabled") != 0)
	{
		SummitDeactivateFreefly(Arguments);
	}
	else
	{
		SummitActivateFreefly(Arguments);
	}
}

class ASummitAdultDragonLevelScriptActor : AHazeLevelScriptActor
{
	bool bIsPlayerRespawnSplineBlocked;

	UFUNCTION(BlueprintCallable, DevFunction)
	void SetFlightModeForBothPlayers(EAdultDragonFlightMode NewFlightMode)
	{
		for (auto Player : Game::Players)
		{
			auto DragonComp = UPlayerAdultDragonComponent::Get(Player);
			if (DragonComp == nullptr)
				break;
			DragonComp.SetFlightMode(NewFlightMode);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetFlightModeForPlayer(AHazePlayerCharacter Player, EAdultDragonFlightMode NewFlightMode)
	{
		auto DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DragonComp.SetFlightMode(NewFlightMode);
	}

	UFUNCTION(BlueprintCallable)
	void SetSplineToFollowForBothPlayers(AActor ActorWithSplineFollowComponent)
	{
		for (auto Player : Game::Players)
		{
			auto SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
			SplineFollowManagerComp.SetSplineToFollow(ActorWithSplineFollowComponent);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetRubberBandSplineForBothPlayers(AAdultDragonFreeFlyingRubberBandSpline RubberBandSplineActor)
	{
		for (auto Player : Game::Players)
		{
			auto FlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
			FlyingComp.SetRubberBandSpline(RubberBandSplineActor);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetSplineToFollowForPlayer(AHazePlayerCharacter Player, AActor ActorWithSplineFollowComponent)
	{
		auto SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		SplineFollowManagerComp.SetSplineToFollow(ActorWithSplineFollowComponent);
	}

	UFUNCTION(BlueprintCallable)
	void AddSplineToQueue(AHazePlayerCharacter Player, AActor ActorWithSplineFollowComponent)
	{
		auto SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		TArray<AActor> ActorsWithSplineFollowComponent;
		ActorsWithSplineFollowComponent.Add(ActorWithSplineFollowComponent);
		SplineFollowManagerComp.AddSplinesToQueue(ActorsWithSplineFollowComponent);
	}

	UFUNCTION(BlueprintCallable)
	void AddSplinesToQueue(AHazePlayerCharacter Player, TArray<AActor> ActorsWithSplineFollowComponent)
	{
		auto SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		SplineFollowManagerComp.AddSplinesToQueue(ActorsWithSplineFollowComponent);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void EnableFreeFlyForBothPlayersWithRubberBandSpline(AAdultDragonFreeFlyingRubberBandSpline RubberBandSplineActor)
	{
		SetFlightModeForBothPlayers(EAdultDragonFlightMode::FreeFlying);
		SetRubberBandSplineForBothPlayers(RubberBandSplineActor);
	}

	UFUNCTION(BlueprintCallable)
	void EnableStrafeForBothPlayersWithSplineFollow(AActor ActorWithSplineFollowComponent)
	{
		SetFlightModeForBothPlayers(EAdultDragonFlightMode::Strafing);
		SetSplineToFollowForBothPlayers(ActorWithSplineFollowComponent);
	}

	UFUNCTION(BlueprintCallable)
	void EnableStrafeForPlayerWithSplineFollow(AHazePlayerCharacter Player, AActor ActorWithSplineFollowComponent)
	{
		SetFlightModeForPlayer(Player, EAdultDragonFlightMode::Strafing);
		SetSplineToFollowForPlayer(Player, ActorWithSplineFollowComponent);
	}

	UFUNCTION(BlueprintCallable)
	void BlockDragonCamera(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Player.BlockCapabilities(AdultDragonCapabilityTags::AdultDragonCamera, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockDragonCamera(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Player.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragonCamera, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void SetDragonVisibility(bool bSetHidden, AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerAdultDragonComponent::Get(Player);
		Print("SetDragonVisibility: " + Player.Name + " " + bSetHidden);
		// DragonComp.GetAdultDragon().SetActorHiddenInGame(bSetHidden);

		if (bSetHidden)
		{
			Player.BlockCapabilities(CapabilityTags::Visibility, this);
			DragonComp.GetAdultDragon().BlockCapabilities(CapabilityTags::Visibility, this);
		}
		else
		{
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);
			DragonComp.GetAdultDragon().UnblockCapabilities(CapabilityTags::Visibility, this);
		}
	}

	UFUNCTION()
	void StartDragonTwirl(AHazePlayerCharacter Player, float Duration, int NrOfSpins)
	{
		auto DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DragonComp.Twirl(Duration, NrOfSpins);
	}

	UFUNCTION(BlueprintPure)
	AAdultDragon GetAdultDragon(AHazePlayerCharacter Player)
	{
		return UPlayerAdultDragonComponent::Get(Player).GetAdultDragon();
	}

	UFUNCTION(BlueprintCallable, Category = "DragonSword")
	void ActivateSword(EHazeSelectPlayer PlayerSelection, FInstigator Instigator)
	{
		TArray<AHazePlayerCharacter> SelectedPlayers;
		if (PlayerSelection == EHazeSelectPlayer::Mio)
		{
			SelectedPlayers.Add(Game::Mio);
		}
		else if (PlayerSelection == EHazeSelectPlayer::Zoe)
		{
			SelectedPlayers.Add(Game::Zoe);
		}
		else if (PlayerSelection == EHazeSelectPlayer::Both)
		{
			SelectedPlayers.Add(Game::Mio);
			SelectedPlayers.Add(Game::Zoe);
		}

		for (auto Player : SelectedPlayers)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			SwordComp.ActivateSword(Instigator);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "DragonSword")
	void MoveSwordsToBacks()
	{
		auto MioSwordComp = UDragonSwordUserComponent::Get(Game::Mio);
		auto ZoeSwordComp = UDragonSwordUserComponent::Get(Game::Zoe);
		MioSwordComp.MoveSwordToBack();
		ZoeSwordComp.MoveSwordToBack();
	}

	UFUNCTION(BlueprintCallable, Category = "DragonSword")
	void MoveSwordsToHands()
	{
		auto MioSwordComp = UDragonSwordUserComponent::Get(Game::Mio);
		auto ZoeSwordComp = UDragonSwordUserComponent::Get(Game::Zoe);
		MioSwordComp.MoveSwordToHand();
		ZoeSwordComp.MoveSwordToHand();
	}

	UFUNCTION(BlueprintCallable, Category = "DragonSword")
	void DeactivateSword(EHazeSelectPlayer PlayerSelection, FInstigator Instigator)
	{
		TArray<AHazePlayerCharacter> SelectedPlayers;
		if (PlayerSelection == EHazeSelectPlayer::Mio)
		{
			SelectedPlayers.Add(Game::Mio);
		}
		else if (PlayerSelection == EHazeSelectPlayer::Zoe)
		{
			SelectedPlayers.Add(Game::Zoe);
		}
		else if (PlayerSelection == EHazeSelectPlayer::Both)
		{
			SelectedPlayers.Add(Game::Mio);
			SelectedPlayers.Add(Game::Zoe);
		}

		for (auto Player : SelectedPlayers)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			SwordComp.DeactivateSword(Instigator);
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction, Category = "DragonSword")
	void ActivateSwordChargeAttackSheetForBothPlayers(EDragonSwordChargeAttack ChargeAttack)
	{
		for (auto Player : Game::Players)
		{
			auto SwordComp = UDragonSwordCombatUserComponent::Get(Player);
			if (SwordComp == nullptr)
				break;

			SwordComp.ActivateChargeAttackSheet(ChargeAttack);
		}
	}

	UFUNCTION(BlueprintCallable)
	void BlockSplinePlayerRespawn()
	{
		if (bIsPlayerRespawnSplineBlocked)
			return;

		bIsPlayerRespawnSplineBlocked = true;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.BlockCapabilities(n"StoneBeastPlayerRespawn", this);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockSplinePlayerRespawn()
	{
		if (!bIsPlayerRespawnSplineBlocked)
			return;

		bIsPlayerRespawnSplineBlocked = false;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.UnblockCapabilities(n"StoneBeastPlayerRespawn", this);
	}

	UFUNCTION(BlueprintCallable)
	void ShowStoneBeastHealth()
	{
		// TListedActors<AStoneBeastHealthManager>().GetSingle().ShowStoneBeastHealth();
	}

	UFUNCTION(BlueprintCallable)
	void HideStoneBeastHealth()
	{
		// TListedActors<AStoneBeastHealthManager>().GetSingle().HideStoneBeastHealth();
	}

	UFUNCTION(BlueprintCallable)
	void DamageStoneBeast(float Damage)
	{
		TListedActors<AStoneBeastHealthManager>().GetSingle().DamageStoneBeast(Damage);
	}

	UFUNCTION(BlueprintCallable)
	void SetStoneBeastHealth(float Value)
	{
		TListedActors<AStoneBeastHealthManager>().GetSingle().SetStoneBeastHealth(Value);
	}

	UFUNCTION(DevFunction)
	void DebugZoePlayerFollow()
	{
		Game::Zoe.BlockCapabilities(CapabilityTags::Movement, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::Input, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::Visibility, this);
		Game::Zoe.AttachToActor(Game::Mio, NAME_None, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(DevFunction)
	void DebugMioPlayerFollow()
	{
		Game::Mio.BlockCapabilities(CapabilityTags::Movement, this);
		Game::Mio.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Game::Mio.BlockCapabilities(CapabilityTags::Input, this);
		Game::Mio.BlockCapabilities(CapabilityTags::Visibility, this);
		Game::Mio.AttachToActor(Game::Zoe, NAME_None, EAttachmentRule::SnapToTarget);
	}
}