
class USanctuaryBabyWormGrabbedBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AAISanctuaryBabyWorm BabyWorm;
	USanctuaryBabyWormSettings Settings;

	TArray<FCentipedeBiteEventParams> Grabbers;
	FVector OriginalScale;
	FVector OriginalLocation;
	float WiggleRotationTimer;
	float WiggleRotationMax = 25;
	float GrabbedSingleTimer = 0;
	UBasicAIHealthComponent HealthComp;
	
	float TearDistance = 750;
	float GrabbedPlayerMoveSpeed = 500;
	float GrabbedPlayerMaxSpeedSlowdown = 300;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BabyWorm = Cast<AAISanctuaryBabyWorm>(Owner);
		Settings = USanctuaryBabyWormSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		HealthComp.OnDie.AddUFunction(this, n"OnDied");

		OriginalScale = BabyWorm.Mesh.RelativeScale3D;
		OriginalLocation = BabyWorm.Mesh.RelativeLocation;

		BabyWorm.Bite1Comp.OnCentipedeBiteStarted.AddUFunction(this, n"Bite1Started");
		BabyWorm.Bite2Comp.OnCentipedeBiteStarted.AddUFunction(this, n"Bite2Started");
	}

	UFUNCTION()
	private void OnDied(AHazeActor ActorBeingKilled)
	{
		USanctuaryBabyWormEffectHandler::Trigger_OnTornApart(Owner);
	}

	UFUNCTION()
	private void Bite1Started(FCentipedeBiteEventParams BiteParams)
	{		
		if(Grabbers.Contains(BiteParams))
		{
			Grabbers.Remove(BiteParams);
			Reset();
			return;
		}
		
		Grabbers.Add(BiteParams);
	}

	UFUNCTION()
	private void Bite2Started(FCentipedeBiteEventParams BiteParams)
	{
		if(Grabbers.Contains(BiteParams))
		{
			Grabbers.Remove(BiteParams);
			Reset();
			return;
		}

		Grabbers.Add(BiteParams);
	}

	private void Reset()
	{
		BabyWorm.Mesh.SetRelativeScale3D(OriginalScale);
		BabyWorm.Mesh.SetRelativeLocation(OriginalLocation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(Grabbers.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(Grabbers.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GrabbedSingleTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		BabyWorm.Mesh.SetRelativeScale3D(OriginalScale);
		BabyWorm.Mesh.SetRelativeLocation(OriginalLocation);
		Grabbers.Empty();
		Game::Zoe.ClearSettingsByInstigator(this);
		Game::Mio.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(FCentipedeBiteEventParams Grabber: Grabbers)
		{	
			float Speed = GrabbedPlayerMoveSpeed;
			if(Grabbers.Num() > 1)
			{
				float Factor = Grabbers[0].Player.ActorLocation.Distance(Grabbers[1].Player.ActorLocation) / TearDistance;
				float Slowdown = 300 * Factor;
				Speed = GrabbedPlayerMoveSpeed - Slowdown;
			}
			UCentipedeMovementSettings::SetMoveSpeed(Grabber.Player, Speed, this);
		}

		float Distance = -300;

		FVector Grabber1Loc = Grabbers[0].Player.ActorLocation + Grabbers[0].Player.ActorForwardVector * 100;
		FVector MidLocation = Grabber1Loc;

		WiggleRotationTimer += DeltaTime * 10;
		float Rotation = Math::Sin(WiggleRotationTimer) * WiggleRotationMax;
		FVector Dir = Grabbers[0].Player.ActorForwardVector.RotateAngleAxis(Rotation, FVector::UpVector);

		if(Grabbers.Num() > 1)
		{
			FVector Grabber2Loc = Grabbers[1].Player.ActorLocation + Grabbers[1].Player.ActorForwardVector * 100;

			Distance = Grabber1Loc.Distance(Grabber2Loc);
			MidLocation = (Grabber1Loc + Grabber2Loc) / 2;
			Dir = (Grabber1Loc - Grabber2Loc);

			FVector Scale = OriginalScale + FVector(0, 0, Distance  / 2000);
			BabyWorm.Mesh.SetRelativeScale3D(Scale);

			GrabbedSingleTimer = 0;
		}
		else
		{
			GrabbedSingleTimer += DeltaTime;
		}

		Owner.SetActorRotation(Dir.Rotation());
		Owner.SetActorLocation(MidLocation);
		FVector Location = OriginalLocation - (FVector(Distance, 0, 0) * 0.35); 
		BabyWorm.Mesh.SetRelativeLocation(Location);

		if(Distance > TearDistance)
		{
			HealthComp.TakeDamage(1000, EDamageType::Default, Owner);
			DeactivateBehaviour();
		}

		if(GrabbedSingleTimer > Settings.GrabbedSingleDuration)
			DeactivateBehaviour();
	}
}