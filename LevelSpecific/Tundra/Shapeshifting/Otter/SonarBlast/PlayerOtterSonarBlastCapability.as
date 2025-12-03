class UTundraPlayerOtterSonarBlastCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerOtterSettings OtterSettings;
	UTundraPlayerOtterSonarBlastTargetable CurrentTargetable;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UTundraPlayerOtterComponent OtterComp;
	UTundraPlayerOtterSwimmingComponent OtterSwimComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	bool bTriggered = false;
	bool bShouldLerp;
	FVector TargetLocation;
	FVector StartLocation;

	const float LerpDuration = 0.2;
	const float AnimationLockDuration = 0.4;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtterSettings = UTundraPlayerOtterSettings::GetSettings(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		OtterSwimComp = UTundraPlayerOtterSwimmingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PlayerTargetablesComp.ShowWidgetsForTargetables(UTundraPlayerOtterSonarBlastTargetable);
		OtterSwimComp.AnimData.bSonarBlasting = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerOtterSonarBlastActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::Interaction))
			return false;

		auto Targetable = PlayerTargetablesComp.GetPrimaryTarget(UTundraPlayerOtterSonarBlastTargetable);

		if(Targetable == nullptr)
			return false;

		Params.Targetable = Targetable;
		Params.bShouldLerp = Targetable.bLerpOutOnCircle && Player.ActorLocation.DistSquaredXY(Targetable.WorldLocation) < Math::Square(Targetable.LerpOutCircleRadius);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!bTriggered)
			return false;

		if(!bShouldLerp && ActiveDuration > AnimationLockDuration)
			return true;

		if(bShouldLerp && ActiveDuration > LerpDuration + AnimationLockDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerOtterSonarBlastActivatedParams Params)
	{
		bTriggered = false;
		CurrentTargetable = Params.Targetable;
		bShouldLerp = Params.bShouldLerp;

		if(bShouldLerp)
		{
			FVector Dir = (Player.ActorLocation - CurrentTargetable.WorldLocation).GetSafeNormal2D();
			if(Dir.IsNearlyZero())
				Dir = -Player.ActorForwardVector;

			StartLocation = Player.ActorLocation;
			TargetLocation = CurrentTargetable.WorldLocation + Dir * CurrentTargetable.LerpOutCircleRadius;
			TargetLocation.Z = Player.ActorLocation.Z;
		}
		else
		{
			Trigger();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(bShouldLerp)
				{
					float Alpha = ActiveDuration / LerpDuration;
					Alpha = Math::Saturate(Alpha);
					Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
					if(Math::IsNearlyEqual(Alpha, 1.0))
					{
						Alpha = 1.0;

						if(!bTriggered)
							CrumbTrigger();
					}
					FVector Current = Math::Lerp(StartLocation, TargetLocation, Alpha);
					Movement.AddDelta(Current - Player.ActorLocation);
				}
				
				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, CurrentTargetable.WorldLocation - Player.ActorLocation), 30.0);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"UnderwaterSwimming");
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTrigger()
	{
		Trigger();
	}

	void Trigger()
	{
		CurrentTargetable.OnTriggered.Broadcast(CurrentTargetable);
		Niagara::SpawnOneShotNiagaraSystemAttachedWithRelativeTransform(OtterComp.SonarBlastEffect, OtterComp.GetShapeMesh(), FTransform(FRotator(0.0, 0.0, 0.0)), n"Head");
		UTundraPlayerOtterEffectHandler::Trigger_OnUnderwaterSonarBlast(OtterComp.OtterActor);
		OtterSwimComp.AnimData.bSonarBlasting = true;

		Player.PlayCameraShake(OtterComp.SonarBlastCameraShake, this);
		Player.PlayForceFeedback(OtterComp.SonarBlastForceFeedback, false, false, this);
		bTriggered = true;
	}
}

struct FTundraPlayerOtterSonarBlastActivatedParams
{
	UTundraPlayerOtterSonarBlastTargetable Targetable;
	bool bShouldLerp;
}