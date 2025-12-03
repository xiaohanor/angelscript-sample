
class UPlayerLadderExitOnTopCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderExit);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 22;	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;
	UHazeCameraUserComponent CameraUserComp;
	ALadder Ladder;

	float Timer;

	FVector RelativeTargetLocation;
	FVector RelativeStartLocation;
	FVector InitialForwardVector;
	FVector InitialUpVector;

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
		CameraUserComp = UHazeCameraUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if (LadderComp.Data.ActiveLadder.bBlockClimbingOutTop)
			return false;

		if ((LadderComp.Data.ActiveLadder.LadderType == ELadderType::BottomSegmented))
			return false;

		if (LadderComp.bDisableClimbingUpUntilReInput)
			return false;

		if (!LadderComp.bTriggerExitOnTop)
		{
			if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y < 0.25)
				return false;

			// If there is still a rung above the player, don't exit
			FLadderRung RungAbovePlayer = LadderComp.Data.ActiveLadder.GetClosestRungAboveWorldLocation(Player.ActorLocation);
			if (RungAbovePlayer.IsValid())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LadderComp.Settings.TopExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ladder = LadderComp.Data.ActiveLadder;
		LadderComp.SetState(EPlayerLadderState::ExitOnTop);

		MoveComp.FollowComponentMovement(Ladder.RootComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);

		FHazeTraceSettings ExitTrace = Trace::InitFromPlayer(Player);
		if(IsDebugActive())
			ExitTrace.DebugDraw(3);

		FVector TraceStartLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(LadderComp.Data.ActiveLadder.GetTopRung());
		
		float VerticalMargin = Player.GetScaledCapsuleHalfHeight() * 2;
		TraceStartLocation += LadderComp.Data.ActiveLadder.ActorUpVector * VerticalMargin;

		float InwardsTraceDistance = 150;
		TraceStartLocation += LadderComp.Data.ActiveLadder.ActorForwardVector * InwardsTraceDistance;

		FVector TraceEndLocation = TraceStartLocation - (LadderComp.Data.ActiveLadder.ActorUpVector * VerticalMargin);
		FHitResult ExitHit = ExitTrace.QueryTraceSingle(TraceStartLocation, TraceEndLocation);
		
		FVector EndLoc;

		if(ExitHit.bBlockingHit)
		{
			//Add one unit in normals direction to make sure we dont depenetrate once move is over.
			EndLoc = ExitHit.Location + ExitHit.ImpactNormal;
		}
		else
			EndLoc = Ladder.Interact.WorldLocation;

		//Clear our Camera Clamps assigned by LadderClimbCapability
		CameraUserComp.CameraSettings.Clamps.Clear(LadderComp);

		RelativeStartLocation = Ladder.ActorTransform.InverseTransformPosition(Player.ActorLocation);
		RelativeTargetLocation = Ladder.ActorTransform.InverseTransformPosition(EndLoc);

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);

		Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(this, LadderComp.Settings.TopExitDuration);

		LadderComp.DeactivateLadderClimb();
		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Exit_Top_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		MoveComp.UnFollowComponentMovement(this);

		Ladder.PlayerExitedLadderEvent.Broadcast(Player, Ladder, ELadderExitEventStates::ExitOnTop);

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Exit_Top_Finished(Player);
		FLadderPlayerEventParams EventParams(Player);

		ULadderEventHandler::Trigger_OnPlayerExitedFromTop(Ladder, EventParams);
		
		Ladder = nullptr;
		Timer = 0;
		MoveComp.Reset();

		LadderComp.VerifyExitStateCompleted(EPlayerLadderState::ExitOnTop);

		Player.PlayForceFeedback(LadderComp.EnterFF, this , 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector StartLoc = Ladder.ActorTransform.TransformPosition(RelativeStartLocation);
				FVector EndLoc = Ladder.ActorTransform.TransformPosition(RelativeTargetLocation);

				FHazeShapeSettings Shape;
				Shape.Type = EHazeShapeType::Capsule;
				Shape.CapsuleHalfHeight = Player.GetScaledCapsuleHalfHeight();
				Shape.CapsuleRadius = Player.GetScaledCapsuleRadius();

				Timer += DeltaTime;
				float Alpha = Math::Clamp(Timer / LadderComp.Settings.TopExitDuration, 0, 1);
				FVector NewLoc = Math::Lerp(StartLoc, EndLoc, Alpha);

#if !RELEASE
				FTemporalLog Log = TEMPORAL_LOG(this);
				Log.Shape("Start", StartLoc + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight), Shape, Player.ActorRotation, FLinearColor::Green);
				Log.Shape("End", EndLoc + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight), Shape, Player.ActorRotation, FLinearColor::Red);
				Log.Shape("Target", NewLoc + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight), Shape, Player.ActorRotation, FLinearColor::Yellow);
#endif

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, FVector::ZeroVector);
				Movement.SetRotation(FRotator::MakeFromXZ(Ladder.ActorForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal(), MoveComp.WorldUp));

			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};