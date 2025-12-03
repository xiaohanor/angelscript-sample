
class UIslandOverseerTremorAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerTremorComponent TremorComp;
	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	UAnimInstanceIslandOverseer AnimInstance;
	AHazeCharacter Character;

	float SpawnTime;
	int SpawnedCount;
	bool bSpawned;
	float AttackDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		TremorComp = UIslandOverseerTremorComponent::GetOrCreate(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::Tremor, NAME_None, Durations);
		Durations.Anticipation *= 0.5;
		Durations.Telegraph *= 0.5;
		Durations.Action *= 0.5;
		Durations.Recovery *= 0.5;
		AnimComp.RequestAction(FeatureTagIslandOverseer::Tremor, EBasicBehaviourPriority::Medium, this, Durations);
		SpawnedCount = 0;
		SpawnTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.TremorCooldown);
		TremorComp.AdditionalTremors++;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AttackDuration += DeltaTime;

		if(!bSpawned && Durations.IsInActionRange(AttackDuration))
		{
			FIslandOverseerEventHandlerOnTremorImpactData Data;
			Data.LeftHandImpactLocation = Character.Mesh.GetSocketLocation(n"LeftFingerBase");
			Data.LeftHandImpactLocation.Z = Character.ActorLocation.Z;
			Data.RightHandImpactLocation = Character.Mesh.GetSocketLocation(n"RightFingerBase");
			Data.RightHandImpactLocation.Z = Character.ActorLocation.Z;
			UIslandOverseerEventHandler::Trigger_OnTremorImpact(Owner, Data);
			bSpawned = true;
			FVector SpawnLocation = Owner.ActorLocation + Owner.ActorForwardVector * 500;
			AIslandOverseerTremor Tremor = SpawnActor(TremorComp.TremorClass, SpawnLocation + Owner.ActorUpVector * Settings.TremorDamageWidth / 2 + Owner.ActorForwardVector * 150, bDeferredSpawn = true, Level = Owner.Level);
			Tremor.Owner = Owner;
			FinishSpawningActor(Tremor);
			SpawnedCount++;
		}

		if(AttackDuration >= Durations.GetTotal())
		{
			AttackDuration = 0;
			bSpawned = false;
			if(SpawnedCount >= Settings.TremorAmount + TremorComp.AdditionalTremors)
				DeactivateBehaviour();
		}
	}
}