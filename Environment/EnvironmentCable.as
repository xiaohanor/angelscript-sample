
/**
 * Cables that we hang in the level that react to forces. 
 * Supports attachments and detachments.
 * 
 * @TODO: once ribbons are supported on GPU, next UE update, 
 * then we switch to the niagara implementation instead. 
 */

event void FShockwaveForceHitEvent(FVector AverageForce);

UCLASS(Abstract)
class AEnvironmentCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UEnvironmentCableComponent Cable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RemoveAllShockwaveForce();
		Environment::GetForceEmitter().RegisterCable(this);
		Cable.bFirstFrame = false;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		RemoveAllShockwaveForce();
		Environment::GetForceEmitter().UnregisterCable(this);
	}

	/** Will update the force if it finds a matching Instigator otherwise a new one will be added */
	UFUNCTION(BlueprintCallable, Category = "EnvironmentCable")
	void AddShockwaveForce(const FEnvironmentShockwaveForceData& ForceData)
	{
		// don't let shockwave forces stack up while being disabled
		if(IsActorDisabled())
			return;

		Cable.AddShockwaveForce(ForceData);
	}

	/** remove all forces that are tagged with this instigator */
	UFUNCTION(BlueprintCallable, Category = "EnvironmentCable")
	void RemoveShockwaveForce(FInstigator Instigator)
	{
		Cable.RemoveShockwaveForce(Instigator);
	}

	/** removes all forces from the cable, including pending ones */
	UFUNCTION(BlueprintCallable, Category = "EnvironmentCable")
	void RemoveAllShockwaveForce()
	{
		Cable.PendingShockwaveForces.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR
		Cable.WarmupTick(Cable.WarmupTime);
#endif
		Cable.bFirstFrame = false;
	}
}

UCLASS(NotBlueprintable)
class UEnvironmentCableComponent : UHazeTEMPCableComponent
{
	default CableForce = FVector::ZeroVector;
	default EndLocation = FVector(0,0, -1000);
	default bEnableCollision = false;
	default bEnableStiffness = false;
	default SolverIterations = 3;
	default CableLength = 1000;
	default NumSegments = 1;
	default CableWidth = 10;
	default SubstepTime = 0.005;
	default bSkipCableUpdateWhenNotOwnerRecentlyRendered = true;
	default bBlockVisualsOnDisable = false;

	/* 	The friction of the velocity, where 0 is no friction and 
		extends to infinity (2.3 is almost instant) */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Cable")
	float Friction = 1.0;

	/**
	 * Scale the force to visually match other force receiver actors
	 * (the cable needs a stronger force because its tethered)
	 */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Cable")
	float ShockwaveForceScaler = 1000.0;

	TArray<FEnvironmentShockwaveForceData> PendingShockwaveForces;

	// will trigger when the swing get hit by a force
	UPROPERTY(Category = "Cable")
	FShockwaveForceHitEvent OnHitByShockwave;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Cable")
	bool bApplyFirstFrameReset = false;
	bool bFirstFrame = false;

	// useful if we have a texture material and we don't want it to stretch as the cable becomes longer.
	UFUNCTION(Category = "Cable", CallInEditor)
	void CalculateAndSetMaterialTilingParam()
	{
		const float CurrentLinearCableLength = (EndLocation - StartLocation).Size();
		const float CurrentRopeLength = Math::Max(Math::Max(CableLength, CurrentLinearCableLength), 1.0);
		TileMaterial = CurrentRopeLength * 0.01;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// reset the cable the first frame due to Particle init happening
		// in OnRegister(). Sequencer does not account for that so we have to 
		// do this workaround of reinitializing here once.
		if(bFirstFrame == false)
		{
			if(bApplyFirstFrameReset)
			{
				ResetCable();
			}
			bFirstFrame = true;
		}

		ResetParticleForces();
		ConsumeShockwaveForces(DeltaSeconds);
		ApplyFriction(DeltaSeconds);
	}

	// @TODO perhaps switch to using the global CableForce variabel instead
	// and computing that for the center of mass instead. Probably cheaper
	// and the difference is quite minimal visually based on what we need.
	void ConsumeShockwaveForces(const float Dt)
	{
		if(PendingShockwaveForces.Num() <= 0)
			return;

		for(int i = PendingShockwaveForces.Num() - 1; i >= 0; --i)
		{
			auto& IterShockwaveForce = PendingShockwaveForces[i];

			FVector AverageForce = FVector::ZeroVector;

			for(auto& IterParticle : Particles)
			{
				FVector Force = IterShockwaveForce.CalculateForceForTarget(IterParticle.Position);

				if(Force.IsZero())
					continue;

				Force *= ShockwaveForceScaler;

				IterParticle.Force += Force;

				AverageForce += IterParticle.Force;
			}

			AverageForce /= Particles.Num();

			OnHitByShockwave.Broadcast(AverageForce);

		}

		PendingShockwaveForces.Empty();
	}

	// @TODO move this to the actual cablecomponent instead
	void ApplyFriction(const float Dt)
	{
		if(Friction == 0)
			return;

		for(int i = 0; i < Particles.Num()-1; ++i)
		{
			const auto& Particle = Particles[i];
			FVector NewParticleVelocity = Particle.Position - Particle.OldPosition;
			NewParticleVelocity /= SubstepTime; 
			NewParticleVelocity *= Math::Pow(Math::Exp(-Friction), Dt);
			SetParticleVelocity(i, NewParticleVelocity);
		}
	}

	void AddShockwaveForce(const FEnvironmentShockwaveForceData& ShockwaveForce)
	{
		PendingShockwaveForces.Add(ShockwaveForce);
	}

	void RemoveShockwaveForce(FInstigator Instigator)
	{
		for (int i = PendingShockwaveForces.Num() - 1; i >= 0; --i)
		{
			auto& IterShockwaveForce = PendingShockwaveForces[i];
			if (IterShockwaveForce.OptionalInstigator == Instigator)
			{
				PendingShockwaveForces.RemoveAt(i);
			}
		}

		// clear all forces here because it won't do the cleanup on tick since its empty
		if(PendingShockwaveForces.Num() <= 0)
		{
			ResetParticleForces();
		}
	}

	void ClearShockwaveForces()
	{
		PendingShockwaveForces.Empty();
		ResetParticleForces();
	}

}