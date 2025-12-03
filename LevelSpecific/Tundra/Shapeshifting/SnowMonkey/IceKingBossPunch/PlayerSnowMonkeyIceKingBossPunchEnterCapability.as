class UTundraPlayerSnowMonkeyIceKingBossPunchEnterCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);
	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	USteppingMovementData Movement;
	UTeleportingMovementData RootMovement;
	UTeleportingMovementData TempMovement;
	UTundraSnowMonkeyIceKingBossPunchTargetableComponent CurrentTargetable;
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings Settings;

	bool bMoveDone = false;
	float EnterDuration;
	FVector Destination;
	FVector OriginalLocation;
	FHazeLocomotionTransform RootMotion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		RootMovement = MoveComp.SetupTeleportingMovementData();
		TempMovement = MoveComp.SetupTeleportingMovementData();
		Settings = UTundraPlayerSnowMonkeyIceKingBossPunchSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;

		if(BossPunchComp.CurrentBossPunchTargetable != nullptr)
			return;

		if(Player.IsCapabilityTagBlocked(TundraShapeshiftingTags::SnowMonkeyBossPunch))
			return;

		PlayerTargetablesComp.ShowWidgetsForTargetables(UTundraSnowMonkeyIceKingBossPunchTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraSnowMonkeyIceKingBossPunchEnterActivatedParams& Params) const
	{
		if(BossPunchComp.CurrentBossPunchTargetable != nullptr)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BossPunchComp.ForcedBossPunchActor != nullptr)
		{
			Params.Targetable = BossPunchComp.ForcedBossPunchActor.Targetable;
			return true;
		}

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		auto Targetable = PlayerTargetablesComp.GetPrimaryTarget(UTundraSnowMonkeyIceKingBossPunchTargetableComponent);
		if(Targetable == nullptr)
			return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraSnowMonkeyIceKingBossPunchEnterActivatedParams Params)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		
		BossPunchComp.ForcedBossPunchActor = nullptr;
		CurrentTargetable = Params.Targetable;
		bMoveDone = false;

		OriginalLocation = Player.ActorLocation;
		Destination = CurrentTargetable.WorldLocation;

		BossPunchComp.EnterBossPunch(CurrentTargetable);
		
		auto InteractionActor = Cast<ATundraSnowMonkeyIceKingBossPunchInteractionActor>(CurrentTargetable.Owner);
		if(InteractionActor != nullptr)
			InteractionActor.OnPunchInteractionStarted.Broadcast();
		
		BossPunchComp.OnEntered.Broadcast(BossPunchComp.Type);
		EnterDuration = BossPunchComp.TypeSettings.BossPunchEnterDuration;

		if(!BossPunchComp.TypeSettings.bAutomaticallyPunchFirstPunch)
			Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyBossPunch, this);

		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		SnowMonkeyComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!BossPunchComp.TypeSettings.bAutomaticallyPunchFirstPunch)
			Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyBossPunch, this);

		if(IsBlocked())
		{
			BossPunchComp.ExitBossPunch();
		}

		SnowMonkeyComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.Unbind(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION()
	private void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase SkelMeshComp)
	{
		if(BossPunchComp.bWithinRootMotionState)
			SkelMeshComp.ConsumeLastExtractedRootMotion(RootMotion);
		else
			RootMotion = FHazeLocomotionTransform();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BossPunchComp.bWithinRootMotionState && MoveComp.PrepareMove(RootMovement))
		{
			if(HasControl())
			{
				FVector CurrentDelta = RootMotion.DeltaTranslation;
				RootMovement.AddDeltaWithCustomVelocity(CurrentDelta, FVector::ZeroVector);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					RootMovement.ApplyCrumbSyncedGroundMovement();
				else
					RootMovement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(RootMovement, BossPunchComp.AnimationFeatureTag);
			return;
		}

		// OLIVERL TODO: TEMP, THIS WILL BE REMOVED WHEN PROPER ROOT MOTION IS IN
		if(BossPunchComp.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch && MoveComp.PrepareMove(TempMovement))
		{
			if(HasControl())
			{
				float Alpha = Math::Saturate(ActiveDuration / EnterDuration);
				if(Alpha == 1.0)
					bMoveDone = true;

				float MoveAlpha = Settings.BossPunchEnterCurve.GetFloatValue(Alpha);

				FVector Location = Math::Lerp(OriginalLocation, Destination, MoveAlpha);

				TempMovement.AddDelta(Location - Player.ActorLocation);

				if(!bMoveDone)
					TempMovement.InterpRotationTo(CurrentTargetable.ComponentQuat, Settings.BossPunchEnterRotationSpeed);
				else
					TempMovement.SetRotation(CurrentTargetable.ComponentQuat);
			}
			else
			{
				TempMovement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(TempMovement, BossPunchComp.AnimationFeatureTag);
			return;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = Math::Saturate(ActiveDuration / EnterDuration);
				if(Alpha == 1.0)
					bMoveDone = true;

				float MoveAlpha = Settings.BossPunchEnterCurve.GetFloatValue(Alpha);

				FVector Location = Math::Lerp(OriginalLocation, Destination, MoveAlpha);

				Movement.AddDelta(Location - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();

				if(!bMoveDone)
					Movement.InterpRotationTo(CurrentTargetable.ComponentQuat, Settings.BossPunchEnterRotationSpeed);
				else
					Movement.SetRotation(CurrentTargetable.ComponentQuat);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, BossPunchComp.AnimationFeatureTag);
		}
	}
}

struct FTundraSnowMonkeyIceKingBossPunchEnterActivatedParams
{
	UTundraSnowMonkeyIceKingBossPunchTargetableComponent Targetable;
}