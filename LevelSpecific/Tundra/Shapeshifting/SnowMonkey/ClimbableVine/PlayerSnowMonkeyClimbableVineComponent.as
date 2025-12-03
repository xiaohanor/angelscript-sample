class UTundraPlayerSnowMonkeyClimbableVineComponent : UActorComponent
{
	ATundraPlayerSnowMonkeyClimbableVine CurrentVine = nullptr;
	int MonkeyAttachParticleIndex1 = -1;
	int MonkeyAttachParticleIndex2 = -1;
	float MonkeyAttachParticleAlpha = -1.0;
	float TimeOfDetachFromVine = -100.0;
	TArray<int> FixedParticles;
	TArray<int> GravityParticles;
	TArray<FVector> GravityParticlePreviousForce;
	UTundraPlayerSnowMonkeyClimbableVineSettings Settings;
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Settings = UTundraPlayerSnowMonkeyClimbableVineSettings::GetSettings(PlayerOwner);
	}

	void SetGravityForceOnParticles(FVector GravityOriginLocation, float GravityForce)
	{
		ResetGravityForceOnParticles();

		for(int i = 0; i < CurrentVine.CableComp.Particles.Num(); i++)
		{
			FCableParticle& Particle = CurrentVine.CableComp.Particles[i];

			float Dist = Particle.Position.Distance(GravityOriginLocation);
			if(Dist > Settings.GravityForceRadius)
				continue;

			float GravityAlpha = 1.0 - (Dist / Settings.GravityForceRadius);
			GravityParticlePreviousForce.Add(Particle.Force);
			Particle.Force += FVector::DownVector * (GravityForce * GravityAlpha);
			GravityParticles.Add(i);
		}
	}

	void ResetGravityForceOnParticles()
	{
		if(GravityParticles.Num() == 0)
			return;

		for(int i = 0; i < GravityParticles.Num(); i++)
		{
			FCableParticle& Particle = CurrentVine.CableComp.Particles[GravityParticles[i]];
			Particle.Force = GravityParticlePreviousForce[i];
		}
		GravityParticles.Reset();
		GravityParticlePreviousForce.Reset();
	}

	void SetFixedParticleClamped(int ParticleIndex)
	{
		int Index = Math::Clamp(ParticleIndex, 0, CurrentVine.CableComp.Particles.Num() - 1);
		SetFixedParticle(Index);
	}

	void SetFixedParticle(int ParticleIndex)
	{
		if(FixedParticles.AddUnique(ParticleIndex))
			CurrentVine.CableComp.SetParticleFree(ParticleIndex, false);
	}

	void ResetFixedParticles()
	{
		for(int i = 0; i < FixedParticles.Num(); i++)
		{
			int CurrentIndex = FixedParticles[i];
			CurrentVine.CableComp.SetParticleFree(CurrentIndex, true);
		}

		FixedParticles.Reset();
	}

	void SetPositionOfFixedParticle(int FixedParticlesArrayIndex, FVector Location)
	{
		int ParticleIndex = FixedParticles[FixedParticlesArrayIndex];
		CurrentVine.CableComp.SetParticlePosition(ParticleIndex, Location);
	}
}