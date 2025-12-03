class UTundraPlayerSnowMonkeyClimbableVineEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerSnowMonkeyClimbableVineComponent VineComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerSnowMonkeyClimbableVineSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		VineComp = UTundraPlayerSnowMonkeyClimbableVineComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerSnowMonkeyClimbableVineSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraSnowMonkeyClimbableVineEnterActivatedParams& Params) const
	{
		if(MoveComp.HasGroundContact())
			return false;

		if(VineComp.CurrentVine != nullptr)
			return false;

		if(Time::GetGameTimeSince(VineComp.TimeOfDetachFromVine) < Settings.ClimbableVineCooldown)
			return false;

		TListedActors<ATundraPlayerSnowMonkeyClimbableVine> ListedVines;
		for(ATundraPlayerSnowMonkeyClimbableVine Vine : ListedVines.Array)
		{
			// If vine is out of range (so the disable comp has disabled it) we don't want to check against it.
			if(Vine.IsActorDisabled())
				continue;

			for(int i = 0; i < Vine.CableComp.Particles.Num() - 1; i++)
			{
				FCableParticle Particle1 = Vine.CableComp.Particles[i];
				FCableParticle Particle2 = Vine.CableComp.Particles[i + 1];

				FVector ClosestPoint = Math::ClosestPointOnLine(Particle1.Position, Particle2.Position, Player.ActorCenterLocation);

				FVector PlayerToClosestPoint = (ClosestPoint - Player.ActorCenterLocation).VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
				float Dot = PlayerToClosestPoint.DotProduct(MoveComp.PreviousHorizontalVelocity.GetSafeNormal());

				// If we aren't heading towards the closest point we ignore this vine
				if(Dot < -0.25)
					continue;

				float SqrDist = ClosestPoint.DistSquared(Player.ActorCenterLocation);
				if(SqrDist < Math::Square(Settings.DistanceToEnterVine))
				{
					Params.Vine = Vine;
					Params.ParticleIndex1 = i;
					Params.ParticleIndex2 = i + 1;

					FVector Part1ToPart2 = (Particle2.Position - Particle1.Position);
					FVector Part1ToPart2Dir = Part1ToPart2.GetSafeNormal();
					FVector Part1ToClosestPoint = (ClosestPoint - Particle1.Position);
					float Part1ToPart2Dist = Part1ToPart2Dir.DotProduct(Part1ToPart2);
					float Part1ToClosestPointDist = Part1ToPart2Dir.DotProduct(Part1ToClosestPoint);

					Params.AttachPositionAlpha = (Part1ToClosestPointDist / Part1ToPart2Dist);

					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraSnowMonkeyClimbableVineEnterActivatedParams Params)
	{
		VineComp.CurrentVine = Params.Vine;
		VineComp.MonkeyAttachParticleIndex1 = Params.ParticleIndex1;
		VineComp.MonkeyAttachParticleIndex2 = Params.ParticleIndex2;
		VineComp.MonkeyAttachParticleAlpha = Params.AttachPositionAlpha;
		FVector ParticlePos1 = Params.Vine.CableComp.Particles[Params.ParticleIndex1].Position;
		FVector ParticlePos2 = Params.Vine.CableComp.Particles[Params.ParticleIndex2].Position;

		Player.ActorLocation = Math::Lerp(ParticlePos1, ParticlePos2, Params.AttachPositionAlpha) - Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;

		//Debug::DrawDebugSphere(Player.ActorCenterLocation, Settings.MonkeyAttachImpulseRadius, 12, FLinearColor::Red, 3.0, 5.0);

		FVector Impulse = MoveComp.PreviousHorizontalVelocity * Settings.MonkeyAttachImpulseHorizontalMultiplier + MoveComp.PreviousVerticalVelocity * Settings.MonkeyAttachImpulseVerticalMultiplier;
		for(int i = 0; i < VineComp.CurrentVine.CableComp.Particles.Num(); i++)
		{
			FCableParticle Particle = VineComp.CurrentVine.CableComp.Particles[i];
			FVector PlayerLocation = Player.ActorCenterLocation;

			float Dist = Particle.Position.Distance(PlayerLocation);
			if(Dist > Settings.MonkeyAttachImpulseRadius)
				continue;

			float ImpulseAlpha = 1.0 - (Dist / Settings.MonkeyAttachImpulseRadius);
			VineComp.CurrentVine.CableComp.SetParticleVelocity(i, Impulse * ImpulseAlpha);
		}
	}
}

struct FTundraSnowMonkeyClimbableVineEnterActivatedParams
{
	ATundraPlayerSnowMonkeyClimbableVine Vine;
	int ParticleIndex1;
	int ParticleIndex2;
	float AttachPositionAlpha;
}