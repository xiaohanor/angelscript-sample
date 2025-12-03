
class UPlayerGrappleEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleEnter);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 10;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerPerchComponent PerchComp;

	private float Deceleration;
	private	float EnterTimer = 0;

	FVector InitialDirection;
	UGrapplePointBaseComponent TargetGrapplePoint;

	//Temp Assets/etc
	bool bHasSpawnedEffect = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrappleEnterActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if(GrappleComp.Data.ForceGrapplePoint != nullptr)
		{
			Params.SelectedGrapplePoint = GrappleComp.Data.ForceGrapplePoint;
			return true;
		}

		if (!WasActionStarted(ActionNames::Grapple))
			return false;

		if (Player.IsAnyCapabilityActive(PlayerGrappleTags::GrappleSlide))
			return false;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UGrapplePointBaseComponent);
		if (PrimaryTarget == nullptr)
			return false;
		
		if (!PrimaryTarget.CanTriggerGrappleEnter(Player))
			return false;

		Params.SelectedGrapplePoint = PrimaryTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGrappleEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter || GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive)
				Params.bMoveFinished = true;

			return true;
		}

		if (GrappleComp.Data.bEnterFinished)
		{
			Params.bMoveFinished = true;
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGrappleEnterActivationParams Params)
	{
		//Incase we interrupted another grapple, reset our data manually here
		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();

		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.BlockCapabilities(BlockedWhileIn::GrappleEnter, this);

		GrappleComp.Grapple.CheckMaterial();
		GrappleComp.SetGrappleMaterialParams(Params.SelectedGrapplePoint.WorldLocation);

		//Assign data
		TargetGrapplePoint = Params.SelectedGrapplePoint;
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleEnter;
		GrappleComp.Data.CurrentGrapplePoint = Params.SelectedGrapplePoint;
		GrappleComp.Data.CurrentGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

		TargetGrapplePoint.ActivateGrapplePointForPlayer(Player);
		PlayerTargetablesComp.TriggerActivationAnimationForTargetableWidget(Params.SelectedGrapplePoint);

		InitialDirection = Player.ActorForwardVector;
		FVector InitialToTarget = (TargetGrapplePoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		
		//if we are turning basically 180 then offset the initial direction slightly since slerping opposite directions can break
		if(InitialToTarget.DotProduct(InitialDirection) < -0.999)
			InitialDirection += Player.ActorRightVector * 0.01;

		switch (TargetGrapplePoint.GrappleType)
		{
			case (EGrapplePointVariations::SlidePoint):
				GrappleComp.VerifyAndStoreSlideAssistDirection(Cast<UGrappleSlidePointComponent>(GrappleComp.Data.CurrentGrapplePoint));
				GrappleComp.VerifyGrappleToSlideType(IsDebugActive());
				break;

			default:
				break;
		}

		//Incase we are grappling from a perch/Pole then ignore attached actors
		if(PerchComp.Data.ActivePerchPoint != nullptr)
		{
			//Add Owner
			AHazeActor PerchOwner = Cast<AHazeActor>(PerchComp.Data.ActivePerchPoint.Owner);
			GrappleComp.Data.ActorsToIgnore.Add(PerchOwner);
			
			//Add Parent if exists
			if(PerchOwner.GetAttachParentActor() != nullptr && PerchOwner.GetAttachParentActor().IsObjectNetworked())
				GrappleComp.Data.ActorsToIgnore.Add(PerchOwner.GetAttachParentActor());

			//Add Attached Actors
			TArray<AActor> AttachedActors;
			PerchOwner.GetAttachedActors(AttachedActors, bRecursivelyIncludeAttachedActors = true);
			if(AttachedActors.Num() > 0)
			{
				for(auto Actor : AttachedActors)
				{
					if (Actor.IsObjectNetworked())
						GrappleComp.Data.ActorsToIgnore.Add(Actor);
				}
			}

			//Add all to ignore
			for (auto Actor : GrappleComp.Data.ActorsToIgnore)
			{
				MoveComp.AddMovementIgnoresActor(this, Actor);
			}
		}

		//In case we interrupted another grapple, reset our grapple position
		GrappleComp.Grapple.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GrappleComp.Grapple.ActorLocation = (Player.Mesh.GetSocketLocation(n"LeftAttach"));

		//Handle Rope
		GrappleComp.Grapple.SetActorRotation((GrappleComp.Data.CurrentGrapplePoint.WorldLocation - GrappleComp.Grapple.ActorLocation).Rotation());

		FVector EnterVelocity = MoveComp.Velocity;
		Deceleration = EnterVelocity.Size() / GrappleComp.Settings.GrappleEnterDuration;

		//Assign Anim Data
		GrappleComp.SetHeightAndAngleDiff();

		bHasSpawnedEffect = false;
		EnterTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGrappleEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.UnblockCapabilities(BlockedWhileIn::GrappleEnter, this);

		if (Params.bMoveFinished)
		{
			if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter)
			{
				//We finished enter and another grapple capability took over

				if(MoveComp.WasOnWalkableGround())
					UPlayerCoreMovementEffectHandler::Trigger_Grapple_Enter_Finished_Grounded(Player);
			}
			else
			{
				//Nothing took over
				ClearGrapple();
			}
		}
		else
		{
			//Move didnt finish
			ClearGrapple();
		}

		if (!bHasSpawnedEffect)
		{
			// The grapple point reached event is used for gameplay not just effects, so we need to
			// make sure it gets called even if the capability was deactivated before the hook fully reached
			// on the remote side
			if (TargetGrapplePoint != nullptr)
				TargetGrapplePoint.OnGrappleHookReachedGrapplePointEvent.Broadcast(Player, TargetGrapplePoint);
		}

		MoveComp.RemoveMovementIgnoresActor(this);
		TargetGrapplePoint = nullptr;
	}

	void ClearGrapple()
	{
		TargetGrapplePoint.ClearPointForPlayer(Player);

		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();

		GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		GrappleComp.Grapple.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			EnterTimer += DeltaTime;
			float MoveAlpha = EnterTimer / GrappleComp.Settings.GrappleEnterDuration;

			if(HasControl())
			{
				if(EnterTimer >= GrappleComp.Settings.GrappleEnterDuration && !GrappleComp.Data.bEnterFinished)
				{
					switch(TargetGrapplePoint.GrappleType)
					{
						case (EGrapplePointVariations::GrapplePoint):
							//Perform our GrappleToPoint Trace here so its available next frame when ToPoint takes over
							GrappleComp.TraceForGrappleToPointTarget(IsDebugActive());
							break;

						case (EGrapplePointVariations::PerchPoint):
							GrappleComp.CalculateGrappleToPerchData();
							break;

						default:
							break;
					}
					GrappleComp.Data.bEnterFinished = true;
				}

				FVector Velocity = MoveComp.Velocity;
				Velocity -= Velocity.GetSafeNormal() * (Deceleration / 1.5) * DeltaTime;

				FVector Dir = (TargetGrapplePoint.WorldLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
				if(Dir.IsNearlyZero())
					Dir = Player.ActorForwardVector;

				FVector TargetRotation = InitialDirection.SlerpTowards(Dir, Math::Clamp(MoveAlpha, 0 , 1));
				
				Movement.SetRotation(TargetRotation.Rotation());
				Movement.AddVelocity(Velocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");
			UpdateGrappleHook(MoveAlpha);
		}
	}

	void UpdateGrappleHook(float Alpha)
	{
		if(Alpha > GrappleComp.Settings.CableStartAlpha)
		{
			if(GrappleComp.Grapple.IsHidden())
			{
				GrappleComp.Grapple.SetActorHiddenInGame(false);
			}

			FTransform TargetTransform;
			if(!GrappleComp.GetValidGrappleHookTargetTransform(TargetTransform))
				return;

			float GrappleHookAlpha = Math::GetMappedRangeValueClamped(FVector2D(GrappleComp.Settings.CableStartAlpha, 0.9), FVector2D(0, 1), Alpha);
			GrappleHookAlpha = Math::Clamp(GrappleHookAlpha, 0, 1);

			FVector NewLoc = Math::Lerp(Player.Mesh.GetSocketLocation(n"LeftAttach"), TargetTransform.Location, GrappleHookAlpha);
			GrappleComp.Grapple.SetActorLocation(NewLoc);

			//Limiting tenseness behavior for now as having it start at a high value means it looks completely broken the first few frames
			float NewTense = Math::Lerp(0.6, 0.25, Alpha);
			GrappleComp.Grapple.Tense = NewTense;

			if(!bHasSpawnedEffect && GrappleHookAlpha == 1)
			{
				switch (TargetGrapplePoint.ImpactEffectType)
				{
					case(EGrappleImpactType::Default):
						Niagara::SpawnOneShotNiagaraSystemAtLocation(GrappleComp.GrappleImpactDefault, TargetTransform.Location, (Player.ActorLocation - TargetTransform.Location).GetSafeNormal().Rotation());
						break;

					case(EGrappleImpactType::Metal):
						Niagara::SpawnOneShotNiagaraSystemAtLocation(GrappleComp.GrappleImpactMetal, TargetTransform.Location, (Player.ActorLocation - TargetTransform.Location).GetSafeNormal().Rotation());
						break;

					case(EGrappleImpactType::Leaves):
						Niagara::SpawnOneShotNiagaraSystemAtLocation(GrappleComp.GrappleImpactLeaves, TargetTransform.Location, (Player.ActorLocation - TargetTransform.Location).GetSafeNormal().Rotation());
						break;

					default:
						Niagara::SpawnOneShotNiagaraSystemAtLocation(GrappleComp.GrappleImpactDefault, TargetTransform.Location, (Player.ActorLocation - TargetTransform.Location).GetSafeNormal().Rotation());
						break;
				}

				// Niagara::SpawnOneShotNiagaraSystemAtLocation(GrappleComp.GrappleImpactEffect, TargetTransform.Location);
				bHasSpawnedEffect = true;
				
				if(GrappleComp.GrappleImpactFeedbackRumble != nullptr)
					Player.PlayForceFeedback(GrappleComp.GrappleImpactFeedbackRumble, false, false, this);

				if(TargetGrapplePoint != nullptr)
					TargetGrapplePoint.OnGrappleHookReachedGrapplePointEvent.Broadcast(Player, TargetGrapplePoint);
			}
		}
		else
			GrappleComp.Grapple.ActorLocation = (Player.Mesh.GetSocketLocation(n"LeftAttach"));
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{

	}
}

struct FGrappleEnterActivationParams
{
	UGrapplePointBaseComponent SelectedGrapplePoint;
};

struct FGrappleEnterDeactivationParams
{
	bool bMoveFinished = false;
}
