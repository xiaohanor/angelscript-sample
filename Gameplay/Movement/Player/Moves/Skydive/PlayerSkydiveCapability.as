class UPlayerSkydiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Skydive);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 159;

	bool bIsLeadingPlayer = false;
	float ModifiedTerminalVelocity = 0;

	UPlayerMovementComponent MoveComp;
	UPlayerSkydiveComponent SkydiveComp;
	USteppingMovementData Movement;

	UNiagaraComponent SpawnedOutlineEffect;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		SkydiveComp = UPlayerSkydiveComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && MoveComp.IsOnWalkableGround())
		{
			if(SkydiveComp.ShouldActivateSkydive())
			{
				SkydiveComp.ClearAllSkydiveActivations();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (MoveComp.IsOnAnyGround())
			return false;
		
		if (!SkydiveComp.ShouldActivateSkydive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerSkydiveDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			if(MoveComp.IsOnWalkableGround())
				Params.bBecameGroundedWalkable = true;
			else if(MoveComp.IsOnAnyGround())
				Params.bBecameGroundedAny = true;

			if(MoveComp.HasCustomMovementStatus(n"Swimming"))
				Params.bEnteredSwimming = true;

			return true;
		}

		if (MoveComp.IsOnWalkableGround())
		{
			Params.bBecameGroundedWalkable = true;
			return true;
		}

		if (MoveComp.IsOnAnyGround())
		{
			Params.bBecameGroundedAny = true;
			return true;
		}

		if (MoveComp.HasCustomMovementStatus(n"Swimming"))
		{
			Params.bEnteredSwimming = true;
			return true;
		}

		if (!SkydiveComp.IsSkydiveActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Blocking capabilities here rather then adding the BlockedWhileInTag to moves incase we want to modify which moves are blocked or have 2 versions of skydive (Scenario / General movement)
		// which might not want to block these options

		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);

		UMovementGravitySettings::SetTerminalVelocity(Player, 0, this);
		SkydiveComp.ActivateSkydive();

		if(SkydiveComp.SkydiveOutlineEffect != nullptr)
			SpawnedOutlineEffect = Niagara::SpawnLoopingNiagaraSystemAttached(SkydiveComp.SkydiveOutlineEffect, Player.Mesh);

		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerSkydiveDeactivationParams Params)
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);

		UMovementGravitySettings::ClearTerminalVelocity(Player, this);

		if(Params.bBecameGroundedAny || Params.bBecameGroundedWalkable || Params.bEnteredSwimming)
			SkydiveComp.ClearAllSkydiveActivations();

		SkydiveComp.DeactivateSkydive();

		if(SpawnedOutlineEffect != nullptr)
			SpawnedOutlineEffect.Deactivate();

		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(SkydiveComp.Settings.bShouldTraceForLanding)
			{
				//Trace for landing anim data
				TraceForLanding();
			}
			
			if(HasControl())
			{
				FVector MoveInput = MoveComp.MovementInput;
				if (Player.IsCapabilityTagBlocked(PlayerSkydiveTags::SkydiveInput))
					MoveInput = FVector();
				FVector BlendSpaceValue = Player.ActorTransform.InverseTransformVector(MoveInput);
				SkydiveComp.AnimData.SkydiveInput = FVector2D(BlendSpaceValue.Y, BlendSpaceValue.X);

				FVector AirControlVelocity = SkydiveComp.CalculateSkydiveAirControlVelocity(
					MoveInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);

				Movement.AddHorizontalVelocity(AirControlVelocity);
				// Movement.AddOwnerVerticalVelocity();
				// Movement.AddGravityAcceleration();

				FVector VerticalVelocity = MoveComp.VerticalVelocity;
				if(SkydiveComp.Settings.bEnableRubberbanding && ShouldRubberband())
				{
					if(VerticalVelocity.DotProduct(-MoveComp.WorldUp) > ModifiedTerminalVelocity)
					{
						//Deccelerate
						float VerticalSpeed = Math::FInterpConstantTo(VerticalVelocity.Size(), ModifiedTerminalVelocity, DeltaTime, SkydiveComp.Settings.RubberBandDeccelerationSpeed);
						VerticalSpeed = Math::Min(VerticalSpeed, ModifiedTerminalVelocity);
						VerticalVelocity = -MoveComp.WorldUp * VerticalSpeed;
					}
					else if (VerticalVelocity.DotProduct(-MoveComp.WorldUp) < ModifiedTerminalVelocity)
					{
						//Accelerate
						float VerticalSpeed = Math::FInterpConstantTo(VerticalVelocity.Size(), ModifiedTerminalVelocity, DeltaTime, SkydiveComp.Settings.RubberBandAccelerationSpeed);
						VerticalSpeed = Math::Min(VerticalSpeed, ModifiedTerminalVelocity);
						VerticalVelocity = -MoveComp.WorldUp * VerticalSpeed;
					}
					else
					{
						VerticalVelocity = -MoveComp.WorldUp * SkydiveComp.Settings.TerminalVelocity;
					}
				}
				else
				{
					//Add normal gravity / Constrain our velocity
					if(VerticalVelocity.DotProduct(-MoveComp.WorldUp) >= SkydiveComp.Settings.TerminalVelocity)
						VerticalVelocity = -MoveComp.WorldUp * SkydiveComp.Settings.TerminalVelocity;
					else
					{
						VerticalVelocity += -MoveComp.WorldUp * (UMovementGravitySettings::GetSettings(Player).GravityAmount * DeltaTime);
					}
				}

				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.AddPendingImpulses();

				/*
					Calculate how fast the player should rotate when falling at fast speeds
				*/
				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - SkydiveComp.Settings.MaximumTurnRateFallingSpeed) / SkydiveComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				if(SkydiveComp.GetCurrentSkydiveMode() == EPlayerSkydiveMode::Default && !Player.IsCapabilityTagBlocked(PlayerSkydiveTags::SkydiveInput))
				{
					const float FacingDirectionInterpSpeed = Math::Lerp(SkydiveComp.Settings.MaximumTurnRate, SkydiveComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
					Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveInput.Size());
				}

#if !RELEASE
				/* Debug */
				if (IsDebugActive())
				{
					PrintToScreen("Skydive Mode:" + SkydiveComp.GetCurrentSkydiveMode(), Color = FLinearColor::DPink);
					PrintToScreen("AirControlVelocity: " + AirControlVelocity);
				}
#endif
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Skydive");
		}
	}


	bool ShouldRubberband()
	{
		AHazePlayerCharacter OtherPlayer = Player.IsMio() ? Game::GetZoe() : Game::GetMio();

		FVector PlayerToPlayerDelta = (OtherPlayer.ActorLocation - Player.ActorLocation);
		FVector PlayerVerticalDelta = PlayerToPlayerDelta.ConstrainToDirection(MoveComp.WorldUp);

		if (PlayerVerticalDelta.Size() >= SkydiveComp.Settings.RubberBandMinDistance)
		{
			if(PlayerToPlayerDelta.GetSafeNormal().DotProduct(MoveComp.WorldUp) >= 0)
			{
				if(SkydiveComp.Settings.RubberBandMaxSlowdown < 1)
				{
					bIsLeadingPlayer = true;

					ModifiedTerminalVelocity = SkydiveComp.Settings.TerminalVelocity * Math::GetMappedRangeValueClamped(FVector2D(SkydiveComp.Settings.RubberBandMinDistance, SkydiveComp.Settings.RubberBandMaxDistance),
																															FVector2D(1, SkydiveComp.Settings.RubberBandMaxSlowdown),
																																PlayerVerticalDelta.Size());
					return true;

				}

				return false;
			}
			else
			{
				if (SkydiveComp.Settings.RubberBandMaxSpeedUp > 1)
				{
					bIsLeadingPlayer = false;

					ModifiedTerminalVelocity = SkydiveComp.Settings.TerminalVelocity * Math::GetMappedRangeValueClamped(FVector2D(SkydiveComp.Settings.RubberBandMinDistance, SkydiveComp.Settings.RubberBandMaxDistance),
																															FVector2D(1, SkydiveComp.Settings.RubberBandMaxSpeedUp),
																																PlayerVerticalDelta.Size());
					return true;
				}

				return false;					
			}
		}

		return false;
	}

	float CalculateRubberBandMultiplier()
	{
		AHazePlayerCharacter OtherPlayer = Player.IsMio() ? Game::GetZoe() : Game::GetMio();

		FVector PlayerToPlayerDelta = (OtherPlayer.ActorLocation - Player.ActorLocation);
		FVector PlayerVerticalDelta = PlayerToPlayerDelta.ConstrainToDirection(MoveComp.WorldUp);
		
		float RubberBandMultiplier = Math::GetMappedRangeValueClamped(FVector2D(-SkydiveComp.Settings.RubberBandMaxDistance, SkydiveComp.Settings.RubberBandMaxDistance),
																		FVector2D(SkydiveComp.Settings.RubberBandMaxSlowdown, SkydiveComp.Settings.RubberBandMaxSpeedUp),
																			-PlayerVerticalDelta.DotProduct(MoveComp.WorldUp));

		return RubberBandMultiplier;
	}

	bool TraceForLanding()
	{
		if (MoveComp.VerticalVelocity.Size() < KINDA_SMALL_NUMBER)
			return false;

		FHazeTraceSettings GroundTrace = Trace::InitFromMovementComponent(MoveComp);
		GroundTrace.TraceWithPlayerProfile(Player);
		GroundTrace.UseLine();
		GroundTrace.UseShapeWorldOffset(FVector::ZeroVector);

		if (IsDebugActive())
			GroundTrace.DebugDraw(0);

		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = Player.ActorLocation + (-MoveComp.WorldUp * (MoveComp.VerticalVelocity.Size() * SkydiveComp.Settings.LandingTracePredictionTime));

		FHitResult GroundTraceHit = GroundTrace.QueryTraceSingle(TraceStart, TraceEnd);
		FHitResultArray GroundTraceHits = GroundTrace.QueryTraceMultiUntilBlock(TraceStart, TraceEnd);

		if(GroundTraceHits.HasOverlapHits())
		{
			for(auto Overlap : GroundTraceHits.OverlapHits)
			{
				ASwimmingVolume SwimVolume = Cast<ASwimmingVolume>(Overlap.Actor);

				if(SwimVolume == nullptr)
					continue;

				float RemainingHeightDelta = (Overlap.ImpactPoint - Player.ActorLocation).ConstrainToDirection(MoveComp.WorldUp).Size();

				// Crumb_RegisteredGroundHit(RemainingHeightDelta);
				SkydiveComp.AnimData.RemainingHeightForLanding = RemainingHeightDelta;
				SkydiveComp.AnimData.bWaterLandingDetected = true;
				SkydiveComp.AnimData.bLandingDetected = false;
				
				return true;
			}
		}
		
		if(GroundTraceHits.HasBlockHits())
		{
			if(GroundTraceHits.BlockHits[0].Component.HasTag(n"Walkable"))
			{
				float RemainingHeightDelta = (GroundTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToDirection(MoveComp.WorldUp).Size();

				// Crumb_RegisteredWaterHit(RemainingHeightDelta);
				SkydiveComp.AnimData.RemainingHeightForLanding = RemainingHeightDelta;
				SkydiveComp.AnimData.bLandingDetected = true;
				SkydiveComp.AnimData.bWaterLandingDetected = false;
				
				return true;
			}
		}

		if(SkydiveComp.AnimData.bLandingDetected || SkydiveComp.AnimData.bWaterLandingDetected)
		{
			SkydiveComp.AnimData.bLandingDetected = false;
			SkydiveComp.AnimData.bWaterLandingDetected = false;
			SkydiveComp.AnimData.RemainingHeightForLanding = -1;
			// Crumb_ClearLandingHits();
		}

		return false;
	}

	// UFUNCTION(BlueprintOverride)
	// void OnLogActive(FTemporalLog TemporalLog)
	// {
	// 
	// }

	// UFUNCTION(NotBlueprintCallable, CrumbFunction)
	// void Crumb_RegisteredGroundHit(float Height)
	// {
	// 	SkydiveComp.AnimData.RemainingHeightForLanding = Height;
	// 	SkydiveComp.AnimData.bLandingDetected = true;
	// 	SkydiveComp.AnimData.bWaterLandingDetected = false;
	// }

	// UFUNCTION(NotBlueprintCallable, CrumbFunction)
	// void Crumb_RegisteredWaterHit(float Height)
	// {
	// 	SkydiveComp.AnimData.RemainingHeightForLanding = Height;
	// 	SkydiveComp.AnimData.bLandingDetected = false;
	// 	SkydiveComp.AnimData.bWaterLandingDetected = true;
	// }

	// UFUNCTION(NotBlueprintCallable, CrumbFunction)
	// void Crumb_ClearLandingHits()
	// {
	// 	SkydiveComp.AnimData.bLandingDetected = false;
	// 	SkydiveComp.AnimData.bWaterLandingDetected = false;
	// 	SkydiveComp.AnimData.RemainingHeightForLanding = -1;
	// }
}

struct FPlayerSkydiveDeactivationParams
{
	bool bBecameGroundedAny = false;

	bool bBecameGroundedWalkable = false;

	bool bEnteredSwimming = false;
}