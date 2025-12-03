class USummitKnightFlailSmashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightFlailComponent Flail;
	USummitKnightSceptreComponent Sceptre;
	UHazeSkeletalMeshComponentBase Mesh;
	USummitKnightFlailBombLauncher BombLauncher;
	USummitKnightAnimationComponent KnightAnimComp;
	
	FBasicAIAnimationActionDurations Durations;

	float DefaultScale;
	FHazeAcceleratedFloat AccScale;
	
	ASummitKnightFlailBomb Bomb;
	AHazePlayerCharacter TrackedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Flail = USummitKnightFlailComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Flail.Initialize();
		Flail.Unequip();
		DefaultScale = Flail.WorldScale.X;
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		BombLauncher = USummitKnightFlailBombLauncher::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		UBasicAIProjectileComponent Proj = BombLauncher.Launch(FVector::ZeroVector);
		Bomb = Cast<ASummitKnightFlailBomb>(Proj.Owner);
		Bomb.Spawn(Flail);

		Flail.DetachFromParent();
		Flail.Equip();
		AccScale.SnapTo(DefaultScale * 0.1);
		Flail.WorldScale3D = FVector(AccScale.Value);
		Flail.SetWorldLocation(Sceptre.WorldLocation);
		Flail.Chain.EndLocation = Owner.ActorTransform.InverseTransformPosition(Sceptre.WorldLocation);

		Durations.Telegraph = Settings.FlailSmashTelegraphDuration;
		Durations.Anticipation = Settings.FlailSmashAnticipationDuration;
		Durations.Action = Settings.FlailSmashActionDuration;
		Durations.Recovery = Settings.FlailSmashRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SingleSlash, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SingleSlash, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Flail.Unequip();	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLoc = TrackedPlayer.ActorLocation;
		if (Game::Mio.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, 5000.0))
			TargetLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		if (ActiveDuration < Durations.Telegraph)
			DestinationComp.RotateTowards(TargetLoc);	

		AccScale.AccelerateTo(DefaultScale, Durations.Telegraph, DeltaTime);
		Flail.WorldScale3D = FVector(AccScale.Value);

		Flail.Chain.EndLocation = Owner.ActorTransform.InverseTransformPosition(Sceptre.WorldLocation);
		Flail.WorldLocation = Mesh.GetSocketLocation(n"Align");

		if (Durations.IsInActionRange(ActiveDuration))
		{
			// Deal damage to any nearby player
		}
		if (!Bomb.bPrimed && Durations.IsInRecoveryRange(ActiveDuration))
		{
			// Release bomb and start countdown
			Bomb.Prime();
		}
	}
}

