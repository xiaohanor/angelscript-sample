
struct FIslandOverseerShakeAttackBehaviourParams
{
	TArray<float> RandomOffsets;
}

class UIslandOverseerShakeAttackBehaviour : UBasicBehaviour
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
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerShakeAttackBehaviourParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(DoorComp.bDoorClosed)
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
	void OnActivated(FIslandOverseerShakeAttackBehaviourParams Params)
	{
		Super::OnActivated();
		SideOffsets = Params.RandomOffsets;
		SideOffsetIndex = 0;
		Timer = 0;
		SpawnTimer = 0;
		Waves = 0;
		SpawnAmount = 4;
		
		AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::DoorShake, SubTagIslandOverseerDoorShake::Default, Durations);
		AnimComp.RequestAction(FeatureTagIslandOverseer::DoorShake, SubTagIslandOverseerDoorShake::Default, EBasicBehaviourPriority::Medium, this, Durations);

		AIslandOverseerDoorSplineContainer Container = TListedActors<AIslandOverseerDoorSplineContainer>().GetSingle();
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		DoorSpline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		// TakeDamageComp.bBlockReactions = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer += DeltaTime;

		if(Durations.IsInTelegraphRange(Timer))
			return;

		if(Durations.IsInActionRange(Timer))
		{
			if(SpawnTimer == 0 || Time::GetGameTimeSince(SpawnTimer) > Durations.Action / SpawnAmount)
			{
				float UpOffset = 1200;
				float SideOffset = SideOffsets[SideOffsetIndex];
				SideOffsetIndex++;

				// First attack of this wave
				if(SpawnTimer == 0)
				{
					FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data;	
					UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackImpact(Owner, Data);
					UIslandOverseerEventHandler::Trigger_OnDoorShakeAttackFistImpact(Owner, Data);
				}

				FVector SpawnLocation;
				if(Target == 0 || Target == 2)
				{
					FVector BaseLocation = Math::ProjectPositionOnInfiniteLine(DoorSpline.WorldLocation, Owner.ActorRightVector, Owner.ActorLocation) + Owner.ActorUpVector * UpOffset;
					SpawnLocation = BaseLocation + Owner.ActorRightVector * SideOffset;	
				}
				else
				{
					AHazePlayerCharacter Player = Target == 1 ? Game::Mio : Game::Zoe;
					SpawnLocation = Math::ProjectPositionOnInfiniteLine(DoorSpline.WorldLocation, Owner.ActorRightVector, Player.ActorLocation) + Owner.ActorUpVector * UpOffset;
				}

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
		}
	}
}