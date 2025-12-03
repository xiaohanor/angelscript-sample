class USkylineTorStormAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::StormAttack);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorStormAttackComponent StormAttackComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazeActor Target;
	private ASkylineTorCenterPoint CenterActor;
	private AHazeCharacter Character;
	int AttackIndex;

	float TelegraphDuration;
	float ActionDuration = 14;
	float RecoveryDuration;

	float AttackDuration;
	bool bRecoveryStarted;
	bool bAttackStarted;
	float TrailDelay = 1;

	int BeamSegments = 3;
	
	float DamageCooldown = 0.5;
	TPerPlayer<FSkylineTorStormAttackBehaviourTargetData> TargetData;

	float BeamSpeed = 975;

	UFUNCTION(BlueprintOverride)
	void Setup() 
	{
		Super::Setup();
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		StormAttackComp = USkylineTorStormAttackComponent::GetOrCreate(Owner);
		TorTargetingComp = USkylineTorTargetingComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		CenterActor = TListedActors<ASkylineTorCenterPoint>().Single;

		TelegraphDuration = AnimInstance.StormAttackTelegraph.Sequence.PlayLength;
		// ActionDuration = AnimInstance.StormAttackAttack.Sequence.PlayLength;
		RecoveryDuration = AnimInstance.StormAttackRecovery.Sequence.PlayLength;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			TargetData[Player].Beams.Add(FSkylineTorStormAttackBehaviourBeamData());
			TargetData[Player].Beams.Add(FSkylineTorStormAttackBehaviourBeamData());
			TargetData[Player].Beams.Add(FSkylineTorStormAttackBehaviourBeamData());
			TargetData[Player].TrailComp = UTargetTrailComponent::GetOrCreate(Player);
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			for(FSkylineTorStormAttackBehaviourBeamData BeamData : TargetData[Player].Beams)
				StormAttackComp.Beams.Add(FSkylineTorStormAttackBeam());
		}

		AttackIndex = TorBehaviourComp.GetNewAttackIndex(Outer.Name);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(AttackIndex != TorBehaviourComp.GetAttackIndex(Outer.Name))
			return false;
		if (HoldHammerComp.bDetached)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(AttackDuration > TelegraphDuration + ActionDuration + RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackDuration = 0;
		bRecoveryStarted = false;
		bAttackStarted = false;
		AnimComp.RequestFeature(FeatureTagSkylineTor::StormAttack, SubTagSkylineTorStormAttack::Telegraph, EBasicBehaviourPriority::Medium, this);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			FSkylineTorStormAttackBehaviourTargetData& PlayerData = TargetData[Player];
			PlayerData.CurrentLocation = CenterActor.ActorLocation;
			FVector TargetLocation;
			Pathfinding::FindNavmeshLocation(PlayerData.TrailComp.GetTrailLocation(TrailDelay), 500, 500, TargetLocation);
			PlayerData.OffsetRotation.SnapTo((TargetLocation - PlayerData.CurrentLocation).GetSafeNormal2D().ToOrientationQuat());
			PlayerData.Offset.SnapTo(0);
		}

		USkylineTorEventHandler::Trigger_OnStormAttackTelegraph(Owner, FSkylineTorEventHandlerOnStormAttackStartData(HoldHammerComp.Hammer, StormAttackComp));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);
		USkylineTorEventHandler::Trigger_OnStormAttackStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		TorBehaviourComp.IncrementAttackIndex(Outer.Name);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector PlayerMidLocation = (TorTargetingComp.MioLocation + TorTargetingComp.ZoeLocation) / 2;
		DestinationComp.RotateTowards(PlayerMidLocation);

		if(AttackDuration < SMALL_NUMBER && Owner.ActorLocation.Dist2D(CenterActor.ActorLocation) > 250)
		{
			DestinationComp.MoveTowardsIgnorePathfinding(CenterActor.ActorLocation, 1000);
			return;
		}

		AttackDuration += DeltaTime;

		if(AttackDuration > TelegraphDuration + ActionDuration)
		{
			if(!bRecoveryStarted)
			{
				bRecoveryStarted = true;
				USkylineTorEventHandler::Trigger_OnStormAttackStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
				AnimComp.RequestSubFeature(SubTagSkylineTorStormAttack::Recovery, this);
			}
			return;
		}

		if(AttackDuration < TelegraphDuration)
			return;

		if(!bAttackStarted)
		{
			bAttackStarted = true;
			USkylineTorEventHandler::Trigger_OnStormAttackStart(Owner, FSkylineTorEventHandlerOnStormAttackStartData(HoldHammerComp.Hammer, StormAttackComp));
			AnimComp.RequestSubFeature(SubTagSkylineTorStormAttack::Attack, this);
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			FSkylineTorStormAttackBehaviourTargetData& PlayerData = TargetData[Player];			
			FVector Dir = (Player.ActorLocation - PlayerData.CurrentLocation).GetSafeNormal();
			PlayerData.AccDirection.AccelerateTo(Dir, 4, DeltaTime);
			FVector Delta = PlayerData.AccDirection.Value * DeltaTime * BeamSpeed;
			PlayerData.CurrentLocation += Delta;
		}

		TArray<FVector> BeamEndLocations;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			FSkylineTorStormAttackBehaviourTargetData& PlayerData = TargetData[Player];
			float Distance = PlayerData.CurrentLocation.Dist2D(Player.ActorLocation);
			FVector ForwardVector = PlayerData.AccDirection.Value.GetSafeNormal2D().Rotation().ForwardVector;

			int Index = 0;
			for(FSkylineTorStormAttackBehaviourBeamData& Beam : PlayerData.Beams)
			{
				float BaseOffset = 600;
				float OffsetFactor = Math::Clamp(Distance / BaseOffset, 0, 1);
				float TargetOffset = BaseOffset * OffsetFactor;
				PlayerData.Offset.AccelerateTo(TargetOffset, 8, DeltaTime);
				float Offset = PlayerData.Offset.Value;

				float Angle = (360.0 / 3.0);
				Beam.AccOffset.AccelerateTo(ForwardVector.RotateAngleAxis((Angle / 2) + Index * Angle, FVector::UpVector) * Offset, 1, DeltaTime);
				FVector BeamLocation = PlayerData.CurrentLocation + Beam.AccOffset.Value;

				if(BeamLocation.Dist2D(CenterActor.ActorLocation) > CenterActor.ArenaRadius)
				{
					FVector Dir = (BeamLocation - CenterActor.ActorLocation).GetSafeNormal();
					BeamLocation = CenterActor.ActorLocation + Dir * CenterActor.ArenaRadius;
				}

				FVector NavLocation;
				if(Pathfinding::FindNavmeshLocation(BeamLocation, 100, 500, NavLocation))
					BeamEndLocations.Add(NavLocation);
				else
					BeamEndLocations.Add(BeamLocation);

				Index++;
			}
		}

		FVector BeamStartLocation = HoldHammerComp.Hammer.ActorCenterLocation;
		for(int i = 0; i < BeamEndLocations.Num(); i++)
		{
			FVector BeamEndLocation = BeamEndLocations[i];
			FSkylineTorStormAttackBeam& Beam = StormAttackComp.Beams[i];
			Beam.StartLocation = BeamStartLocation;
			Beam.EndLocation = BeamEndLocation;

			FVector Dir = (Beam.EndLocation - Beam.StartLocation).GetSafeNormal2D();
			float Distance = Beam.StartLocation.Distance(Beam.EndLocation);
			Beam.ControlPoint1 = Beam.StartLocation + Dir * (Distance/3);
			Beam.ControlPoint2 = Beam.EndLocation + FVector::UpVector * (Distance/3);
		}

		for(FSkylineTorStormAttackBeam Beam : StormAttackComp.Beams)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(TargetData[Player].DamageTime > SMALL_NUMBER && Time::GetGameTimeSince(TargetData[Player].DamageTime) < DamageCooldown)
					continue;

				bool bIsIntersecting = BezierCurve::IsIntersectingSphere_2CP(Beam.StartLocation, Beam.ControlPoint1, Beam.ControlPoint2, Beam.EndLocation, Player.ActorCenterLocation, Player.CapsuleComponent.BoundsRadius);
				if(bIsIntersecting)
				{
					Player.DamagePlayerHealth(0.5, DamageEffect = StormAttackComp.DamageEffect, DeathEffect = StormAttackComp.DeathEffect);
					TargetData[Player].DamageTime = Time::GameTimeSeconds;
				}
			}
		}
	}
}

struct FSkylineTorStormAttackBehaviourTargetData
{
	UTargetTrailComponent TrailComp;
	FVector CurrentLocation;
	FHazeAcceleratedVector AccDirection;
	FHazeAcceleratedQuat OffsetRotation;
	FHazeAcceleratedFloat Offset;
	TArray<FSkylineTorStormAttackBehaviourBeamData> Beams;
	float DamageTime;
}

struct FSkylineTorStormAttackBehaviourBeamData
{
	bool bActive;
	FHazeAcceleratedVector AccOffset;
}