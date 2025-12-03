enum ETundraPlayerCrackBirdState
{
	None,
	WalkingToBird,
	PickingUp,
	Carrying,
	WalkingToNest,
	PuttingDown
}

class UBigCrackBirdCarryComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	ABigCrackBird CurrentBird;
	private ABigCrackBirdNest NestToPlaceIn;
	private ETundraPlayerCrackBirdState CurrentState = ETundraPlayerCrackBirdState::None;
	private bool bBlockedCapabilities = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UPlayerHealthComponent::Get(Player).OnReviveTriggered.AddUFunction(this, n"OnRevive");
	}

	UFUNCTION()
	private void OnRevive()
	{
		if(CurrentBird != nullptr)
		{
			auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			FShapeShiftTriggerData Data;
			Data.Type = ETundraShapeshiftShape::Big;
			ShapeshiftComp.SetCurrentShape(Data);
		}
	}

	private void SetState(ETundraPlayerCrackBirdState NewState)
	{
		CurrentState = NewState;
	}

	void ForceSetBird(ABigCrackBird Bird)
	{
		CurrentBird = Bird;
		CurrentBird.bNetWasForcedAttach = true;
		CurrentState = ETundraPlayerCrackBirdState::Carrying;
		Bird.AddActorCollisionBlock(this);

		if(bBlockedCapabilities)
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	void BlockCapabilities()
	{
		if(bBlockedCapabilities)
			return;

		Player.BlockCapabilities(TundraShapeshiftingTags::TundraLifeGiving, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);
		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);

		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyPunchInteract, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyCeilingClimb, this);

		bBlockedCapabilities = true;
	}

	void UnblockCapabilities()
	{
		if(!bBlockedCapabilities)
			return;

		Player.UnblockCapabilities(TundraShapeshiftingTags::TundraLifeGiving, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);

		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyPunchInteract, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyCeilingClimb, this);

		bBlockedCapabilities = false;
	}

	void SetBirdPickupTarget(ABigCrackBird Bird)
	{
		check(CurrentState == ETundraPlayerCrackBirdState::None);
		SetState(ETundraPlayerCrackBirdState::WalkingToBird);
		BlockCapabilities();

		CurrentBird = Bird;
		Bird.AddActorCollisionBlock(this);

		if(HasControl())
			CurrentBird.NetSetInteractingPlayer(Player);

		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		if(ShapeshiftComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
			Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);

		ShapeshiftComp.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	void StartPickingUpBird()
	{
		check(CurrentState == ETundraPlayerCrackBirdState::WalkingToBird);

		if(CurrentBird.InteractingPlayer == Player)
		{	
			SetState(ETundraPlayerCrackBirdState::PickingUp);
			CurrentBird.SetState(ETundraCrackBirdState::PickupStarted);
			CurrentBird.bIsPrimed = false;
			UBigCrackBirdEffectHandler::Trigger_LiftFromNest(CurrentBird, FTundraBigCrackBirdPlayerParams(Player));
		}
		else
		{
			CancelPickingUp();
		}
	}

	void AttachBird()
	{
		CurrentBird.CurrentNest.Bird = nullptr;
		CurrentBird.CurrentNest = nullptr;
		CurrentBird.SetState(ETundraCrackBirdState::PickedUp);
		auto PlayerMeshComp = UTundraPlayerShapeshiftingComponent::Get(Owner).GetMeshForShapeType(ETundraShapeshiftShape::Big);
		CurrentBird.RootComp.AttachToComponent(PlayerMeshComp, n"RightAttach", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	void FinishPickingUpBird()
	{
		check(CurrentState == ETundraPlayerCrackBirdState::PickingUp);
		SetState(ETundraPlayerCrackBirdState::Carrying);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	void SetBirdPutDownTarget(ABigCrackBirdNest Nest)
	{
		check(CurrentState == ETundraPlayerCrackBirdState::Carrying);
		SetState(ETundraPlayerCrackBirdState::WalkingToNest);
		Nest.Interaction.Disable(this);

		NestToPlaceIn = Nest;
	}

	void StartPuttingDownBird()
	{
		check(CurrentState == ETundraPlayerCrackBirdState::WalkingToNest);
		SetState(ETundraPlayerCrackBirdState::PuttingDown);
		CurrentBird.SetState(ETundraCrackBirdState::PuttingDown);
		CurrentBird.TargetNest = NestToPlaceIn;

		UBigCrackBirdEffectHandler::Trigger_PlaceInNest(CurrentBird, FTundraBigCrackBirdPlayerParams(Player));
	}

	void FinishPuttingDownBird()
	{
		check(CurrentState == ETundraPlayerCrackBirdState::PuttingDown);
		SetState(ETundraPlayerCrackBirdState::None);
		UnblockCapabilities();

		if(HasControl())
			ControlTryPutBirdOnSmallPlayer(CurrentBird);

		CurrentBird.InteractingPlayer = nullptr;
		CurrentBird.RemoveActorCollisionBlock(this);
		
		UTundraPlayerShapeshiftingComponent::Get(Player).RemoveShapeTypeBlockerInstigator(this);
		
		Player.ClearMovementInput(this);

		CurrentBird.AttachToActor(NestToPlaceIn, AttachmentRule = EAttachmentRule::KeepWorld);
		CurrentBird.bAttached = true;
		CurrentBird.CurrentNest = NestToPlaceIn;
		NestToPlaceIn.Interaction.Enable(this);
		NestToPlaceIn.Bird = CurrentBird;
		CurrentBird.SetState(ETundraCrackBirdState::InNest);
		
		auto Catapult = Cast<ABigCrackBirdCatapult>(NestToPlaceIn.AttachParentActor);

		if(Catapult != nullptr)
		{
			if(CurrentBird.bIsEgg)
			{
				CurrentBird.SetOriginalLocation();
				CurrentBird.Attach();
				CurrentBird.bIsPrimed = true;
			}
			else
			{
				CurrentBird.bHopOffCatapult = true;
			}
		}

		CurrentBird = nullptr;
		NestToPlaceIn = nullptr;
	}

	void TargetReached()
	{
		if(CurrentState == ETundraPlayerCrackBirdState::WalkingToBird)
			StartPickingUpBird();
		else 
			StartPuttingDownBird();
	}

	void CancelPickingUp()
	{
		SetState(ETundraPlayerCrackBirdState::None);
		CurrentBird.RemoveActorCollisionBlock(this);
		UnblockCapabilities();
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.RemoveShapeTypeBlockerInstigator(this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		if(CurrentBird.InteractingPlayer == Player)
			CurrentBird.InteractingPlayer = nullptr;

		CurrentBird = nullptr;
	}

	void CancelOnBirdDead()
	{
		SetState(ETundraPlayerCrackBirdState::None);
		CurrentBird.RemoveActorCollisionBlock(this);
		UnblockCapabilities();
		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.RemoveShapeTypeBlockerInstigator(this);
		if(CurrentBird.InteractingPlayer == Player)
			CurrentBird.InteractingPlayer = nullptr;

		CurrentBird = nullptr;
	}

	const ABigCrackBird GetBird() const
	{
		return CurrentBird;
	}

	const ABigCrackBirdNest GetTargetNest() const
	{
		return NestToPlaceIn;
	}

	const ETundraPlayerCrackBirdState GetCurrentState() const
	{
		return CurrentState;
	}

	/**
	 * CrackBirdStuck
	 */

	bool ControlTryPutBirdOnSmallPlayer(ABigCrackBird CrackBird)
	{
		check(HasControl());

		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		Trace.UseSphereShape(CrackBird.RootComp);

		const FOverlapResultArray Overlaps = Trace.QueryOverlaps(CurrentBird.RootComp.WorldLocation);
		for(const FOverlapResult& Overlap : Overlaps)
		{
			auto OverlapPlayer = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if(OverlapPlayer == nullptr)
				continue;

			auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(OverlapPlayer);
			if(ShapeShiftComp == nullptr)
				continue;

			if(!ShapeShiftComp.IsSmallShape())
				continue;

			if(CrackBird.bIsEgg)
			{
				// The egg just kills the player outright
				OverlapPlayer.KillPlayer();
				FTundraBigCrackBirdPlayerParams Params;
				Params.Player = OverlapPlayer;
				UBigCrackBirdEffectHandler::Trigger_OnPlayerSquishedByEgg(CrackBird, Params);
				return true;
			}

			auto StuckComp = UCrackBirdPlayerStuckComponent::Get(Overlap.Actor);
			if(StuckComp == nullptr)
				continue;

			if(StuckComp.IsStuckInBird())
				continue;

			StuckComp.CrumbBecomeStuckInBird(CrackBird);
			return true;
		}

		return false;
	}
}