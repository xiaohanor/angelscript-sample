struct FTundra_River_InteractableBellRopeVolatileParticleForce
{
	FTundra_River_InteractableBellRopeVolatileParticleForce(int In_ParticleIndex, FVector In_ParticleForce, float In_ParticleDrag)
	{
		ParticleIndex = In_ParticleIndex;
		ParticleForce = In_ParticleForce;
		ParticleDrag = In_ParticleDrag;
	}

	FTundra_River_InteractableBellRopeVolatileParticleForce(int In_ParticleIndex)
	{
		ParticleIndex = In_ParticleIndex;
	}

	int ParticleIndex;
	FVector ParticleForce;
	float ParticleDrag;

	bool opEquals(FTundra_River_InteractableBellRopeVolatileParticleForce Other) const
	{
		return ParticleIndex == Other.ParticleIndex;
	}
}

UCLASS(Abstract)
class ATundra_River_InteractableBellRope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeTEMPCableComponent CableComp;
	//default CableComp.bUseSubstepping = true;
	default CableComp.bSkipCableUpdateWhenNotVisible = true;

	UPROPERTY(EditAnywhere)
	float WindMaxForce = 500.0;

	UPROPERTY(EditAnywhere)
	float CableEndForce = 0.0;

	UPROPERTY(EditAnywhere)
	bool bAttachEnd = true;

	UPROPERTY(EditAnywhere)
	FVector EndLocation = FVector(2000.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	float CableWidth = 15.0;

	UPROPERTY(EditAnywhere)
	float TileMaterial = 20.0;

	/* If false, will only apply wind in right/left direction, if true will also apply wind in forward/back direction */
	UPROPERTY(EditAnywhere)
	bool bApplyWindInAllDirections = false;

	TArray<FTundra_River_InteractableBellRopeVolatileParticleForce> VolatileParticleForces;
	float RandomWindOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetCableCompValues();
	}

	void SetCableCompValues()
	{
		CableComp.bAttachEnd = bAttachEnd;
		CableComp.CableLength = EndLocation.Size();
		CableComp.EndLocation = EndLocation;
		CableComp.CableWidth = CableWidth;
		CableComp.TileMaterial = TileMaterial;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RandomWindOffset = Math::RandRange(0.0, 3.0);
		SetCableCompValues();
		CableComp.Particles[CableComp.Particles.Num() - 1].Force = FVector::DownVector * CableEndForce;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleWindForce();
		HandleVolatileParticleForces(DeltaTime);
	}

	void ApplyImpulseAtLocationWithDrag(FVector WorldLocation, FVector Impulse, float Drag)
	{
		int ParticleIndex1, ParticleIndex2;
		float Alpha;
		GetClosestParticlesToWorldLocation(WorldLocation, ParticleIndex1, ParticleIndex2, Alpha);

		Internal_AddImpulseToParticle(ParticleIndex1, Impulse * (1.0 - Alpha), Drag);
		Internal_AddImpulseToParticle(ParticleIndex2, Impulse * Alpha, Drag);
	}

	// Based on the input world location it will return ClosestParticleIndex1 and ClosestParticleIndex2, ClosestPointOnCable = Math::Lerp(ClosestParticle1, ClosestParticle2, ParticleAlpha)
	void GetClosestParticlesToWorldLocation(FVector WorldLocation, int&out ClosestParticleIndex1, int&out ClosestParticleIndex2, float&out ParticleAlpha)
	{
		int ClosestParticleIndex = -1;
		float ClosestSqrDist = MAX_flt;
		FVector ClosestPointOnCable;

		for(int i = 0; i < CableComp.Particles.Num() - 1; i++)
		{
			FCableParticle Particle1 = CableComp.Particles[i];
			FCableParticle Particle2 = CableComp.Particles[i + 1];

			FVector ClosestPoint = Math::ClosestPointOnLine(Particle1.Position, Particle2.Position, WorldLocation);
			float SqrDist = ClosestPoint.DistSquared(WorldLocation);
			if(SqrDist < ClosestSqrDist)
			{
				ClosestParticleIndex = i;
				ClosestSqrDist = SqrDist;
				ClosestPointOnCable = ClosestPoint;
			}
		}

		ClosestParticleIndex1 = ClosestParticleIndex;
		ClosestParticleIndex2 = ClosestParticleIndex + 1;

		FCableParticle Particle1 = CableComp.Particles[ClosestParticleIndex1];
		FCableParticle Particle2 = CableComp.Particles[ClosestParticleIndex2];

		FVector Part1ToPart2 = (Particle2.Position - Particle1.Position);
		FVector Part1ToPart2Dir = Part1ToPart2.GetSafeNormal();
		FVector Part1ToClosestPoint = (ClosestPointOnCable - Particle1.Position);
		float Part1ToPart2Dist = Part1ToPart2Dir.DotProduct(Part1ToPart2);
		float Part1ToClosestPointDist = Part1ToPart2Dir.DotProduct(Part1ToClosestPoint);

		ParticleAlpha = (Part1ToClosestPointDist / Part1ToPart2Dist);
	}

	private void HandleWindForce()
	{
		float WindValue = Math::PerlinNoise1D(Time::GetGameTimeSeconds() * 0.5 + RandomWindOffset);
		CableComp.CableForce = ActorRightVector * (WindValue * WindMaxForce);

		if(bApplyWindInAllDirections)
		{
			WindValue = Math::PerlinNoise1D(Time::GetGameTimeSeconds() * 0.5 + 1000.0 + RandomWindOffset);
			CableComp.CableForce = ActorForwardVector * (WindValue * WindMaxForce);
		}
	}

	private void HandleVolatileParticleForces(float DeltaTime)
	{
		for(int i = VolatileParticleForces.Num() - 1; i >= 0; i--)
		{
			FTundra_River_InteractableBellRopeVolatileParticleForce& Force = VolatileParticleForces[i];

			ClearForceOnParticle(Force);
			ApplyDragOnVolatileForce(Force, DeltaTime);
			if(Force.ParticleForce.IsNearlyZero())
			{
				VolatileParticleForces.RemoveAt(i);
				continue;
			}
			ApplyForceOnParticle(Force);
		}
	}

	private void Internal_AddImpulseToParticle(int ParticleIndex, FVector Impulse, float Drag)
	{
		if(Impulse.IsNearlyZero())
			return;
		
		int Index = VolatileParticleForces.FindIndex(FTundra_River_InteractableBellRopeVolatileParticleForce(ParticleIndex));
		if(Index >= 0)
		{
			FTundra_River_InteractableBellRopeVolatileParticleForce& Force = VolatileParticleForces[Index];
			ClearForceOnParticle(Force);
			if(Drag > Force.ParticleDrag)
				Force.ParticleDrag = Drag;

			Force.ParticleForce += Impulse;
			ApplyForceOnParticle(Force);
		}
		else
		{
			auto Force = FTundra_River_InteractableBellRopeVolatileParticleForce(ParticleIndex, Impulse, Drag);
			VolatileParticleForces.Add(Force);
			ApplyForceOnParticle(Force);
		}
	}

	private void ApplyForceOnParticle(FTundra_River_InteractableBellRopeVolatileParticleForce Force)
	{
		CableComp.Particles[Force.ParticleIndex].Force += Force.ParticleForce;
	}

	private void ClearForceOnParticle(FTundra_River_InteractableBellRopeVolatileParticleForce Force)
	{
		CableComp.Particles[Force.ParticleIndex].Force -= Force.ParticleForce;
	}

	/* Takes in velocity and drag and delta time and returns the new velocity */
	void ApplyDragOnVolatileForce(FTundra_River_InteractableBellRopeVolatileParticleForce& Force, float DeltaTime)
	{
		Force.ParticleForce = Force.ParticleForce * Math::Pow(Force.ParticleDrag, DeltaTime);
	}
}