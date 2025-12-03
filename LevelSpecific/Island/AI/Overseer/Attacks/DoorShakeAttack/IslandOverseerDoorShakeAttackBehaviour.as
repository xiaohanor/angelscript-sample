
struct FIslandOverseerDoorShakeAttackBehaviourParams
{
	TArray<float> RandomOffsets;
}

class UIslandOverseerDoorShakeAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Attack");

	UBasicAIHealthComponent HealthComp;
	UIslandOverseerDoorComponent DoorComp;
	UIslandOverseerDoorShakeComponent DoorShakeComp;
	UIslandOverseerTakeDamageComponent TakeDamageComp;
	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	UAnimInstanceIslandOverseer AnimInstance;
	AHazeCharacter Character;
	TArray<AIslandOverseerDoorShakeSpike> Spikes;

	UHazeSplineComponent DoorSpline;

	int Pattern;
	float SpawnTimer;
	float Timer;
	int SpawnAmount;
	int Target;
	int Waves = 0;
	int MaxWaves = 3;
	bool bTelegraphing;
	bool bAttacked;
	int DebrisId;

	int SideOffsetIndex;
	TArray<float> SideOffsets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		DoorComp = UIslandOverseerDoorComponent::GetOrCreate(Owner);
		DoorShakeComp = UIslandOverseerDoorShakeComponent::GetOrCreate(Owner);
		TakeDamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		Spikes = TListedActors<AIslandOverseerDoorShakeSpike>().GetArray();
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);

		AIslandOverseerDoorSplineContainer Container = TListedActors<AIslandOverseerDoorSplineContainer>().GetSingle();
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		DoorSpline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerDoorShakeAttackBehaviourParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DoorComp.bDoorClosed)
			return false;
		for(int i = 0; i < 30; i++)
			Params.RandomOffsets.Add(Math::RandRange(-750, 750));
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Timer >= Durations.GetTotal() && Waves >= MaxWaves)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverseerDoorShakeAttackBehaviourParams Params)
	{
		Super::OnActivated();
		SideOffsets = Params.RandomOffsets;
		SideOffsetIndex = 0;

		Timer = 0;
		SpawnTimer = 0;
		Waves = 0;
		SpawnAmount = 6;
		DoorComp.bDoorAttack = true;
		
		Durations.Telegraph = 2.5;
		AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::DoorShake, SubTagIslandOverseerDoorShake::Doors, Durations);
		AnimComp.RequestAction(FeatureTagIslandOverseer::DoorShake, SubTagIslandOverseerDoorShake::Doors, EBasicBehaviourPriority::Medium, this, Durations);

		UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackTelegraphStart(Owner);
		bTelegraphing = true;
		bAttacked = false;

		// TakeDamageComp.bBlockReactions = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DoorComp.bDoorAttack = false;
		Cooldown.Set(2);
		UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackTelegraphStop(Owner);
		// TakeDamageComp.bBlockReactions = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer += DeltaTime;

		if(Durations.IsInTelegraphRange(Timer))
			return;

		if(bTelegraphing)
		{
			bTelegraphing = false;
			UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackTelegraphStop(Owner);
		}

		if(Durations.IsInActionRange(Timer))
		{
			if(!bAttacked)
			{
				bAttacked = true;
				FVector AttackLocation = Math::ProjectPositionOnInfiniteLine(Game::Mio.ActorLocation, Owner.ActorRightVector, Owner.ActorLocation);
				RangeHit(AttackLocation);
				FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data;
				Data.AttackLocation = AttackLocation;
				UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackImpact(Owner, Data);
				UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackHeadImpact(Owner, Data);
			}

			if(SpawnTimer == 0 || Time::GetGameTimeSince(SpawnTimer) > Durations.Action / SpawnAmount)
			{
				float UpOffset = 1200;
				float SideOffset = SideOffsets[SideOffsetIndex];

				FVector SpawnLocation;
				if(Target == 0 || Target == 2)
				{
					FVector BaseLocation = Math::ProjectPositionOnInfiniteLine(Game::Mio.ActorLocation, Owner.ActorRightVector, Owner.ActorLocation) + Owner.ActorUpVector * UpOffset;
					SpawnLocation = BaseLocation + Owner.ActorRightVector * SideOffset;	
				}
				else
				{
					AHazePlayerCharacter Player = Target == 1 ? Game::Mio : Game::Zoe;
					SpawnLocation = Player.ActorLocation + Owner.ActorUpVector * UpOffset;
				}

				// Don't allow the debris to fall above the boss head
				FVector Direction = Owner.ActorRightVector;
				bool bRight = Owner.ActorRightVector.DotProduct(SpawnLocation - Owner.ActorLocation) > 0;
				if(!bRight)
					Direction = -Direction;

				FVector Start = DoorSpline.GetClosestSplineWorldLocationToWorldLocation(Owner.ActorLocation + Direction * 200);
				FVector End = DoorSpline.GetClosestSplineWorldLocationToWorldLocation(Owner.ActorLocation + Direction * 10000);
				End -= Direction * 200;
				float OutFraction;
				Math::ProjectPositionOnLineSegment(Start, End, SpawnLocation, SpawnLocation, OutFraction);
				SpawnLocation += Owner.ActorUpVector * UpOffset;

				// Spawn debris
				SpawnTimer = Time::GetGameTimeSeconds();
				AIslandOverseerDoorShakeDebris DebrisActor = SpawnActor(DoorShakeComp.DebrisClass, SpawnLocation, Level = Owner.Level);
				DebrisActor.MakeNetworked(this, DebrisId);
				DebrisActor.Overseer = Cast<AAIIslandOverseer>(Owner);
				DebrisId++;
				
				UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackSpawn(Owner);

				Target++;
				if(Target >= 4)
					Target = 0;
			}
		}

		if(Timer >= Durations.GetTotal())
		{
			Timer = 0;
			SpawnTimer = 0;

			Waves++;
			if(Waves >= MaxWaves)
				DeactivateBehaviour();
			else
			{
				UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackTelegraphStart(Owner);
				bTelegraphing = true;
				bAttacked = false;
			}
		}
	}	

	void RangeHit(FVector Location)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.ActorLocation.Distance(Location) > 150)
				continue;
			
			Player.DealTypedDamage(Owner, 0.5, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
		}			
	}
}