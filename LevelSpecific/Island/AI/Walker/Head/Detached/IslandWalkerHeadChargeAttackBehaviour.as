struct FHeadChargeReachPath
{
	int iCable;
	FVector Start;
	FVector Control;
	FVector Destination;	
	float Alpha;
	float Duration;

	void Update(float DeltaTime) 
	{
		Alpha = (Duration > 0.0) ? Alpha + DeltaTime / Duration : 1.0;
		if (Alpha > 1.0)
			Alpha = 1.0;
	}

	FVector GetLocation() const property
	{
		return BezierCurve::GetLocation_1CP(Start, Control, Destination, Alpha);		
	}	
}

class UIslandWalkerHeadChargeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AIslandWalkerHead Character;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerComponent SuspendComp;
	UIslandWalkerSettings Settings;

	AHazePlayerCharacter Target;
	UTargetTrailComponent TrailComp;
	FVector InitialDestination;
	FVector ChargeDirection;
	FVector Destination;
	bool bGrounded = false;
	FHazeAcceleratedFloat AccSpeed;
	bool bLift;
	bool bBrake;

	float ReachTime;
	TArray<int> ReachIndices;
	TArray<FHeadChargeReachPath> ReachingCables;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Character = Cast<AIslandWalkerHead>(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		SuspendComp = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);

		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		if (bBrake && MoveComp.Velocity.IsNearlyZero(200.0))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TrailComp = UTargetTrailComponent::Get(Target);
		Destination = GetIdealDestination();
		ChargeDirection = (Destination - Owner.ActorLocation).GetSafeNormal();
		InitialDestination = Destination;
		bGrounded = false;
		AccSpeed.SnapTo(0.0);
		bLift = true;
		bBrake = false;

		ReachIndices.SetNum(HeadComp.Cables.Num());
		for (int i = 0; i < ReachIndices.Num(); i++)
		{
			ReachIndices[i] = i;
		}
		ReachIndices.Shuffle();
		ReachTime = 0.0;
		ReachingCables.Empty(HeadComp.Cables.Num());
	}

	FVector GetIdealDestination()
	{
		FVector IdealLoc = Target.ActorLocation + TrailComp.GetAverageVelocity(0.5) * Settings.HeadChargeTargetPredictionDuration;
		IdealLoc += (IdealLoc - Owner.ActorLocation).GetSafeNormal2D() * Settings.HeadChargeOvershoot;
		IdealLoc.Z = SuspendComp.ArenaLimits.Height;
		return IdealLoc;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandWalkerHeadEffectHandler::Trigger_OnChaseAttackGroundedStop(Owner);
		Owner.ClearSettingsByInstigator(this);

		TargetComp.SetTarget(Cast<AHazePlayerCharacter>(TargetComp.Target).OtherPlayer);
		for (FHeadChargeReachPath& Reach : ReachingCables)
		{
			HeadComp.Cables[Reach.iCable].bReach = false;
		}

		Cooldown.Set(Settings.HeadChargeCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		if (ActiveDuration < Settings.HeadChargeTelegraphDuration)
		{
			// Telegraphing!
			// Update destination, clamped within a set angle from starting destination
			FVector ToDest = GetIdealDestination() - OwnLoc;
			Destination = OwnLoc + ToDest.ClampInsideCone(InitialDestination - OwnLoc, Settings.HeadChargeMaxYawTracking);
			ChargeDirection = (Destination - OwnLoc).GetSafeNormal();
			DestinationComp.RotateInDirection(ChargeDirection);
			return;
		}

		// Charge!
		AccSpeed.AccelerateTo(Settings.HeadChargeSpeed, Settings.HeadChargeAccelerationDuration, DeltaTime);

		// Add some initial lift
		if (bLift && (Owner.ActorLocation.Z < SuspendComp.ArenaLimits.Height + Settings.HeadChargeHeight))
			DestinationComp.AddCustomAcceleration(Owner.ActorUpVector * 3000.0);

		if (!bBrake)	
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, AccSpeed.Value);
		DestinationComp.RotateTowards(Owner.ActorLocation + ChargeDirection * 1000.0 + FVector::DownVector * 300.0); // Pitch down a bit

		bool bHit = false;
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 500))
			{
				HitPlayer(Player);
				bHit = true;
			}
		}

		if (!bBrake)
		{
			if(bHit || (ChargeDirection.DotProduct(Destination - Owner.ActorLocation) < 0.0))
				bBrake = true; // We're done, time to stop
		}

		if(!bGrounded && MoveComp.IsOnAnyGround())
		{
			bGrounded = true;
			UIslandWalkerHeadEffectHandler::Trigger_OnChaseAttackGroundedStart(Owner);
		}
		else if(bGrounded && !MoveComp.IsOnAnyGround())
		{
			bGrounded = false;
			UIslandWalkerHeadEffectHandler::Trigger_OnChaseAttackGroundedStop(Owner);
		}
	}

	void HitPlayer(AHazePlayerCharacter Player)
	{
		FKnockdown Knockdown;
		Knockdown.Duration = 1.5;
		FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		Knockdown.Move = Dir * 1750;
		Player.ApplyKnockdown(Knockdown);
		Player.DamagePlayerHealth(Settings.HeadChargeDamage);
		UPlayerDamageEventHandler::Trigger_TakeBigDamage(Target);
	}

	void UpdateCables(float DeltaTime)
	{
		if (HeadComp.Cables.Num() == 0)
			return;

		if (ActiveDuration < Settings.HeadChargeTelegraphDuration)
		{
			// Reach out with one cable after another to brace for flinging head forward
			if (ActiveDuration > ReachTime)
			{
				float MaxReachDuration = 0.5 * Settings.HeadChargeTelegraphDuration;
				
				FHeadChargeReachPath Reach;
				Reach.iCable = ReachIndices.Last();
				Reach.Alpha = 0.0;
				Reach.Duration = Math::RandRange(0.2, 0.4) * MaxReachDuration;
				Reach.Start = HeadComp.Cables[Reach.iCable].AccNeck.Value;

				// Reach to location ahead in charge direction on same side of head as cable is attached to head
				FVector CableDir = HeadComp.Cables[Reach.iCable].LocalOrigin.GetSafeNormal();
				FVector ChargeRight = ChargeDirection.CrossProduct(Owner.ActorUpVector).GetSafeNormal();
				float SideFactor = (CableDir.Y + ((CableDir.Y > 0.0) ? 0.5 : -0.5));
				Reach.Destination = Owner.ActorLocation;
				Reach.Destination += ChargeDirection * Settings.HeadChargeReachFactor * (1.0 + CableDir.X + CableDir.Z);
				Reach.Destination += ChargeRight * Settings.HeadChargeReachFactor * SideFactor; 
				Reach.Destination.Z = SuspendComp.ArenaLimits.Height;

				// Reach curve point upwards and outwards
				Reach.Control = Math::Lerp(Reach.Start, Reach.Destination, Settings.HeadChargeReachCurvature.X);
				Reach.Control += ChargeRight * Settings.HeadChargeReachFactor * SideFactor * Settings.HeadChargeReachCurvature.Y; 
				Reach.Control += Owner.ActorUpVector * Settings.HeadChargeReachFactor * Settings.HeadChargeReachCurvature.Z; 

				ReachingCables.Add(Reach);
				HeadComp.Cables[Reach.iCable].bReach = true;

				// Prepare for next cable reach
				ReachIndices.RemoveAtSwap(ReachIndices.Num() - 1);	
				ReachTime = MaxReachDuration / HeadComp.Cables.Num();
				if (ReachIndices.Num() == 0)
					ReachTime = BIG_NUMBER;
			}
		}	

		// Update any reaching cable
		for (FHeadChargeReachPath& Reach : ReachingCables)
		{
			Reach.Update(DeltaTime);
			HeadComp.Cables[Reach.iCable].ReachLocation = Reach.Location;
			FVector EndControl = Math::Lerp(Reach.Start, Reach.Control, Reach.Alpha);
			EndControl.Z = (EndControl.Z * 0.7 + Reach.Destination.Z * 0.3);
			HeadComp.Cables[Reach.iCable].ReachEndControl = EndControl; 
		}

		if (ActiveDuration > Settings.HeadChargeTelegraphDuration)
		{
			// Detach any cables that we've passed by
			for (int i = ReachingCables.Num() - 1; i >= 0; i--)
			{
				FHeadChargeReachPath Reach = ReachingCables[i];
				if (ChargeDirection.DotProduct(Reach.Destination - Owner.ActorLocation) > 0.0)
					continue; // Keep gripping
				// Let go!
				HeadComp.Cables[Reach.iCable].bReach = false;
				ReachingCables.RemoveAtSwap(i);	
			}
		}
	}
}