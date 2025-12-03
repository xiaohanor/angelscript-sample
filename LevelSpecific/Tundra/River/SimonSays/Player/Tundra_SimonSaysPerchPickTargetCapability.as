class UTundra_SimonSaysPerchPickTargetCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraSimonSays::SimonSaysPerchJump);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ATundra_SimonSaysManager Manager;
	UTundra_SimonSaysPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UTundra_SimonSaysPerchPointTargetable Internal_Targetable;
	UTundra_SimonSaysPerchPointTargetable QueuedTargetable;
	float TimeOfSetTargetable;

	const bool bDebug = false;
	const float SetTargetableCooldown = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = TundraSimonSays::GetManager();
		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Targetable", Internal_Targetable)
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.CurrentPerchedTile == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.CurrentPerchedTile == nullptr)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(CanSetTargetable() && QueuedTargetable != nullptr)
		{
			TrySetTargetable(QueuedTargetable);
			QueuedTargetable = nullptr;
		}

		TrySetTargetable(PlayerTargetablesComp.GetPrimaryTarget(UTundra_SimonSaysPerchPointTargetable));
		ACongaDanceFloorTile Tile = Targetable != nullptr ? Cast<ACongaDanceFloorTile>(Targetable.Owner) : nullptr;
		PlayerComp.CurrentPerchTarget = Tile;

		if(bDebug && Targetable != nullptr)
		{
			// Debug::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + (Targetable.WorldLocation - Player.ActorLocation).GetSafeNormal() * 200.0, 10.0, FLinearColor::Green);
			// Debug::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + MoveComp.MovementInput.GetSafeNormal() * 200.0, 10.0, FLinearColor::Red);
			Debug::DrawDebugSphere(Targetable.WorldLocation, 100.0, 12, FLinearColor::Red, 5);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.CurrentPerchTarget = nullptr;

		if(Internal_Targetable != nullptr)
			LocalSetTargetable(nullptr);
	}

	UTundra_SimonSaysPerchPointTargetable GetTargetable() const property
	{
		return Internal_Targetable;
	}

	void TrySetTargetable(UTundra_SimonSaysPerchPointTargetable Value)
	{
		if(!HasControl())
			return;

		bool bHasInput = !MoveComp.MovementInput.IsNearlyZero();
		bool bTargetableEnabled = Internal_Targetable == nullptr || !Internal_Targetable.IsDisabled();
		if(Value == nullptr && bHasInput && bTargetableEnabled)
			return;

		if(Value == Internal_Targetable)
			return;

		if(!CanSetTargetable())
		{
			QueuedTargetable = Value;
			return;
		}

		CrumbSetTargetable(Value);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTargetable(UTundra_SimonSaysPerchPointTargetable Value)
	{
		LocalSetTargetable(Value);
	}

	void LocalSetTargetable(UTundra_SimonSaysPerchPointTargetable Value)
	{
		if(Value != nullptr)
		{
			FTundra_SimonSaysMangerOnPlayerPickTargetEffectParams Params;
			Params.Targetable = Value;
			UTundra_SimonSaysManagerEffectHandler::Trigger_OnPlayerPickTarget(Manager, Params);
		}
		else
		{
			UTundra_SimonSaysManagerEffectHandler::Trigger_OnPlayerClearTarget(Manager);
		}
		TimeOfSetTargetable = Time::GetGameTimeSeconds();
		Internal_Targetable = Value;
	}

	bool CanSetTargetable() const
	{
		return Time::GetGameTimeSince(TimeOfSetTargetable) > SetTargetableCooldown;
	}
}