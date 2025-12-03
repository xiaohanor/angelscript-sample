struct FHoverPerchDashActivatedParams
{
	AHazePlayerCharacter Player;
}

class UHoverPerchDashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(HoverPerchBlockedWhileIn::Grind);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 170;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHoverPerchActor PerchActor;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UPlayerMovementComponent PlayerMoveComp;

	const float ImpulseInterpSpeed = 5.0;
	const float LastBumpedDashCooldown = 0.5;
	const float LeftGrindRedirectionBuffer = 0.5;

	FVector StartMovementInput;
	FVector Impulse;

	float StartSpeed;
	AHazePlayerCharacter Player;
	float MaxDashSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();

		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchDashActivatedParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;

		if(PerchActor.PlayerLocker == nullptr)
			return false;

		if(DeactiveDuration <= PerchActor.DashCooldown)
			return false;

		if(Time::GetGameTimeSince(PerchActor.HoverPerchComp.TimeLastBumpedOtherPerch) < LastBumpedDashCooldown)
			return false;

		if(!PerchActor.WasDashActionStarted())
			return false;

		// if(PerchActor.PlayerIsJumping())
		// 	return false;

		Params.Player = PerchActor.PlayerLocker;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return true;

		if(ActiveDuration >= PerchActor.DashDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchDashActivatedParams Params)
	{
		Player = Params.Player;
		Player.PlayForceFeedback(PerchActor.DashForceFeedback, false, false, this);
		Player.PlayCameraShake(PerchActor.DashCameraShake, this);

		MoveComp.OverrideResolver(UHoverPerchActorSweepingResolver, this);
		
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		if(PlayerMoveComp.MovementInput.IsNearlyZero()
		|| JustLeftGrind())
			StartMovementInput = Player.ActorForwardVector;
		else
			StartMovementInput = PlayerMoveComp.MovementInput.GetSafeNormal();

		FHoverPerchOnDashedParams EffectParams;
		EffectParams.Player = Player;
		UHoverPerchEffectHandler::Trigger_OnDashed(PerchActor, EffectParams);

		Player.ApplyBlendToCurrentView(0.75);
		StartSpeed = PerchActor.ActorVelocity.Size();
		Impulse = FVector::ZeroVector;
		MaxDashSpeed = PerchActor.DashSpeedMax;
		if (PerchActor.PlayerIsJumping())
			MaxDashSpeed *= 0.6;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(UHoverPerchActorSweepingResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				const float DashAlpha = ActiveDuration / PerchActor.DashDuration;
				const float CurveSpeedMultiplier = PerchActor.DashSpeedCurve.GetFloatValue(DashAlpha);
				const float DashSpeed = CurveSpeedMultiplier * MaxDashSpeed;

				const float SimulatedSpeedWithoutDash = Math::Lerp(StartSpeed, PerchActor.MaxSpeedWhileOnPerch, DashAlpha);

				const float Speed = Math::Lerp(SimulatedSpeedWithoutDash, DashSpeed, CurveSpeedMultiplier);
				FVector Velocity = StartMovementInput * Speed;

				Movement.AddVelocity(Velocity);

				FVector MovementImpulse = MoveComp.PendingImpulse;
				Movement.AddPendingImpulses();

				Impulse = MovementImpulse;
				Impulse = Math::VInterpTo(Impulse, FVector::ZeroVector, DeltaTime, ImpulseInterpSpeed);

				PerchActor.MeshComp.AddLocalRotation(FRotator(0, (PerchActor.ActorVelocity.Size() / 2) * DeltaTime, 0));
				PerchActor.SyncedMeshRelativeRotation.Value = PerchActor.MeshComp.RelativeRotation;
				PerchActor.ApplyHeightResetMovement(Movement, DeltaTime);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				PerchActor.MeshComp.RelativeRotation = PerchActor.SyncedMeshRelativeRotation.Value;
			}

			MoveComp.ApplyMove(Movement);
		}

		if(HasControl())
		{
			PerchActor.BodyMeshComp.WorldRotation = Player.ActorRotation;
			PerchActor.SyncedBodyMeshWorldRotation.Value = PerchActor.BodyMeshComp.WorldRotation;
		}
		else
		{
			PerchActor.BodyMeshComp.WorldRotation = PerchActor.SyncedBodyMeshWorldRotation.Value;
		}
	}

	bool JustLeftGrind() const
	{
		if(Time::GetGameTimeSince(PerchActor.HoverPerchComp.TimeLastStoppedGrinding) < LeftGrindRedirectionBuffer)
			return true;

		return false;
	}
};