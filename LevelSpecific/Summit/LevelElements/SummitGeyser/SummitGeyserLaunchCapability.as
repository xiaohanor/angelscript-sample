struct FSummitGeyserLaunchActivationParams
{
	ASummitGeyser LaunchingGeyser;
}
class USummitGeyserLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	USteppingMovementData Movement;

	TArray<ASummitGeyser> Geysers;
	float LaunchDuration = 0.0;
	FVector TargetLocation;
	FVector HorizontalMovement;

	FRotator LaunchRotation;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player.OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		Player.OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");

		MoveComp = UPlayerMovementComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION()
	private void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Geyser = Cast<ASummitGeyser>(OtherActor);
		if (Geyser != nullptr)
		{
			Geyser.PlayersOnGeyser.AddUnique(Player);
			Geysers.Add(Geyser);
		}
	}

	UFUNCTION()
	private void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Geyser = Cast<ASummitGeyser>(OtherActor);
		if (Geyser != nullptr)
		{
			Geyser.PlayersOnGeyser.Remove(Player);
			Geysers.Remove(Geyser);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitGeyserLaunchActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (Geysers.Num() == 0)
			return false;
		for (auto Geyser : Geysers)
		{
			if (Geyser.IsErupting()
			&& Geyser.IsInLaunchPlayerThreshold()
			&& LaunchTargetIsAbovePlayer(Geyser))
			{
				Params.LaunchingGeyser = Geyser;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration >= LaunchDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitGeyserLaunchActivationParams Params)
	{
		auto Geyser = Params.LaunchingGeyser;

		FSummitGeyserOnPlayerLaunchedParams EffectParams;
		EffectParams.Player = Player;
		USummitGeyserEventHandler::Trigger_OnPlayerLaunched(Geyser, EffectParams);

		if(Geyser.IsA(ASummitGeyserRunes))
			USummitGeyserRunesEventHandler::Trigger_OnPlayerLaunched(Geyser, EffectParams);

		TargetLocation = Geyser.ActorTransform.TransformPosition(Geyser.LaunchTarget);

		float LaunchDistance = TargetLocation.Z - Player.ActorLocation.Z;

		// LaunchDistance = StartVelocity * t - 0.5 * Gravity * t^2
		// StartVelocity = EndVelocity + Gravity * t
		//
		// LaunchDistance = (EndVelocity + Gravity * t) * t - 0.5 * Gravity * t^2
		// LaunchDistance = EndVelocity * t + 0.5 * Gravity * t^2
		//

		float A = 0.5 * MoveComp.GetGravityForce();
		float B = Geyser.LaunchTargetVelocity[Player];
		float C = -LaunchDistance;

		// Quadratic formula:
		LaunchDuration = (-B + Math::Sqrt(B*B - 4.0 * A * C)) / (2.0 * A);

		float StartLaunchSpeed = Geyser.LaunchTargetVelocity[Player] + MoveComp.GetGravityForce() * LaunchDuration;
		FVector StartLaunchVelocity = FVector::UpVector * StartLaunchSpeed; 
		Player.SetActorVelocity(StartLaunchVelocity);
		// Player.AddPlayerLaunchMovementImpulse(StartLaunchVelocity, true);
		Player.FlagForLaunchAnimations(StartLaunchVelocity);
		Player.KeepLaunchVelocityDuringAirJumpUntilLanded();

		FVector FlatForward = StartLaunchVelocity.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector LaunchDirection = StartLaunchVelocity.GetSafeNormal();
		LaunchRotation = FRotator::MakeFromZX(LaunchDirection, FlatForward);

		TEMPORAL_LOG(Player, "Geyser Launch")
			.DirectionalArrow("Flat Forward", Player.ActorLocation, FlatForward * 500, 5, 500, FLinearColor::Red)
			.DirectionalArrow("Launch Direction", Player.ActorLocation, LaunchDirection * 500, 5, 500, FLinearColor::Blue)
		;
		

		// Calculate how much horizontal movement to do during the launch
		HorizontalMovement = (TargetLocation - Player.ActorLocation) / LaunchDuration;
		HorizontalMovement.Z = 0.0;

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			CalculateAnimData();

			if(HasControl())
			{
				Movement.AddHorizontalVelocity(HorizontalMovement);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();				
				Movement.AddPendingImpulses();

				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, LaunchRotation, DeltaTime, 2);
				Movement.SetRotation(NewRotation);

				TEMPORAL_LOG(Player, "Geyser Launch")
					.Rotation("Launch Rotation", LaunchRotation.Quaternion(), Player.ActorLocation, 200)
				;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Launch");
		}
	}

	bool LaunchTargetIsAbovePlayer(ASummitGeyser Geyser) const
	{
		FVector GeyserLaunchTargetWorld = Geyser.ActorLocation + Geyser.LaunchTarget;
		FVector DeltaToLaunchTarget = GeyserLaunchTargetWorld - Player.ActorLocation;
		return DeltaToLaunchTarget.DotProduct(FVector::UpVector) > 0;
	}

	void CalculateAnimData()
	{
		AirMotionComp.AnimData.ForwardAlignedVelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL, -AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL), FVector2D(1, -1), MoveComp.HorizontalVelocity.DotProduct(Player.ActorForwardVector));
		AirMotionComp.AnimData.RightAlignedVelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL, -AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL), FVector2D(1, -1), MoveComp.HorizontalVelocity.DotProduct(Player.ActorRightVector));
	}
};