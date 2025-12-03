class UIslandNunchuckManagerCapability : UHazeCompoundCapability
{
 	default CapabilityTags.Add(n"Nunchuck");
	
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::DashRollState);

	default DebugCategory = n"Nunchuck";

 	default TickGroup = EHazeTickGroup::BeforeMovement;
 	default TickGroupOrder = 0;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerIslandNunchuckUserComponent MeleeComp;
	UPlayerTargetablesComponent TargetContainer;
	UPlayerMovementComponent MoveComp;
	UPlayerAimingComponent AimingComp;

	AHazePlayerCharacter PlayerOwner;
	float BlockedSettleTimeLeft = 0;
	bool bIsShowingWeapon = false;

	bool bHasActiveHitStop = false;
	float StopHitStopGameTime = 0;
	
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return
		UHazeCompoundStatePicker()
			.State(n"IslandNunchuckTargetWithEndingBackflipCapability")
			.State(n"IslandNunchuckDefaultComboCapability")
			.State(n"IslandNunchuckNoValidTargetMoveCapability")
		;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Owner);
		TargetContainer = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		AimingComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BlockedSettleTimeLeft > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MeleeComp.ClearActiveComboChain();
		PlayerOwner.ClearActorTimeDilation(this);
		if(MeleeComp.Weapon != nullptr)
		{
			MeleeComp.Weapon.ClearActorTimeDilation(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlocked())
			BlockedSettleTimeLeft = 0.5;
		else
			BlockedSettleTimeLeft = Math::Max(BlockedSettleTimeLeft - DeltaTime, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MeleeComp.PendingGroundImpact = FHitResult();
		if (!IsAnyChildCapabilityActive())
		{
			MeleeComp.ClearActiveComboChain();
			PlayerOwner.ClearActorTimeDilation(this);
			MeleeComp.Weapon.ClearActorTimeDilation(this);

			if(bIsShowingWeapon)
			{
				bIsShowingWeapon = false;
				MeleeComp.Weapon.HideWeapon();
				UIslandNunchuckEffectHandler::Trigger_NunchuckDeactivated(PlayerOwner);
			}
		}
		else
		{
			if(!bIsShowingWeapon)
			{
				bIsShowingWeapon = true;
				MeleeComp.Weapon.ShowWeapon();
				UIslandNunchuckEffectHandler::Trigger_NunchuckActivated(PlayerOwner);
			}

			UpdateHitStop(DeltaTime);
		}

		if(!MoveComp.IsOnAnyGround() 
			&& MoveComp.VerticalVelocity.DotProduct(-PlayerOwner.MovementWorldUp) > 200)
		{
			auto GroundTraceSettings = Trace::InitFromPlayer(PlayerOwner);
			FVector GroundTraceDelta = -PlayerOwner.MovementWorldUp * 200;
			MeleeComp.PendingGroundImpact = GroundTraceSettings.QueryTraceSingle(PlayerOwner.ActorLocation, PlayerOwner.ActorLocation + GroundTraceDelta);
		}

		auto Target = MeleeComp.GetActiveMoveTarget();
		if (Target != nullptr)
		{
			MeleeComp.LastTargetDirection = (Target.GetOwner().GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal();		
		}

		// Update the pending traces to see if we have impacts
		if(MeleeComp.PendingTraces.Num() > 0)
		{
			float DamageMultiplier = 1;
			if(Target != nullptr)
				UpdatePrimeTargetImpacts(DamageMultiplier, Target);
			else
				UpdateNoValidTargetImpacts(DamageMultiplier);

			// Keep the order
			MeleeComp.PendingTraces.RemoveAt(0);
		}
	
		// TEMP, remove when we have real icons
		{
			auto PrimeTarget = TargetContainer.GetPrimaryTarget(UIslandNunchuckTargetableComponent);
			if(PrimeTarget != nullptr)
			{
				FVector WidgetLocation = PrimeTarget.WorldLocation + PrimeTarget.WidgetVisualOffset;
				FVector CameraLocation = PlayerOwner.GetViewTransform().GetLocation();
				
				FQuat WidgetRotation = (CameraLocation - WidgetLocation).ToOrientationQuat();
				WidgetRotation = WidgetRotation * FRotator(0.0, Time::GameTimeSeconds * 100, 0.0).Quaternion();
				
				float Distance = CameraLocation.Distance(PrimeTarget.WorldLocation);
				float Radius = Math::Tan(Math::DegreesToRadians(45)) * Distance * 0.025;
				Debug::DrawDebugDiamond(WidgetLocation, Radius, WidgetRotation.Rotator(), LineColor = FLinearColor::DPink, bDrawInForeground = true);
			}
		}


	}

	void UpdatePrimeTargetImpacts(float& DamageMultiplier, UIslandNunchuckTargetableComponent ActiveTarget)
	{
		FPlayerIslandNunchuckInternalPendingHitTrace& Index = MeleeComp.PendingTraces[0];
		if(Index.AvailableImpacts == 0)
			return;

		// // Update 1 impact each frame
		FIslandNunchuckDamage Damage = Index.Damage;
		Damage.Multiplier *= DamageMultiplier;

		if(ActiveTarget.TraceType == EIslandNunchuckImpactResponseTraceType::AlwaysHitIgnoreTrace)
		{
			if(ApplyImpact(ActiveTarget.Owner, nullptr, Damage))
			{
				UIslandNunchuckEffectHandler::Trigger_AttackImpact(PlayerOwner, FIslandNunchuckEffectHandlerAttackImpactData(ActiveTarget.Owner));

				if(Index.bApplyHitStop)
					ApplyHitStop(Index.HitStopData);

				// Next impact will do less damage;
				DamageMultiplier *= 0.75;

				if(Index.AvailableImpacts > 0)
					Index.AvailableImpacts--;
			}
		}

		if(Index.AvailableImpacts == 0)
			return;
		
		// Prepare the trace
		FVector PositionToTraceFrom = PlayerOwner.GetActorLocation();
		if(Index.TraceBone != NAME_None)
		{
			PositionToTraceFrom = PlayerOwner.Mesh.GetSocketLocation(Index.TraceBone);		
		}
		else
		{
			PositionToTraceFrom += MoveComp.WorldUp * Index.Radius;
			PositionToTraceFrom += PlayerOwner.GetActorForwardVector() * Index.Radius * 0.5;
		}

		PositionToTraceFrom += PlayerOwner.GetActorQuat().RotateVector(Index.ActorLocalOffset);

		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseSphereShape(Index.Radius);
		auto Overlaps = Trace.QueryOverlaps(PositionToTraceFrom);
		HandleQueryOverlapImpacts(DamageMultiplier, Index, Overlaps);
	}

	void UpdateNoValidTargetImpacts(float& DamageMultiplier)
	{
		FPlayerIslandNunchuckInternalPendingHitTrace& Index = MeleeComp.PendingTraces[0];
		if(Index.AvailableImpacts == 0)
			return;

		// Prepare the trace
		FVector PositionToTraceFrom = PlayerOwner.GetActorLocation();
		if(Index.TraceBone != NAME_None)
		{
			PositionToTraceFrom = PlayerOwner.Mesh.GetSocketLocation(Index.TraceBone);		
		}
		else
		{
			PositionToTraceFrom += MoveComp.WorldUp * Index.Radius;
			PositionToTraceFrom += PlayerOwner.GetActorForwardVector() * Index.Radius * 0.5;
		}

		PositionToTraceFrom += PlayerOwner.GetActorQuat().RotateVector(Index.ActorLocalOffset);

		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseSphereShape(Index.Radius);
		auto Overlaps = Trace.QueryOverlaps(PositionToTraceFrom);
		HandleQueryOverlapImpacts(DamageMultiplier, Index, Overlaps);
	}

	void HandleQueryOverlapImpacts(float& DamageMultiplier, FPlayerIslandNunchuckInternalPendingHitTrace& TraceIndexData, FOverlapResultArray Overlaps)
	{
		for(auto Overlap : Overlaps)
		{			
			FIslandNunchuckDamage Damage = TraceIndexData.Damage;
			Damage.Multiplier *= DamageMultiplier;

			if(!ApplyImpact(Overlap.Actor, Overlap.Component, Damage))
				continue;

			if(TraceIndexData.bApplyHitStop)
				ApplyHitStop(TraceIndexData.HitStopData);
			
			UIslandNunchuckEffectHandler::Trigger_AttackImpact(PlayerOwner, FIslandNunchuckEffectHandlerAttackImpactData(Overlap.Actor));

			// Next impact will do less damage;
			DamageMultiplier *= 0.5;

			if(TraceIndexData.AvailableImpacts > 0)
				TraceIndexData.AvailableImpacts--;

			if(TraceIndexData.AvailableImpacts == 0)
				break;
		}
	}

	bool ApplyImpact(AActor OnActor, UPrimitiveComponent PrimComp, FIslandNunchuckDamage Damage)
	{
		TArray<UIslandNunchuckImpactResponseComponent> ResponseComponents;
		OnActor.GetComponentsByClass(ResponseComponents);
		bool bDidApplyAnyImpacts = false;

		// We only hit the actor so we trigger on all impact response components
		if(PrimComp == nullptr)
		{
			for(auto It : ResponseComponents)
			{
				if(It.ApplyImpact(PlayerOwner, Damage))
					bDidApplyAnyImpacts = true;
			}
		}
		// We trigger on the valid primitives
		else
		{
			for(auto It : ResponseComponents)
			{
				if(It.GetPrimitiveParentComponent() != PrimComp)
					continue;

				if(It.ApplyImpact(PlayerOwner, Damage))
					bDidApplyAnyImpacts = true;
			}
		}

		// Did we have anything that would respond to impacts on this actor?
		return bDidApplyAnyImpacts;
	}

	void ApplyHitStop(FIslandNunchuckHitStopData HitStop)
	{
		// Hitstop for atleast 1 frame
		//float Duration = Math::Max(HitStop.Duration, 1/60);
		float Duration = 0.1;

	 	bHasActiveHitStop = true;
		StopHitStopGameTime = Time::GameTimeSeconds + Duration;

		float Multiplier = Math::Clamp(HitStop.DeltaTimeMultiplier, KINDA_SMALL_NUMBER, 1);

		PlayerOwner.SetActorTimeDilation(Multiplier, this, EInstigatePriority::High);
		MeleeComp.Weapon.SetActorTimeDilation(Multiplier, this, EInstigatePriority::High);
	}

	void UpdateHitStop(float DeltaTime)
	{
		if(!bHasActiveHitStop)
			return;

		if(Time::GameTimeSeconds < StopHitStopGameTime)
			return;

		bHasActiveHitStop = false;
		MeleeComp.ClearActiveComboChain();
		PlayerOwner.ClearActorTimeDilation(this);
		MeleeComp.Weapon.ClearActorTimeDilation(this);
	}
}
