struct FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData
{
	UPROPERTY()
	FVector Location;
	UPROPERTY()
	float Scale;
}

class USkylineTorHammerSpiralMoveBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorHammerSpiralComponent SpiralComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorSettings Settings;

	private AHazeCharacter Character;
	private bool bCompleted;
	float MaxTime = 5.0;

	FVector CenterLocation;
	FVector LauncherLocation;
	FVector TargetLocation;
	FVector Direction;

	TArray<AHazeActor> HitTargets;
	float Distance;
	float Angle;

	FHazeAcceleratedFloat AccSpeed;
	float Speed = 200;
	float SpiralingSpeed = 750;

	bool bStartSpiraling;
	bool bReverse;

	FHazeRuntimeSpline TelegraphSpline;
	TArray<FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData> TelegraphLocations;

	FHazeAcceleratedVector AccMeshLocation;
	FHazeAcceleratedRotator AccMeshRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		SpiralComp = USkylineTorHammerSpiralComponent::GetOrCreate(Owner);
		TorTargetingComp = USkylineTorTargetingComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		HammerComp.OnChangedMode.AddUFunction(this, n"ChangedMode");
	}

	UFUNCTION()
	private void ChangedMode(ESkylineTorHammerMode NewMode, ESkylineTorHammerMode OldMode)
	{
		if(NewMode == ESkylineTorHammerMode::Spiral)
			bCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (bCompleted)
			return false;
		return true;
	}

	bool SetTelegraphLocations(TArray<FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData>& _TelegraphLocations)
	{
		float TelegraphSteps = 0.1;
		float TelegraphDistance = Distance;
		float TelegraphAngle = 0;
		bool bTelegraphSpiral = false;

		if(bReverse)
			TelegraphSteps *= -1;

		while(TelegraphDistance > 0)
		{
			TelegraphAngle -= TelegraphSteps * Speed;
			
			FVector TelegraphLocation = CenterLocation + Direction.RotateAngleAxis(TelegraphAngle, FVector::UpVector) * TelegraphDistance;

			if(!bTelegraphSpiral)
			{
				if(!bReverse && TelegraphAngle < -180)
					bTelegraphSpiral = true;
				if(bReverse && TelegraphAngle > 180)
					bTelegraphSpiral = true;
			}
			
			if(bTelegraphSpiral)
				TelegraphDistance -= TelegraphSteps * SpiralingSpeed;
			
			if(!Pathfinding::FindNavmeshLocation(TelegraphLocation, 100, 500, TelegraphLocation))
				continue;
			
			FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData Data;
			Data.Location = TelegraphLocation;
			_TelegraphLocations.Add(Data);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.AddActorCollisionBlock(this);
		HitTargets.Empty();

		bStartSpiraling = false;
		Angle = 0;
		AccSpeed.SnapTo(0);

		LauncherLocation = Owner.ActorLocation;
		if(!Pathfinding::FindNavmeshLocation(LauncherLocation, 100, 500, LauncherLocation) || LauncherLocation == FVector::ZeroVector)
			DeactivateBehaviour();

		TargetLocation = SpiralComp.TargetLocation;
		if(!Pathfinding::FindNavmeshLocation(TargetLocation, 100, 500, TargetLocation) || TargetLocation == FVector::ZeroVector)
			DeactivateBehaviour();

		CenterLocation = (LauncherLocation + TargetLocation) / 2;
		if(!Pathfinding::FindNavmeshLocation(CenterLocation, 100, 500, CenterLocation) || CenterLocation == FVector::ZeroVector)
			DeactivateBehaviour();

		Direction = (LauncherLocation - CenterLocation).GetSafeNormal2D();
		Distance = CenterLocation.Dist2D(LauncherLocation);

		bReverse = false;
		TelegraphLocations.Empty();
		if(!SetTelegraphLocations(TelegraphLocations))
		{
			bReverse = true;
			SetTelegraphLocations(TelegraphLocations);
		}

		TelegraphSpline = FHazeRuntimeSpline();
		TelegraphSpline.Looping = false;
		for(int i = 0; i < TelegraphLocations.Num(); i++)
		{
			TelegraphLocations[i].Scale = 1.5 - (float(i) / TelegraphLocations.Num());
			TelegraphSpline.AddPoint(TelegraphLocations[i].Location);
		}		

		FSkylineTorHammerOnSpiralTelegraphData Data;
		Data.TelegraphLocations = TelegraphLocations;
		Data.TelegraphSpline = TelegraphSpline;
		USkylineTorHammerEventHandler::Trigger_OnSpiralTelegraphStart(Owner, Data);

		Owner.BlockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.RemoveActorCollisionBlock(this);
		bCompleted = true;
		TargetComp.SetTarget(nullptr);
		VolleyComp.ImpactLocation = CenterLocation;

		Owner.ActorRotation = FRotator(0, 0, 0);
		PivotComp.SetPivot(Owner.ActorCenterLocation);
		PivotComp.Pivot.SetActorRotation(FRotator(180, 0, 0));

		Character.MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;
		Character.MeshOffsetComponent.RelativeRotation = FRotator::ZeroRotator;

		USkylineTorHammerEventHandler::Trigger_OnSpiralTelegraphStop(Owner);
		Owner.UnblockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		AccMeshLocation.AccelerateTo(FVector(0, 0, 113), 0.25, DeltaTime);
		AccMeshRotation.AccelerateTo(FRotator(0, AccMeshRotation.Value.Yaw - 60, 90), 0.25, DeltaTime);
		Character.MeshOffsetComponent.SetRelativeLocation(AccMeshLocation.Value);
		Character.MeshOffsetComponent.SetRelativeRotation(AccMeshRotation.Value);

		FSkylineTorHammerOnSpiralTelegraphData Data;
		Data.TelegraphLocations = TelegraphLocations;
		Data.TelegraphSpline = TelegraphSpline;
		USkylineTorHammerEventHandler::Trigger_OnSpiralTelegraphUpdate(Owner, Data);

		if(Distance <= 0)
		{
			FHitResult Hit;
			Hit.Location = TargetLocation;
			USkylineTorHammerEventHandler::Trigger_OnImpactLand(Owner, FSkylineTorHammerOnHitEventData(Hit));
			DeactivateBehaviour();
			return;
		}

		AccSpeed.AccelerateTo(Speed, 1.5, DeltaTime);

		if(bReverse)
			Angle += DeltaTime * AccSpeed.Value;
		else
			Angle -= DeltaTime * AccSpeed.Value;

		FVector MoveLocation = CenterLocation + Direction.RotateAngleAxis(Angle, FVector::UpVector) * Distance;

		if(!bStartSpiraling)
		{
			if(!bReverse && Angle < -180)
				bStartSpiraling = true;
			if(bReverse && Angle > 180)
				bStartSpiraling = true;
		}

		if(bStartSpiraling)
		{
			if(bReverse)
				Distance += DeltaTime * SpiralingSpeed;
			else
				Distance -= DeltaTime * SpiralingSpeed;
		}

		FVector NavMeshMove;
		if(Pathfinding::FindNavmeshLocation(MoveLocation, 0, 500, NavMeshMove))
			Owner.SetActorLocation(NavMeshMove);
		else
			Owner.SetActorLocation(MoveLocation);
		Owner.SetActorRotation(Owner.ActorVelocity.Rotation());

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(HitTargets.Contains(Player))
				continue;
			if(Player.ActorCenterLocation.Distance(Owner.ActorCenterLocation) > 250)
				continue;

			FHitResult Hit;
			Hit.Location = Player.ActorLocation;
			USkylineTorHammerEventHandler::Trigger_OnImpactHit(Owner, FSkylineTorHammerOnHitEventData(Hit));

			HitTargets.Add(Player);
			Player.DamagePlayerHealth(1, DamageEffect = HammerComp.DamageEffect, DeathEffect = HammerComp.DeathEffect);
			FStumble Stumble;
			FVector Dir = Owner.ActorRightVector + FVector(0, 0, 0.2);
			Stumble.Move = Dir * 500;
			Stumble.Duration = 0.25;
			Player.ApplyStumble(Stumble);
		}
	}

	void Impact(FHitResult Hit)
	{
		USkylineTorHammerEventHandler::Trigger_OnImpactLand(Owner, FSkylineTorHammerOnHitEventData(Hit));
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent)
	void OnLocalHitCharacter(FHitResult Hit) {}
}