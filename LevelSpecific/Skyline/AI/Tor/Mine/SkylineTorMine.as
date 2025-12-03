class ASkylineTorMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorMineMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Drag;
	default WhipResponseComp.bAllowMultiGrab = false;
	default WhipResponseComp.OffsetDistance = 750;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutline;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USkylineTorMineComponent MineComp;

	ASkylineTorHammer Hammer;
	TArray<AHazeActor> Targets;
	float ExpirationTime = 3.0;
	AActor CenterActor;
	bool bDeployed;

	AHazeActor Grabber;
	UCameraPointOfInterestClamped POI;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"Grabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"Released");

		Hammer = TListedActors<ASkylineTorHammer>().GetSingle();
		Targets.Add(Hammer);
		Targets.Add(Game::Mio);
		Targets.Add(Game::Zoe);

		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
	}

	UFUNCTION()
	private void GravityBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		FHitResult HitResult(HitData.Actor, HitData.Component, HitData.ImpactPoint, HitData.ImpactNormal);
		Explode(HitResult);
	}

	UFUNCTION()
	private void OnReset()
	{
		MineComp.bGrabbed = false;
		bDeployed = false;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bDeployed)
			return;

		if(ActorVelocity.Size() > 100)
			MeshOffsetComp.AddLocalRotation(FRotator(100, 100, 0) * DeltaTime);

		TArray<AHazeActor> HitActors;
		for(AHazeActor Target : Targets)
		{
			float Radius = Collision.CapsuleRadius;
			if(Target == Hammer)
				Radius += 50;
			if(Target.ActorCenterLocation.Distance(ActorCenterLocation) > Radius)
				continue;

			HitActors.Add(Target);

			USkylineTorMineResponseComponent MineResponse = USkylineTorMineResponseComponent::Get(Target);
			if(MineResponse != nullptr)
				MineResponse.OnHit.Broadcast(this);

			UBasicAIHealthComponent AIHealthComp = UBasicAIHealthComponent::Get(Target);
			if(AIHealthComp != nullptr)
				AIHealthComp.TakeDamage(0.25, EDamageType::Default, this);

			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Target);
			if(PlayerHealthComp != nullptr)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);
				FStumble Stumble;
				FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) + FVector::UpVector * 0.3;
				Stumble.Move = Dir * 500;
				Stumble.Duration = 0.5;
				Player.ApplyStumble(Stumble);

				PlayerHealthComp.DamagePlayer(1, nullptr, nullptr);
			}
		}

		if(HitActors.Num() > 0)
			Explode(FHitResult());

		if(ActorLocation.Z < CenterActor.ActorLocation.Z - 200)
			Explode(FHitResult());

		if(MineComp.bGrabbed)
		{
			FVector TargetLocation = WhipResponseComp.DesiredLocation;
			float Dot = (TargetLocation - MineComp.Grabber.ActorLocation).GetSafeNormal2D().DotProduct((Hammer.ActorLocation - MineComp.Grabber.ActorLocation).GetSafeNormal2D());
			if(Dot > 0.95 && Hammer.ActorLocation.IsWithinDist2D(TargetLocation, 1000)) //&& TargetLocation.Dist2D(Hammer.ActorLocation) < ActorLocation.Dist2D(Hammer.ActorLocation))
				TargetLocation = Hammer.ActorLocation;						
			MineComp.MoveTowards(TargetLocation, 10);
		}
		else
			MineComp.bHasTargetLocation = false;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	void Explode(FHitResult Hit)
	{
		FSkylineTorMineOnImpactHitEventData Data;
		Data.HitResult = Hit;
		USkylineTorMineEventHandler::Trigger_OnImpactHit(this, Data);
		if(MineComp.Grabber != nullptr)
			UCameraSettings::GetSettings(Cast<AHazePlayerCharacter>(MineComp.Grabber)).IdealDistance.Clear(this);
		if(POI != nullptr)
			POI.Clear();
		AddActorDisable(this);
	}

	UFUNCTION()
	private void Released(UGravityWhipUserComponent UserComponent,
	                      UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		MineComp.bGrabbed = false;
		if(MineComp.Grabber != nullptr)
			UCameraSettings::GetSettings(Cast<AHazePlayerCharacter>(MineComp.Grabber)).IdealDistance.Clear(this);
		if(POI != nullptr)
			POI.Clear();
	}

	UFUNCTION()
	private void Grabbed(UGravityWhipUserComponent UserComponent,
	                     UGravityWhipTargetComponent TargetComponent,
	                     TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		MineComp.bGrabbed = true;
		MineComp.Grabber = Cast<AHazeActor>(UserComponent.Owner);
		UCameraSettings::GetSettings(Cast<AHazePlayerCharacter>(MineComp.Grabber)).IdealDistance.ApplyAsAdditive(500, this, 0.5);

		if(POI != nullptr)
			POI.Clear();
		POI = Cast<AHazePlayerCharacter>(MineComp.Grabber).CreatePointOfInterestClamped();
		POI.Clamps = FHazeCameraClampSettings(20, 20, 20, 5);
		POI.FocusTarget.SetFocusToActor(this);
		POI.Settings.TurnTime = 0.75;
		POI.Apply(this, 1.5, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Mesh.WorldLocation;
	}
}