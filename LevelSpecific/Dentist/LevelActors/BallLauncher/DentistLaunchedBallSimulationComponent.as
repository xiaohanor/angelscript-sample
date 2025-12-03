UCLASS(NotBlueprintable)
class UDentistLaunchedBallSimulationComponent : UDentistSimulationComponent
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float InitialSpeed = 2000;

	/**
	 * How much to bounce when hitting a surface.
	 * 0 is no bounce, 1 is velocity fully kept and reflected.
	 */
	UPROPERTY(EditAnywhere, Category = "Movement")
	float Restitution = 0;

	/**
	 * How much to bounce when hitting another ball.
	 * 0 is no bounce, 1 is velocity fully kept and reflected.
	 */
	UPROPERTY(EditAnywhere, Category = "Movement")
	float CollisionRestitution = 0.5;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float Gravity = 2000;
	
	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactAwayImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	bool bPlayerImpactNeverLaunchDownwards = true;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactVerticalImpulse = 1500;

	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	FDentistLaunchedBallSimulation Simulation;

	UPROPERTY(EditAnywhere, Category = "Simulation")
	int MaxSubstepCount = 3;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization")
	bool bVisualizeImpacts = false;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Visualization")
	int VisualizeStep = -1;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Collision")
	bool bIgnoreStartPenetrating = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Collision")
	TArray<AActor> ActorsToIgnoreCollisionWith;

	UPROPERTY(EditInstanceOnly, Category = "Simulation|Follow Ground")
	float FollowGroundFriction = 0.5;

	UPROPERTY(EditDefaultsOnly, Category = "VFX")
	UNiagaraSystem SplashSystem;

	UPROPERTY(BlueprintReadOnly)
	FDentistLaunchedBallStartMoving OnStartMoving;

	UPROPERTY(BlueprintReadOnly)
	FDentistLaunchedBallHitWater OnHitWater;

	private ADentistLaunchedBall Ball;
	private ALandscape ChocolateWaterLandscape;
	private FVector VelocityToApplyOnDetach;

	FVector PendingImpulse = FVector::ZeroVector;
	TArray<AActor> TempIgnoredActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Ball = Cast<ADentistLaunchedBall>(Owner);
	}

#if EDITOR
	void PrepareSimulation(ADentistSimulationLoop InSimulationLoop) override
	{
		Super::PrepareSimulation(InSimulationLoop);

		Ball = Cast<ADentistLaunchedBall>(Owner);
		Simulation = FDentistLaunchedBallSimulation();

		FDentistBallLauncherSimulationStep InitialStep;
		InitialStep.SimulationLocation = Ball.SphereComp.WorldLocation;
		InitialStep.Velocity = Ball.ActorForwardVector * InitialSpeed;
		InitialStep.Time = 0;
		Simulation.AddStep(InitialStep);
	
		ChocolateWaterLandscape = Dentist::GetChocolateWaterLandscapeEditor();

		VelocityToApplyOnDetach = FVector::ZeroVector;

		Ball.SphereComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		TempIgnoredActors.Reset();
		
		if(bIgnoreStartPenetrating)
		{
			FHazeTraceSettings OverlapSettings = GetTraceSettings();
			OverlapSettings.UseSphereShape(Ball.SphereComp.SphereRadius * 2);
			auto InitialOverlaps = OverlapSettings.QueryOverlaps(Ball.SphereComp.WorldLocation);

			for(const FOverlapResult& InitialOverlap : InitialOverlaps)
			{
				if(InitialOverlap.Actor == nullptr)
					continue;

				if(InitialOverlap.Actor.IsA(ADentistLaunchedBall))
					continue;

				TempIgnoredActors.AddUnique(InitialOverlap.Actor);
			}
		}
	}

	void PreIteration(float TimeSinceStart, float LoopDuration) override
	{
		if(!PendingImpulse.IsNearlyZero())
		{
			// Apply pending impulses from last frame
			Simulation.GetLastStepRef().Velocity += PendingImpulse;
			PendingImpulse = FVector::ZeroVector;
		}
	}

	void RunIteration(float TimeSinceStart, float TimeStep) override
	{
		if(Simulation.HasHitWater())
			return;

		Ball.SphereComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		FDentistBallLauncherSimulationStep IterationStep = Simulation.GetLastStep();

		if(IterationStep.AttachedTo != nullptr)
		{
			FVector RelativeLocationLastIteration = IterationStep.AttachmentTransformLastIteration.InverseTransformPositionNoScale(IterationStep.SimulationLocation);
			FVector RelativeVelocityLastIteration = IterationStep.AttachmentTransformLastIteration.InverseTransformVectorNoScale(IterationStep.Velocity);

			FTransform AttachmentTransformThisIteration = IterationStep.AttachedTo.WorldTransform;
			
			FVector PreviousLocation = IterationStep.SimulationLocation;

			IterationStep.SimulationLocation = AttachmentTransformThisIteration.TransformPositionNoScale(RelativeLocationLastIteration);
			//IterationStep.Velocity = AttachmentTransformThisIteration.TransformVectorNoScale(RelativeVelocityLastIteration);
			
			//IterationStep.Velocity += AdditionalVelocity * FollowGroundFriction;

			VelocityToApplyOnDetach = (IterationStep.SimulationLocation - PreviousLocation) / TimeStep;
		}

		int SubstepCount = 0;
		float SubstepDeltaTime = TimeStep;
		while(SubstepDeltaTime > KINDA_SMALL_NUMBER)
		{
			SubstepCount++;

			if(SubstepCount > MaxSubstepCount)
				break;

			float PerformedMovementAlpha = 0;
			if(!RunSimulationSweep(IterationStep, Simulation.Impacts, PerformedMovementAlpha, SubstepDeltaTime))
			{
				IterationStep.Time = TimeSinceStart;
				Simulation.AddStep(IterationStep);
				break;
			}

			SubstepDeltaTime *= (1.0 - PerformedMovementAlpha);

			// If we redirected, set the time to the redirect location
			if(SubstepDeltaTime > 0)
				IterationStep.Time = TimeSinceStart - SubstepDeltaTime;
			else
				IterationStep.Time = TimeSinceStart;

			Simulation.AddStep(IterationStep);

			const FVector Location = IterationStep.SimulationLocation;
			float32 ChocolateWaterHeight = 0;
			ChocolateWaterLandscape.GetHeightAtLocation(Location, ChocolateWaterHeight);

			if(Location.Z < (ChocolateWaterHeight - Ball.GetRadius()))
			{
				Simulation.HitWaterIndex = Simulation.GetStepCount() - 1;
				break;
			}
		}

		Ball.SphereComp.SetWorldLocation(IterationStep.SimulationLocation);
	}

	void PostIteration(float TimeSinceStart) override
	{
		if(Simulation.HasHitWater())
		{
			Ball.SphereComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			return;
		}

		FDentistBallLauncherSimulationStep& IterationStep = Simulation.GetLastStepRef();
		
		const bool bHasFoundGround = IterationStep.GroundContact.IsWalkableGroundContact() && IterationStep.GroundContact.Component != nullptr;
		const bool bIsAttached = IterationStep.AttachedTo != nullptr;
		
		if(bHasFoundGround)
		{
			if(bIsAttached)
			{
				const bool bIsNewAttachment = IterationStep.AttachedTo != IterationStep.GroundContact.Component;

				if(bIsNewAttachment)
				{
					// Detach and attach to new ground
					IterationStep.AttachedTo = IterationStep.GroundContact.Component;
					IterationStep.Velocity += VelocityToApplyOnDetach;
					IterationStep.AttachmentTransformLastIteration = IterationStep.AttachedTo.WorldTransform;
				}
				else
				{
					// Same attachment, follow with it
					IterationStep.AttachmentTransformLastIteration = IterationStep.AttachedTo.WorldTransform;
				}
			}
			else
			{
				// We were not attached, attach!
				IterationStep.AttachedTo = IterationStep.GroundContact.Component;
				IterationStep.AttachmentTransformLastIteration = IterationStep.AttachedTo.WorldTransform;
			}
		}
		else
		{
			if(bIsAttached)
			{
				// No ground found, but we have an attachment, detach
				IterationStep.AttachedTo = nullptr;
				IterationStep.Velocity += VelocityToApplyOnDetach;
			}
		}
	}

	void SerializeSimulation() override
	{
		Simulation.SerializeStepsRelativeTo(SimulationLoop);
	}

	void ResetPostSimulation() override
	{
		Ball.SphereComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Ball.SphereComp.SetRelativeLocation(FVector::ZeroVector);
	}

	bool RunSimulationSweep(FDentistBallLauncherSimulationStep& IterationStep, TArray<FDentistLaunchedBallImpact>& Impacts, float&out OutPerformedMovementAlpha, float DeltaTime) const
	{
		if(DeltaTime < KINDA_SMALL_NUMBER)
			return false;

		// The only force acting on these balls is gravity
		IterationStep.Velocity += FVector::DownVector * Gravity * DeltaTime;

		if(IterationStep.bIsGrounded)
		{
			if(IterationStep.Velocity.DotProduct(IterationStep.GroundContact.ImpactNormal) < 0)
			{
				// Clip velocity going into the ground
				IterationStep.Velocity = IterationStep.Velocity.VectorPlaneProject(IterationStep.GroundContact.ImpactNormal);
			}
		}

		const FVector DeltaToTrace = IterationStep.Velocity * DeltaTime;
		if(DeltaToTrace.IsNearlyZero())
			return false;

		const FMovementHitResult SweepImpact = SweepIteration(IterationStep.SimulationLocation, IterationStep.Velocity, DeltaToTrace, OutPerformedMovementAlpha);

		if(SweepImpact.IsValidBlockingHit())
		{
			Impacts.Add(FDentistLaunchedBallImpact(SweepImpact.ConvertToHitResult(), IterationStep.Time, IterationStep.Velocity.Size()));

			if(HitOtherBall(IterationStep.SimulationLocation, IterationStep.Velocity, SweepImpact))
			{
				return true;
			}

			if(Bounce(IterationStep.SimulationLocation, IterationStep.Velocity, SweepImpact))
			{
				IterationStep.GroundContact = FMovementHitResult();
				IterationStep.bIsGrounded = false;
				return true;
			}

			// Project velocity onto sweep impact
			IterationStep.Velocity = ProjectMovementUponImpact(IterationStep.Velocity, SweepImpact, IterationStep.GroundContact);

			if(SweepImpact.IsWalkableGroundContact())
			{
				IterationStep.GroundContact = SweepImpact;
				IterationStep.bIsGrounded = true;
			}
		}

		// Find ground
		if(!SweepImpact.IsWalkableGroundContact())
		{
			const FMovementHitResult GroundImpact = GroundSweep(IterationStep.SimulationLocation);

			if(GroundImpact.IsValidBlockingHit())
			{
				// Project velocity onto ground impact
				//IterationStep.Velocity = ProjectMovementUponImpact(IterationStep.Velocity, GroundImpact, IterationStep.GroundContact);

				if(HitOtherBall(IterationStep.SimulationLocation, IterationStep.Velocity, GroundImpact))
				{
					Impacts.Add(FDentistLaunchedBallImpact(GroundImpact.ConvertToHitResult(), IterationStep.Time, IterationStep.Velocity.Size()));
					return true;
				}

				if(Bounce(IterationStep.SimulationLocation, IterationStep.Velocity, GroundImpact))
				{
					Impacts.Add(FDentistLaunchedBallImpact(GroundImpact.ConvertToHitResult(), IterationStep.Time, IterationStep.Velocity.Size()));
					return true;
				}

				//IterationStep.Location = GroundImpact.Location + GroundImpact.ImpactNormal;
			}

			IterationStep.GroundContact = GroundImpact;
			IterationStep.bIsGrounded = GroundImpact.IsAnyWalkableContact();
		}
		else
		{
			IterationStep.GroundContact = SweepImpact;
		}

		if(IterationStep.GroundContact.IsAnyGroundContact())
		{
			IterationStep.GroundContact.bIsWalkable = true;

			auto GroundAsBall = Cast<ADentistLaunchedBall>(IterationStep.GroundContact.Actor);
			if(GroundAsBall != nullptr)
				IterationStep.GroundContact.bIsWalkable = false;

			IterationStep.bIsGrounded = IterationStep.GroundContact.IsAnyWalkableContact();
		}

		return true;
	}

	FMovementHitResult SweepIteration(FVector& Location, FVector& Velocity, FVector Delta, float&out OutPerformedMovementAlpha) const
	{
		if(!ensure(!Delta.IsNearlyZero()))
			return FMovementHitResult();

		const FHitResult Hit = GetTraceSettings().QueryTraceSingle(Location, Location + Delta);

		if(Hit.bStartPenetrating)
		{
			Location = Hit.Location + GetPenetrationAdjustment(Hit);
			Velocity = FVector::ZeroVector;
			OutPerformedMovementAlpha = 1.0;
			return FMovementHitResult();
		}

		if(!Hit.IsValidBlockingHit())
		{
			Location += Delta;
			OutPerformedMovementAlpha = 1.0;
			return FMovementHitResult();
		}

		Location = Hit.Location + Hit.ImpactNormal;
		OutPerformedMovementAlpha = Hit.Time;
		return MovementHitFromHitResult(Hit);
	}

	FVector GetPenetrationAdjustment(FHitResult SweepHit) const
	{
		check(!SweepHit.Normal.IsZero(), "Trying to call GetPenetrationAdjustment() with an IterationHit that has a ZeroVector Normal, this will return no adjustment at all!");
		
		const float PenetrationPullbackDistance = 0.125;
		const float PenetrationDepth = (SweepHit.PenetrationDepth > 0.0 ? SweepHit.PenetrationDepth : PenetrationPullbackDistance);
		return SweepHit.Normal * (PenetrationDepth + PenetrationPullbackDistance);
	}

	bool HitOtherBall(FVector& Location, FVector& Velocity, FMovementHitResult Impact) const
	{
		auto OtherBall = Cast<ADentistLaunchedBall>(Impact.Actor);
		if(OtherBall == nullptr)
			return false;

		if(Velocity.DotProduct(Impact.ImpactNormal) > -50)
			return false;

		Location = Impact.Location + Impact.ImpactNormal;

		FVector VelocityAlongNormal = Velocity.ProjectOnToNormal(Impact.Normal);
		FVector VelocityAlongPlane = Velocity - VelocityAlongNormal;

		FVector PreviousVelocity = Velocity;

		VelocityAlongNormal = VelocityAlongNormal.GetSafeNormal() * -VelocityAlongNormal.Size() * CollisionRestitution;
		Velocity = VelocityAlongPlane + VelocityAlongNormal;

		FVector VelocityDifference = Velocity - PreviousVelocity;

		OtherBall.SimulationComp.PendingImpulse += -VelocityDifference;

		return true;
	}

	bool Bounce(FVector& Location, FVector& Velocity, FMovementHitResult Impact) const
	{
		if(Restitution < KINDA_SMALL_NUMBER)
			return false;

		if(Velocity.DotProduct(Impact.ImpactNormal) > -50)
			return false;

		// Bounce!
		Location = Impact.Location + Impact.ImpactNormal;

		FVector VelocityAlongNormal = Velocity.ProjectOnToNormal(Impact.Normal);
		FVector VelocityAlongPlane = Velocity - VelocityAlongNormal;

		VelocityAlongNormal = VelocityAlongNormal.GetSafeNormal() * -VelocityAlongNormal.Size() * Restitution;
		Velocity = VelocityAlongPlane + VelocityAlongNormal;
		return true;
	}

	FVector ProjectMovementUponImpact(FVector Velocity, FMovementHitResult Impact, FMovementHitResult GroundContact) const
	{
		check(Impact.IsValidBlockingHit());

		const bool bHitCanBeGround = Impact.IsWalkableGroundContact();

		if(GroundContact.IsWalkableGroundContact())
		{
			// on grounded impacts, we redirect the delta without any loss
			if(bHitCanBeGround)
			{
				// If we are on edges, we use the impact normal instead to not get sucked down
				FVector ImpactNormal = Impact.Normal;

				FVector ConstrainedVelocity = Velocity.VectorPlaneProject(Impact.Normal);
				
				ConstrainedVelocity = SurfaceProject(Velocity, ImpactNormal, FVector::UpVector);
				return ConstrainedVelocity;
			}

			// On blocking hits, project the movement on the obstruction while following the grounding plane
			else
			{
				// Generate a correct impact normal along the grounded surface
				const FVector GroundNormal = GroundContact.Normal;
				const FVector ImpactNormal = Impact.Normal.GetImpactNormalProjectedAlongSurface(GroundNormal, FVector::UpVector);

				const FVector ObstructionRightAlongGround = ImpactNormal.CrossProduct(GroundNormal).GetSafeNormal();
				const FVector ObstructionUpAlongGround = ObstructionRightAlongGround.CrossProduct(ImpactNormal).GetSafeNormal(ResultIfZero = GroundNormal);

				FVector ConstrainedVelocity = SurfaceProject(Velocity, ObstructionUpAlongGround, FVector::UpVector);
				return ConstrainedVelocity.VectorPlaneProject(ImpactNormal);
			}

		}
		else
		{
			// This is a landing impact
			if(bHitCanBeGround)
			{
				FVector ConstrainedVelocity = Velocity.VectorPlaneProject(FVector::UpVector);
				ConstrainedVelocity = ConstrainedVelocity.VectorPlaneProject(Impact.Normal);
				return SurfaceProject(ConstrainedVelocity, Impact.Normal, FVector::UpVector);
			}

			// Generic impact
			else
			{
				return Velocity.VectorPlaneProject(Impact.Normal);
			}
		}
	}

	FVector SurfaceProject(FVector Velocity, FVector SurfaceNormal, FVector WorldUp) const
	{
		return Velocity.GetDirectionTangentToSurface(SurfaceNormal, WorldUp) * Velocity.Size();
	}

	FMovementHitResult GroundSweep(FVector Location, float Distance = 10) const
	{
		const FVector DeltaToTrace = FVector::DownVector * Distance;
		FHitResult Hit = GetTraceSettings().QueryTraceSingle(Location, Location + DeltaToTrace);

		return MovementHitFromHitResult(Hit);
	}

	FMovementHitResult MovementHitFromHitResult(FHitResult HitResult) const
	{
		FMovementHitResult MovementHit(HitResult, KINDA_SMALL_NUMBER);

		if(MovementHit.IsValidBlockingHit())
		{
			if(HitResult.ImpactNormal.GetAngleDegreesTo(FVector::UpVector) > 80)
			{
				MovementHit.Type = EMovementImpactType::Wall;
			}
			else
			{
				MovementHit.Type = EMovementImpactType::Ground;
				MovementHit.bIsWalkable = Cast<ADentistLaunchedBall>(HitResult.Actor) == nullptr;
			}
		}

		return MovementHit;
	}

	FHazeTraceSettings GetTraceSettings() const
    {
        FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
        TraceSettings.IgnoreActor(Ball);
		TraceSettings.IgnoreActors(TempIgnoredActors);

		TraceSettings.IgnoreActors(ActorsToIgnoreCollisionWith);
        TraceSettings.UseSphereShape(Ball.GetRadius());

        return TraceSettings;
    }

	UFUNCTION(CallInEditor)
	void UpdateIsGrounded()
	{
		Ball = Cast<ADentistLaunchedBall>(Owner);

		for(int i = 0; i < Simulation.GetStepCount(); i++)
		{
			auto& Step = Simulation.GetStepAtIndex(i);
			FVector Location = Step.GetPlaybackLocation(SimulationLoop) + FVector(0, 0, 100);
			FMovementHitResult Hit = GroundSweep(Location, 110);
			if(Hit.IsAnyGroundContact())
			{
				Step.bIsGrounded = true;
			}
			else
			{
				Step.bIsGrounded = false;
			}
		}
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer, float LoopTime, float LoopDuration) const override
	{
		auto OwningBall = Cast<ADentistLaunchedBall>(Owner);
		if(OwningBall == nullptr)
			return;

		if(Simulation.GetStepCount() == 0)
			return;
		
		float LineThickness = 2.0;
		TOptional<FLinearColor> DebugColor;
		if(Editor::IsPlaying())
		{
			const bool bIsSelected = Editor::IsSelected(Owner);
			if(bIsSelected)
			{
				LineThickness = 5.0;
			}
			else
			{
				DebugColor = FLinearColor::Gray;
			}
		}
		else
		{
			if(!Editor::IsSelected(Dentist::Simulation::FindOwningSimulationLoop(this)))
			{
				const bool bIsSelected = Editor::IsSelected(Owner);
				if(bIsSelected)
				{
					LineThickness = 5.0;
				}
				else
				{
					DebugColor = FLinearColor::Gray;
				}
			}
		}

		FDentistBallLauncherSimulationStep PreviousStep = Simulation.GetStepAtIndex(0);
		for(int i = 1; i < Simulation.GetStepCount(); i++)
		{
			const FDentistBallLauncherSimulationStep CurrentStep = Simulation.GetStepAtIndex(i);
			
			FLinearColor LineColor = (i % 2 == 0) ? FLinearColor::Green : FLinearColor::Red;

			if(CurrentStep.bIsGrounded)
				LineColor = FLinearColor::Black;

			if(DebugColor.IsSet())
				LineColor = DebugColor.Value;

			Visualizer.DrawLine(PreviousStep.GetPlaybackLocation(SimulationLoop), CurrentStep.GetPlaybackLocation(SimulationLoop), LineColor, LineThickness);

			PreviousStep = CurrentStep;
		}

		if(bVisualizeImpacts)
		{
			for(int i = 0; i < Simulation.Impacts.Num(); i++)
			{
				const FDentistLaunchedBallImpact Impact = Simulation.Impacts[i];
				bool bIsRolling;
				FVector ImpactLocation = Simulation.GetStepAtTime(Impact.Time, bIsRolling).GetPlaybackLocation(SimulationLoop);
				Visualizer.DrawWireSphere(ImpactLocation, OwningBall.GetRadius(), FLinearColor::Teal, 3, 16, false);

				auto ImpactActor = Impact.GetActor();
				if(ImpactActor != nullptr)
					Visualizer.DrawWorldString(f"Impact {i + 1} with {ImpactActor.GetActorNameOrLabel()}", ImpactLocation, FLinearColor::White, 1.5, bCenterText = true);
			}
		}

		if(VisualizeStep >= 0 && VisualizeStep < Simulation.GetStepCount())
		{
			auto Step = Simulation.GetStepAtIndex(VisualizeStep);
			FVector StepLocation = Step.GetPlaybackLocation(SimulationLoop);
			Visualizer.DrawWireSphere(StepLocation, OwningBall.GetRadius(), FLinearColor::Teal, 3, 16, false);
			Visualizer.DrawWorldString(f"Step {VisualizeStep}", StepLocation, FLinearColor::White, 1.5, bCenterText = true);
		}

		EDentistLaunchedBallLoopState LoopState;
		const float MoveTime = Simulation.GetMoveTime(LoopTime, LoopState);

		TOptional<FDentistBallLauncherSimulationStep> BallSimulationStep;
		FString DebugString;
		FLinearColor BallColor;

		switch(LoopState)
		{
			case EDentistLaunchedBallLoopState::WaitingAtStart:
				BallSimulationStep = Simulation.GetFirstStep();
				DebugString += f"Waiting to Start: {LoopTime:.2}/{SimulationStartOffset}";
				BallColor = FLinearColor::Yellow;
				break;

			case EDentistLaunchedBallLoopState::Moving:
			{
				bool bIsRolling = false;
				BallSimulationStep = Simulation.GetStepAtTime(MoveTime, bIsRolling);

				const int Step = Simulation.GetStepIndexAtTime(MoveTime);
				DebugString += f"MoveTime: {MoveTime:.2}/{Simulation.GetMoveEndTime()}";
				DebugString += f"\nStep {Step + 1}/{Simulation.GetStepCount()}";
				DebugString += f"\nSpeed: {BallSimulationStep.Value.Velocity.Size():.0}";
				DebugString += f"\nIs Rolling: {bIsRolling}";
				BallColor = FLinearColor::Green;
				break;
			}


			case EDentistLaunchedBallLoopState::WaitingAtEnd:
			{
				BallSimulationStep = Simulation.GetLastStep();
				const float EndDelay = LoopDuration - Simulation.GetMoveEndTime();
				const float TimeSinceEnd = LoopTime - Simulation.GetMoveEndTime();
				DebugString += f"Waiting For End: {TimeSinceEnd:.2}/{EndDelay:.2}";
				BallColor = FLinearColor::Red;
				break;
			}
		}

		if(!ensure(BallSimulationStep.IsSet()))
			return;

		if(DebugColor.IsSet())
			BallColor = DebugColor.Value;

		const FVector BallLocation = BallSimulationStep.Value.GetPlaybackLocation(SimulationLoop);
		const FVector BallVelocity = BallSimulationStep.Value.Velocity;

		Visualizer.DrawWireSphere(BallLocation, OwningBall.GetRadius(), BallColor, LineThickness, 16, true);
		Visualizer.DrawWorldString(DebugString, BallLocation, BallColor);
		Visualizer.DrawArrow(BallLocation, BallLocation + BallVelocity, BallColor, 10, LineThickness, true);
	}
#endif
};