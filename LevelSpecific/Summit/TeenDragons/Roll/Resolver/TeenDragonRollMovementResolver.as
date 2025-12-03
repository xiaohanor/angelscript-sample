struct FTeenDragonRollResolverFrameImpactData
{
	TArray<FTeenDragonRollResolverResponseComponentHitData> ResponseCompHitData;
	TOptional<FTeenDragonRollKnockbackData> KnockbackData;
	TOptional<FTeenDragonRollReflectOffWallData> ReflectOffWallData;
	TOptional<FTeenDragonRollBounceData> BounceData;

	void Reset()
	{
		ResponseCompHitData.Reset(3);
		KnockbackData.Reset();
		BounceData.Reset();
		ReflectOffWallData.Reset();
	}
}

struct FTeenDragonRollKnockbackData
{
	FRollParams RollParams;
	UTeenDragonRollWallKnockbackSettings KnockbackSettings;
	FHazeCameraImpulse CameraImpulse;
}

struct FTeenDragonRollResolverResponseComponentHitData
{
	bool bAlreadyHitThisFrame = false;
	FRollParams RollParams;
	UTeenDragonTailAttackResponseComponent ResponseComp;
}

struct FTeenDragonRollBounceData
{
	FVector BounceLocation;
	FVector BounceHitNormal;
	float SpeedIntoGroundNormal;
}

struct FTeenDragonRollReflectOffWallData
{
	FVector PreReflectForward;
	FVector PostReflectForward;
	FVector WallNormal;
	FVector HitLocation;
	float SpeedIntoWall;
	UTeenDragonRollWallKnockbackSettings KnockbackSettings;
	FHazeCameraImpulse CameraImpulse;
}

class UTeenDragonRollMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = UTeenDragonRollMovementData;
	private const UTeenDragonRollMovementData MovementData;

	private AHazePlayerCharacter Player;

	private FTeenDragonRollResolverFrameImpactData ImpactData;

	private UTeenDragonRollSettings RollSettings;
	private UTeenDragonRollWallKnockbackSettings DefaultKnockbackSettings;
	private UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FTemporalLog TempLog;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		MovementData = Cast<UTeenDragonRollMovementData>(Movement);
		Player = Cast<AHazePlayerCharacter>(Owner);

		RollSettings = MovementData.RollSettings;
		DefaultKnockbackSettings = MovementData.DefaultKnockbackSettings;
		ClimbSettings = MovementData.ClimbSettings;
		ImpactData.Reset();
		TempLog = TEMPORAL_LOG(Owner, "Roll Resolver");

		if(!HandleStepUpHitDelegate.IsBound())
			HandleStepUpHitDelegate.BindUFunction(this, n"HandleStepUpHit");
	}

	/**
	 * If we try to step up on something, we might fail to do so because of a mesh that we want to
	 * collide with for impact responses, but want to ignore in the following iteration.
	 * Therefore, we must check if the step up hit is a response component that we don't want to
	 * stop us, and then ignore it and redo the step up trace.
	 */
	UFUNCTION()
	protected void HandleStepUpHit(FMovementHitResult& StepUpHit, bool&out bOutModifiedStepUpHit, bool&out bOutRetryStepUpTrace)
	{
		// We only care if this is a failed step up trace
		if(!StepUpHit.bStartPenetrating)
			return;

		// Find if we hit a response comp
		FTeenDragonRollResolverResponseComponentHitData ResponseHitData;
		if(!CollisionWithResponseComp(StepUpHit, ResponseHitData))
			return;

		// If the response comp should stop us, then it should have failed
		if(ResponseHitData.ResponseComp.bShouldStopPlayer)
			return;

		// Otherwise, this was a impact, and we want to ignore the now destroyed actor (crystal) and try the trace again
		ImpactData.ResponseCompHitData.Add(ResponseHitData);
		IterationTraceSettings.AddPermanentIgnoredActor(ResponseHitData.ResponseComp.Owner);
		bOutModifiedStepUpHit = false;
		bOutRetryStepUpTrace = true;
	}
	
	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		// Response Component Hit
		FTeenDragonRollResolverResponseComponentHitData ResponseHitData;
		if(CollisionWithResponseComp(Hit, ResponseHitData))
		{
			// Don't add multiple hits, otherwise event fires multiple times
			if(!ResponseHitData.bAlreadyHitThisFrame)
				ImpactData.ResponseCompHitData.Add(ResponseHitData);

			if(!ResponseHitData.ResponseComp.bShouldStopPlayer)
			{
				// Don't want to add the ignore again
				if(!ResponseHitData.bAlreadyHitThisFrame)
				{
					IterationTraceSettings.AddPermanentIgnoredActor(ResponseHitData.ResponseComp.Owner);
					TempLog.Sphere(f"Response Comp Hit Ignored Actor: {ResponseHitData.ResponseComp.Owner}", Hit.Actor.ActorLocation, 50, FLinearColor::Green, 5);
				}
				return EMovementResolverHandleMovementImpactResult::Skip; 
			}
			else if(GetKnockedBack(IterationState, Hit))
				return EMovementResolverHandleMovementImpactResult::Skip;
		}

		// Ground hit
		if(Hit.IsAnyGroundContact())
		{
			FTeenDragonRollBounceData BounceData;
			if(Bounce(IterationState, Hit, BounceData))
			{
				ImpactData.BounceData.Set(BounceData);
				
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
			// else if(KeepVelocityOnLanding(IterationState, Hit))
			// 	return EMovementResolverHandleMovementImpactResult::Continue;
		}

		// Wall Impact
		if(Hit.IsWallImpact())
		{
			if(GetKnockedBack(IterationState, Hit))
				return EMovementResolverHandleMovementImpactResult::Skip;
			else if(ReflectOffWall(IterationState, Hit))
				return EMovementResolverHandleMovementImpactResult::Skip;
			// else if(RedirectAlongWall(IterationState, Hit))
			// 	return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FTeenDragonRollResolverResponseComponentHitData&out OutResponseCompHitData) const
	{
		auto TempLogPage = TempLog.Page("Response Comp Hit");

		TArray<UTeenDragonTailAttackResponseComponent> ResponseComps;
		Hit.Actor.GetComponentsByClass(ResponseComps);
		const FHitResult HitResult = Hit.ConvertToHitResult();
		if(ResponseComps.Num() == 0)
			return false;

		for(auto ResponseComp : ResponseComps)
		{
			if(ResponseComp.bIsPrimitiveParentExclusive
			&& !ResponseComp.ImpactWasOnParent(HitResult.Component))
				continue;

			if(!ResponseComp.bEnabled)
				continue;
			
			if(Hit.IsAnyGroundContact()
			&& !ResponseComp.bGroundImpactValid)
				continue;

			if(Hit.IsWallImpact()
			&& !ResponseComp.bWallImpactValid)
				continue;

			if(Hit.IsCeilingImpact()
			&& !ResponseComp.bCeilingImpactValid)
				continue;

			// Still want to skip this iteration, otherwise it counts as knockback or reflect, just don't want to add it again so event fires multiple times
			if(ResponseComponentHasAlreadyBeenHitThisFrame(ResponseComp))
				OutResponseCompHitData.bAlreadyHitThisFrame = true;

			OutResponseCompHitData.ResponseComp = ResponseComp;
			break;
		}

		if(OutResponseCompHitData.ResponseComp == nullptr)
			return false;
		
		TempLogPage.Value(f"Response Comp: {OutResponseCompHitData.ResponseComp}", OutResponseCompHitData.ResponseComp);

		FRollParams RollParams;
		RollParams.DamageDealt = RollSettings.RollImpactDamage;
		RollParams.HitComponent = HitResult.Component;
		RollParams.HitLocation = HitResult.ImpactPoint;
		RollParams.PlayerInstigator = Cast<AHazePlayerCharacter>(Owner);
		RollParams.RollDirection = IterationState.DeltaToTrace.GetSafeNormal();
		FVector VelocityAtHit = IterationState.DeltaToTrace / IterationTime;
		RollParams.SpeedAtHit = VelocityAtHit.Size();
		RollParams.SpeedTowardsImpact = VelocityAtHit.DotProduct(-HitResult.Normal);
		RollParams.WallNormal = HitResult.Normal;
		OutResponseCompHitData.RollParams = RollParams;

		TempLogPage.Sphere(f"Hit: {Hit.Actor}", Hit.Actor.ActorLocation, 50, FLinearColor::Purple, 5);

		return true;		
	}

	bool ResponseComponentHasAlreadyBeenHitThisFrame(UTeenDragonTailAttackResponseComponent ResponseComp) const
	{
		for(auto AlreadyRegisteredHit : ImpactData.ResponseCompHitData)
		{
			if(AlreadyRegisteredHit.ResponseComp == ResponseComp)
				return true;
		}

		return false;
	}
 
	bool GetKnockedBack(FMovementResolverState& State, FMovementHitResult Hit) const
	{
		auto TempLogPage = TempLog.Page("Knockback");

		if(ImpactData.KnockbackData.IsSet())
			return false;

		if(Hit.bIsStepUp)
			return false;

		if(Hit.IsStepupGroundContact())
			return false;

		if(!Hit.bBlockingHit)
			return false;

		auto ClimbComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
		if(ClimbComp != nullptr
		&& ClimbComp.ClimbDirectionIsAllowed(Hit.Normal))
			return false;
			
		auto NonKnockbackComp = USummitNonRollKnockBackComponent::Get(Hit.Actor);
		if(NonKnockbackComp != nullptr)
		{
			if(!NonKnockbackComp.bSpecifyComponentsForNoKnockback
			|| !NonKnockbackComp.ShouldBeKnockedback(Hit.Component))
				return false;
		}

		if(MovementData.bKnockbackIsBlocked)
			return false;

		UTeenDragonRollWallKnockbackSettings KnockbackSettings = DefaultKnockbackSettings;
		auto ResponseComponent = UTeenDragonTailAttackResponseComponent::Get(Hit.Actor);
		if(ResponseComponent != nullptr)
		{
			if(ResponseComponent.OverridingKnockbackSettings != nullptr)
				KnockbackSettings = ResponseComponent.OverridingKnockbackSettings;
		}

		const FVector FlatDirToImpact = (Hit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(State.WorldUp).GetSafeNormal();
		const FVector FlatHorizontalVelocityDir = State.GetDelta().GetHorizontalPart(State.WorldUp).Velocity.GetSafeNormal();

		const float ImpactAngleDegrees = FlatDirToImpact.GetAngleDegreesTo(FlatHorizontalVelocityDir);

		TempLogPage
			.DirectionalArrow("Flat Dir to Impact", Player.ActorLocation, FlatDirToImpact * 500, 20, 4000, FLinearColor::Purple)
			.DirectionalArrow("Flat Horizontal Velocity Dir", Player.ActorLocation, FlatHorizontalVelocityDir * 500, 20, 4000, FLinearColor::Red)
			.Value("Impact Degrees", ImpactAngleDegrees)
		;

		// Always want to get knockback if hit something with a response component
		if(ResponseComponent == nullptr)
		{
			if(ImpactAngleDegrees > KnockbackSettings.WallKnockbackMinThreshold)
				return false;
		}
		
		FVector Velocity = FVector::ZeroVector;
		for(auto It : State.DeltaStates)
		{
			TempLog.DirectionalArrow(f"Delta: {It.Key}", Owner.ActorLocation, It.Value.Velocity, 20, 40, FLinearColor::Teal);
			Velocity += It.Value.Velocity;
			State.OverrideDelta(It.Key, FMovementDelta());
		}

		const float ClampedImpactSpeed = Math::Max(Velocity.Size(), KnockbackSettings.MinVelocityKnockback);
		
		FVector NewVelocity;
		NewVelocity += FVector::UpVector * ClampedImpactSpeed * KnockbackSettings.KnockbackWallImpactVerticalMultiplier;

		const FVector ImpactDirection = Velocity.GetSafeNormal();
		const FVector ClampedImpactVelocity = ImpactDirection * ClampedImpactSpeed;
		const float SpeedTowardsWall = ClampedImpactVelocity.DotProduct(FlatDirToImpact);
		NewVelocity += -FlatDirToImpact * SpeedTowardsWall * KnockbackSettings.KnockbackWallImpactHorizontalMultiplier;

		const FVector VelocityTowardsWall = FlatDirToImpact * SpeedTowardsWall;
		const FVector VelocityNotTowardsWall = ClampedImpactVelocity - VelocityTowardsWall;

		NewVelocity += VelocityNotTowardsWall * KnockbackSettings.KnockbackAlongWallVelocityMultiplier;

		NewVelocity = NewVelocity.GetClampedToMaxSize(KnockbackSettings.MaxKnockbackSize);

		const FMovementDelta NewDelta = FMovementDelta(NewVelocity * IterationTime, NewVelocity);

		State.OverrideDelta(EMovementIterationDeltaStateType::Impulse, NewDelta);
		
		TempLogPage
			.DirectionalArrow("Impulse", Owner.ActorLocation, NewVelocity, 20, 40, FLinearColor::DPink)
			.DirectionalArrow("Pre Knockback Velocity", Owner.ActorLocation, State.DeltaToTrace / IterationTime, 20, 40, FLinearColor::Black)
			.DirectionalArrow("Post Knockback Velocity", Owner.ActorLocation, NewDelta.Velocity, 20, 40, FLinearColor::White)
			.DirectionalArrow("Wall Normal", Hit.ImpactPoint, Hit.Normal * 500, 20, 40, FLinearColor::DPink)
			.DirectionalArrow("Impact Velocity", Owner.ActorLocation, ClampedImpactVelocity, 20, 40, FLinearColor::Green)
			.DirectionalArrow("Impact Velocity not towards wall", Owner.ActorLocation, VelocityNotTowardsWall, 20, 40,FLinearColor::Red)
			.DirectionalArrow("Impact Velocity towards wall", Owner.ActorLocation, VelocityTowardsWall, 20, 40, FLinearColor::Purple)
		;


		FTeenDragonRollKnockbackData KnockbackData;
		FRollParams RollParams;
		RollParams.DamageDealt = RollSettings.RollImpactDamage;
		RollParams.HitComponent = Hit.Component;
		RollParams.HitLocation = Hit.ImpactPoint;
		RollParams.PlayerInstigator = Cast<AHazePlayerCharacter>(Owner);
		RollParams.RollDirection = IterationState.DeltaToTrace.GetSafeNormal();
		FVector VelocityAtHit = IterationState.DeltaToTrace / IterationTime;
		RollParams.SpeedAtHit = VelocityAtHit.Size();
		RollParams.SpeedTowardsImpact = VelocityAtHit.DotProduct(-Hit.Normal);
		RollParams.WallNormal = Hit.Normal;
		KnockbackData.RollParams = RollParams;
		KnockbackData.KnockbackSettings = KnockbackSettings;
		ImpactData.KnockbackData.Set(KnockbackData);

		return true;
	}

	bool ReflectOffWall(FMovementResolverState& State, FMovementHitResult Hit)
	{
		auto TempLogPage = TempLog.Page("Reflect off Wall");

		if(ImpactData.ReflectOffWallData.IsSet())
			return false;

		if(Hit.bIsStepUp)
			return false;

		if(Hit.IsStepupGroundContact())
			return false;

		if(!Hit.bBlockingHit)
			return false;
		
		auto ClimbComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
		if(ClimbComp != nullptr
		&& ClimbComp.ClimbDirectionIsAllowed(Hit.Normal))
			return false;
			
		auto NonKnockbackComp = USummitNonRollKnockBackComponent::Get(Hit.Actor);
		if(NonKnockbackComp != nullptr)
		{
			if(!NonKnockbackComp.bSpecifyComponentsForNoKnockback
			|| !NonKnockbackComp.ShouldBeKnockedback(Hit.Component))
				return false;
		}

		if(MovementData.bKnockbackIsBlocked)
			return false;

		UTeenDragonRollWallKnockbackSettings KnockbackSettings = DefaultKnockbackSettings;
		auto ResponseComponent = UTeenDragonTailAttackResponseComponent::Get(Hit.Actor);
		if(ResponseComponent != nullptr)
		{
			if(ResponseComponent.OverridingKnockbackSettings != nullptr)
				KnockbackSettings = ResponseComponent.OverridingKnockbackSettings;
		}
		
		const FVector FlatDirToImpact = (Hit.ImpactPoint - State.GetPreviousIterationLocation()).ConstrainToPlane(State.WorldUp).GetSafeNormal();
		const FVector FlatHorizontalVelocityDir = State.GetDelta().GetHorizontalPart(State.WorldUp).Velocity.GetSafeNormal();

		const float ImpactAngle = FlatDirToImpact.GetAngleDegreesTo(FlatHorizontalVelocityDir);

		TempLogPage
			.DirectionalArrow("Flat Dir to Impact", Hit.ImpactPoint, FlatDirToImpact * 500, 20, 4000, FLinearColor::Purple)
			.DirectionalArrow("Flat Horizontal Velocity Dir", Hit.ImpactPoint, FlatHorizontalVelocityDir * 500, 20, 4000, FLinearColor::Red)
			.Value("Impact Degrees", ImpactAngle)
		;

		// Disregard shallowness of angle if in air (Don't want to turn along wall when in air, feels better to reflect)
		if(State.PhysicsState.GroundContact.IsValidBlockingHit())
		{
			if(ImpactAngle > KnockbackSettings.ReflectOffWallMaxThreshold)
				return false;
		}
		
		const FVector FlatWallNormal = Hit.Normal.ConstrainToPlane(State.WorldUp).GetSafeNormal();

		const float DegreesTowardsWall = FlatHorizontalVelocityDir.GetAngleDegreesTo(FlatDirToImpact); 

		const float HitNormalDotRight = Owner.ActorRightVector.DotProduct(FlatDirToImpact);
		float RotationDegrees = (ImpactAngle * KnockbackSettings.ReflectDegreesMultiplier);
		RotationDegrees = Math::Clamp(RotationDegrees, 0, 90);
		if(HitNormalDotRight < 0)
			RotationDegrees *= -1;

		const FVector ReflectedDir = -FlatDirToImpact.RotateAngleAxis(RotationDegrees, State.WorldUp);

		TempLogPage
			.DirectionalArrow("Flat Wall Normal", Owner.ActorLocation, FlatWallNormal * 500, 20, 4000, FLinearColor::Purple)
			.Value("Degrees Towards Wall", DegreesTowardsWall)
			.Value("Rotation Degrees", RotationDegrees)
			.DirectionalArrow("Reflected Horizontal Direction", Owner.ActorLocation, ReflectedDir * 500, 20, 4000, FLinearColor::White)
		;

		float SpeedIntoWall = 0.0;
		for(auto It : State.DeltaStates)
		{
			TempLog.DirectionalArrow(f"Delta: {It.Key}", Owner.ActorLocation, It.Value.Velocity, 20, 4000, FLinearColor::Teal);

			FMovementDelta Delta = It.Value.ConvertToDelta();
			if(Delta.IsNearlyZero())
				continue;

			FMovementDelta VerticalDelta = Delta.GetVerticalPart(State.WorldUp);
			FMovementDelta HorizontalDelta = Delta - VerticalDelta;

			SpeedIntoWall += Delta.Velocity.DotProduct(FlatDirToImpact);

			const float HorizontalDeltaSize = HorizontalDelta.Delta.Size();
			const float HorizontalSpeed = HorizontalDelta.Velocity.Size();

			HorizontalDelta = FMovementDelta(ReflectedDir * HorizontalDeltaSize, ReflectedDir * HorizontalSpeed);
		
			Delta = HorizontalDelta + VerticalDelta;
			State.OverrideDelta(It.Key, Delta);
		}

		FTeenDragonRollReflectOffWallData ReflectOffWallData;
		ReflectOffWallData.WallNormal = -FlatDirToImpact;
		ReflectOffWallData.PreReflectForward = State.GetHorizontalMovementDirection(State.WorldUp);
		ReflectOffWallData.PostReflectForward = ReflectedDir;
		ReflectOffWallData.SpeedIntoWall = SpeedIntoWall;
		ReflectOffWallData.KnockbackSettings = KnockbackSettings;
		ReflectOffWallData.HitLocation = Hit.ImpactPoint;

		ImpactData.ReflectOffWallData.Set(ReflectOffWallData);

		return true;
	}

	bool RedirectAlongWall(FMovementResolverState& State, FMovementHitResult Hit)
	{
		auto TempLogPage = TempLog.Page("Redirect along Wall");

		if(Hit.bIsStepUp)
			return false;

		if(Hit.IsStepupGroundContact())
			return false;

		if(!Hit.bBlockingHit)
			return false;
		
		auto ClimbComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
		if(ClimbComp != nullptr
		&& ClimbComp.ClimbDirectionIsAllowed(Hit.Normal))
			return false;
			
		auto NonKnockbackComp = USummitNonRollKnockBackComponent::Get(Hit.Actor);
		if(NonKnockbackComp != nullptr)
		{
			if(!NonKnockbackComp.bSpecifyComponentsForNoKnockback
			|| !NonKnockbackComp.ShouldBeKnockedback(Hit.Component))
				return false;
		}

		if(MovementData.bKnockbackIsBlocked)
			return false;
		
		const FVector FlatDirToImpact = (Hit.ImpactPoint - State.GetPreviousIterationLocation()).ConstrainToPlane(State.WorldUp).GetSafeNormal();
		const FVector FlatHorizontalVelocityDir = State.GetDelta().GetHorizontalPart(State.WorldUp).Velocity.GetSafeNormal();

		const float ImpactAngle = FlatDirToImpact.GetAngleDegreesTo(FlatHorizontalVelocityDir);

		TempLogPage
			.DirectionalArrow("Flat Dir to Impact", Hit.ImpactPoint, FlatDirToImpact * 500, 20, 4000, FLinearColor::Purple)
			.DirectionalArrow("Flat Horizontal Velocity Dir", Hit.ImpactPoint, FlatHorizontalVelocityDir * 500, 20, 4000, FLinearColor::Red)
			.Value("Impact Degrees", ImpactAngle)
		;
		
		const FVector FlatWallNormal = Hit.Normal.ConstrainToPlane(State.WorldUp).GetSafeNormal();

		TempLogPage
			.DirectionalArrow("Flat Wall Normal", Owner.ActorLocation, FlatWallNormal * 500, 20, 4000, FLinearColor::Purple)
		;

		for(auto It : State.DeltaStates)
		{
			TempLog.DirectionalArrow(f"Delta: {It.Key}", Owner.ActorLocation, It.Value.Velocity, 20, 4000, FLinearColor::Teal);

			FMovementDelta Delta = It.Value.ConvertToDelta();
			if(Delta.IsNearlyZero())
				continue;

			FMovementDelta VerticalDelta = Delta.GetVerticalPart(State.WorldUp);
			FMovementDelta HorizontalDelta = Delta - VerticalDelta;

			// const float HorizontalDeltaSize = HorizontalDelta.Delta.Size();
			// const float HorizontalSpeed = HorizontalDelta.Velocity.Size();

			// auto TowardsWall = FMovementDelta(-Hit.ImpactNormal * IterationTime, -Hit.ImpactNormal);
			HorizontalDelta = HorizontalDelta.PlaneProject(Hit.ImpactNormal, true);
			// HorizontalDelta += TowardsWall;

			// HorizontalDelta = FMovementDelta(ReflectedDir * HorizontalDeltaSize, ReflectedDir * HorizontalSpeed);
		
			Delta = HorizontalDelta + VerticalDelta;
			State.OverrideDelta(It.Key, Delta);
		}

		return true;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult Hit, FTeenDragonRollBounceData&out OutBounceData) const
	{
		auto TempLogPage = TempLog.Page("Bounce");

		// If was on ground last frame
		if(MovementData.OriginalContacts.GroundContact.IsValidBlockingHit())
			return false;

		// If currently on ground
		if(State.PhysicsState.GroundContact.IsValidBlockingHit())
			return false;

		// Already Bounced
		if(ImpactData.BounceData.IsSet())
			return false;

		if(UTeenDragonRollNonBouncableComponent::Get(Hit.Actor) != nullptr)
			return false;

		if(Hit.bIsStepUp)
			return false;

		if(!Hit.IsValidBlockingHit())
			return false;

		if(!RollSettings.bShouldBounce)
			return false;

		if(MovementData.bWantToJump)
			return false;

		TempLogPage
			.Sphere("Impact Location", Hit.ImpactPoint, 20, FLinearColor::Blue, 5)
			.DirectionalArrow("Ground Normal", Hit.ImpactPoint, Hit.Normal * 500, 20, 40, FLinearColor::Blue)
		;


		if(RollSettings.bShouldOnlyBounceOnce)
		{
			TempLogPage.Value("Has Bounced Since Landing", MovementData.bHasBouncedSinceLanding);
			if(MovementData.bHasBouncedSinceLanding)
				return false;
		}

		const FVector CurrentVelocity = State.GetDelta().Velocity;
		const float SpeedTowardsImpact = CurrentVelocity.DotProduct(-Hit.Normal);
		const float SpeedDownwards = CurrentVelocity.DotProduct(FVector::DownVector); 

		TempLogPage
			.Value("Speed Towards Impact", SpeedTowardsImpact)
			.Value("Speed Downwards", SpeedDownwards)
		;

		if(Math::Max(SpeedTowardsImpact, SpeedDownwards) < RollSettings.BounceVerticalSpeedThreshold)
			return false;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();

			FMovementDelta VerticalDelta = MovementDelta.GetVerticalPart(State.WorldUp);
			FMovementDelta PreBounceHorizontalDelta = MovementDelta - VerticalDelta;

			FVector HorizontalDir = Owner.ActorForwardVector.GetDirectionTangentToSurface(Hit.Normal, State.WorldUp);
			float VerticalSpeedTowardsHorizontalDir = VerticalDelta.Velocity.DotProduct(HorizontalDir);

			if(It.Key == EMovementIterationDeltaStateType::Movement)
			{
				TempLogPage
					.DirectionalArrow("Pre Bounce Vertical Velocity", Owner.ActorLocation, VerticalDelta.Velocity, 20, 40, FLinearColor::Blue)
				;
			}

			FVector VerticalDir = FVector::UpVector;

			float BounceSpeed = VerticalDelta.Velocity.Size() * RollSettings.BounceRestitution;
			BounceSpeed = Math::Clamp(BounceSpeed, RollSettings.MinBounceSpeed, RollSettings.MaxBounceSpeed);

			VerticalDelta.Delta = VerticalDir * BounceSpeed * IterationTime;
			VerticalDelta.Velocity = VerticalDir * BounceSpeed;

			float HorizontalSpeed = PreBounceHorizontalDelta.Velocity.Size();
			FVector HorizontalVelocity = HorizontalDir * HorizontalSpeed;
			FVector HorizontalDelta = HorizontalDir * HorizontalSpeed * IterationTime;
			FMovementDelta HorizontalMovementDelta(HorizontalDelta, HorizontalVelocity);

			MovementDelta = HorizontalMovementDelta + VerticalDelta;
			State.OverrideDelta(It.Key, MovementDelta);
			if(It.Key == EMovementIterationDeltaStateType::Movement)
			{
				TempLogPage
					.DirectionalArrow("Horizontal Velocity", Owner.ActorLocation, HorizontalMovementDelta.Velocity, 20, 4000, FLinearColor::Red)
					.DirectionalArrow("Post Bounce Vertical Velocity", Owner.ActorLocation, VerticalDelta.Velocity, 20, 4000, FLinearColor::White)
					.Value("Bounce Speed", BounceSpeed)
					.Value("Vertical Speed Towards Horizontal Dir", VerticalSpeedTowardsHorizontalDir)
				;
			}
		}

		OutBounceData.BounceLocation = Hit.ImpactPoint;
		OutBounceData.BounceHitNormal = Hit.Normal;
		OutBounceData.SpeedIntoGroundNormal = -OutBounceData.BounceHitNormal.DotProduct(CurrentVelocity);

		return true;
	}

	bool KeepVelocityOnLanding(FMovementResolverState& State, FMovementHitResult Hit)
	{
		auto TempLogPage = TempLog.Page("Land");

		// If was on ground last frame
		if(MovementData.OriginalContacts.GroundContact.IsValidBlockingHit())
			return false;

		// If currently on ground
		if(State.PhysicsState.GroundContact.IsValidBlockingHit())
			return false;

		if(Hit.bIsStepUp)
			return false;

		if(!Hit.IsValidBlockingHit())
			return false;

		if(MovementData.bWantToJump)
			return false;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();

			FMovementDelta VerticalDelta = MovementDelta.GetVerticalPart(State.WorldUp);
			FMovementDelta PreLandHorizontalDelta = MovementDelta - VerticalDelta;

			FVector HorizontalDir = Owner.ActorForwardVector.GetDirectionTangentToSurface(Hit.Normal, State.WorldUp);
			float HorizontalSpeed = PreLandHorizontalDelta.Velocity.Size();
			FVector HorizontalVelocity = HorizontalDir * HorizontalSpeed;
			FVector HorizontalDelta = HorizontalDir * HorizontalSpeed * IterationTime;
			FMovementDelta HorizontalMovementDelta(HorizontalDelta, HorizontalVelocity);
			MovementDelta = HorizontalMovementDelta + VerticalDelta;

			State.OverrideDelta(It.Key, MovementDelta);
			if(It.Key == EMovementIterationDeltaStateType::Movement)
			{
				TempLogPage
					.DirectionalArrow("Pre Land Horizontal Velocity", Owner.ActorLocation, PreLandHorizontalDelta.Velocity, 20, 4000, FLinearColor::Red)
					.DirectionalArrow("Post Horizontal Velocity", Owner.ActorLocation, HorizontalMovementDelta.Velocity, 20, 4000, FLinearColor::Red)
					.DirectionalArrow("Vertical Velocity", Owner.ActorLocation, VerticalDelta.Velocity, 20, 4000, FLinearColor::Blue)
				;
			}
		}


		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		auto RollComp = UTeenDragonRollComponent::Get(Owner);
		if(ImpactData.ResponseCompHitData.Num() > 0)
		{
			RollComp.CrumbSendRollHits(ImpactData.ResponseCompHitData);
		}	

		if(ImpactData.BounceData.IsSet())
		{
			auto BounceComp = UTeenDragonRollBounceComponent::Get(Owner);
			auto BounceData = ImpactData.BounceData.Value;
			BounceComp.PreviousBounceData = BounceData;
			BounceComp.LastResolverBounceFrame = Time::FrameNumber;

			BounceComp.CrumbSendOnBounceEvent(BounceData.BounceLocation, BounceData.BounceHitNormal, BounceData.SpeedIntoGroundNormal);
		}
		else if(ImpactData.KnockbackData.IsSet())
		{
			auto RollParams = ImpactData.KnockbackData.Value.RollParams;
			RollComp.CrumbSendRollWallKnockback(RollParams);

			auto KnockbackSettings = ImpactData.KnockbackData.Value.KnockbackSettings;

			FVector DirToImpact = (RollParams.HitLocation - RollParams.PlayerInstigator.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FHazeCameraImpulse CamImpulse;
			float ImpulseSize = RollParams.SpeedTowardsImpact * KnockbackSettings.WallKnockbackCameraImpulsePerSpeedIntoWall;
			ImpulseSize = Math::Clamp(ImpulseSize, KnockbackSettings.WallKnockbackCameraImpulseMinSize, KnockbackSettings.WallKnockbackCameraImpulseMaxSize);
			CamImpulse.WorldSpaceImpulse = DirToImpact * ImpulseSize;
			CamImpulse.Dampening = KnockbackSettings.WallKnockbackCameraImpulseDampening;
			CamImpulse.ExpirationForce = KnockbackSettings.WallKnockbackCameraImpulseExpirationForce;
			

			FTeenDragonRollWallKnockbackParams KnockbackParams;
			KnockbackParams.CameraImpulse = CamImpulse;
			RollComp.KnockbackParams.Set(KnockbackParams);
		}
		else if(ImpactData.ReflectOffWallData.IsSet())
		{
			auto ReflectOffData = ImpactData.ReflectOffWallData.Value;

			auto KnockbackSettings = ReflectOffData.KnockbackSettings;

			FVector DirToImpact = (ReflectOffData.HitLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FHazeCameraImpulse CamImpulse;
			float ImpulseSize = ReflectOffData.SpeedIntoWall * KnockbackSettings.ReflectCameraImpulsePerSpeedIntoWall;
			ImpulseSize = Math::Clamp(ImpulseSize, KnockbackSettings.ReflectCameraImpulseMinSize, KnockbackSettings.ReflectCameraImpulseMaxSize);
			CamImpulse.WorldSpaceImpulse = DirToImpact * ImpulseSize;
			CamImpulse.Dampening = KnockbackSettings.ReflectCameraImpulseDampening;
			CamImpulse.ExpirationForce = KnockbackSettings.ReflectCameraImpulseExpirationForce;
			ReflectOffData.CameraImpulse = CamImpulse;

			RollComp.ReflectOffWallData.Set(ReflectOffData);
		}
	}
}