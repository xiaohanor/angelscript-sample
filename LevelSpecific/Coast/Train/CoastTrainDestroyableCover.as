class ACoastTrainDestroyableCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent ResponseComp;

	float HitTime;
	float HitDelay;

	float DirZ;
	float DirSideFactor;
	float Speed;
	FRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnBulletHit.AddUFunction(this, n"OnBulletHit");
		JoinTeam(n"CoastTrainDestroyableCoverTeam");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(n"CoastTrainDestroyableCoverTeam");
	}

	UFUNCTION()
	private void OnBulletHit(FCoastShoulderTurretBulletHitParams Params)
	{
		if(HitTime > 0)
			return;
		if (Params.PlayerInstigator.HasControl())
			CrumbExplode();
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode()
	{
		// Only explode once (in case hit by both players in network before crumb got through from other side)
		if (HitTime == 0)
			Explode(0.0);
	}

	void Explode(float InHitDelay)
	{
		HitDelay = InHitDelay;
		LeaveTeam(n"CoastTrainDestroyableCoverTeam");
		OnExploded();

		HitTime = Time::GameTimeSeconds;
		DirZ = Math::RandRange(0.4, 0.6);
		DirSideFactor = Math::RandRange(0.4, 0.6);
		Speed = Math::RandRange(3800,4200);
		Rotation = FRotator(Math::RandRange(450, 550), Math::RandRange(450, 550), 0);

		UAutoAimTargetComponent AutoAim = UAutoAimTargetComponent::Get(this);
		if(AutoAim != nullptr)
			AutoAim.bIsAutoAimEnabled = false;

		auto AITeam = HazeTeam::GetTeam(n"BasicAITeam");
		for(AHazeActor Member: AITeam.GetMembers())
		{
			if(Member.GetDistanceTo(this) < 300)
			{
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Member);
				HealthComp.TakeDamage(1000, EDamageType::Default, this);
			}
		}

		float MemberHitDelay = 0.0;
		UHazeTeam CoverTeam = HazeTeam::GetTeam(n"CoastTrainDestroyableCoverTeam");
		TArray<AHazeActor> CoverMembers = CoverTeam.GetMembers();
		for(AHazeActor Member: CoverMembers)
		{
			if(Member.GetDistanceTo(this) < 200 && Math::Abs(Member.ActorLocation.Z - ActorLocation.Z) > 50)
			{
				MemberHitDelay += 0.075;
				ACoastTrainDestroyableCover Cover = Cast<ACoastTrainDestroyableCover>(Member);
				Cover.Explode(MemberHitDelay);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnExploded(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HitTime == 0)
			return;

		if(HitDelay > 0)
		{
			HitDelay -= DeltaSeconds;
			HitTime = Time::GameTimeSeconds;
			return;
		}

		FVector Right = AttachParentActor.ActorRightVector * DirSideFactor;
		float Dot = AttachParentActor.ActorRightVector.DotProduct(ActorLocation - AttachParentActor.ActorLocation);
		if(Dot < 0)
			Right *= -1;
		FVector Dir = (Right + (AttachParentActor.ActorForwardVector * -1)).GetSafeNormal();
		DirZ -= DeltaSeconds * 0.75;
		Dir.Z = DirZ;

		FHitResult Dummy;
		AddActorWorldOffset(Dir * Speed * DeltaSeconds, false, Dummy, false);
		AddActorLocalRotation(Rotation * DeltaSeconds);

		if(Time::GetGameTimeSince(HitTime) > 3)
			DestroyActor();
	}
}