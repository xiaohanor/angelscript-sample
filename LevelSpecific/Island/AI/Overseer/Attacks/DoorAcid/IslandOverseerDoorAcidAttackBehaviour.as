
class UIslandOverseerDoorAcidAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerFloodAttackComponent FloodAttackComp;
	UIslandOverseerDoorAcidComponent DoorAcidComp;
	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;

	float SpawnTime;
	int SpawnedCount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		FloodAttackComp = UIslandOverseerFloodAttackComponent::GetOrCreate(Owner);
		DoorAcidComp = UIslandOverseerDoorAcidComponent::GetOrCreate(Owner);
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
		AnimComp.RequestFeature(FeatureTagIslandOverseer::DoorAcid, EBasicBehaviourPriority::Medium, this);
		SpawnedCount = 0;
		SpawnTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.DoorAcidCooldown);
		FloodAttackComp.StopEffects();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 2.27)
			return;
		FloodAttackComp.StartEffects();
		FVector Offset = FloodAttackComp.WorldLocation;
		Offset.Z = Owner.ActorLocation.Z;
		FloodAttackComp.SetSplashOffset(Offset);

		if(ActiveDuration < 3.8)
			return;

		if(SpawnTime == 0 || Time::GetGameTimeSince(SpawnTime) > 2)
		{
			AIslandOverseerDoorAcid Acid = SpawnActor(DoorAcidComp.DoorAcidClass, Owner.ActorLocation + Owner.ActorUpVector * Settings.DoorAcidDamageWidth / 2 + Owner.ActorForwardVector * 150, bDeferredSpawn = true, Level = Owner.Level);
			Acid.Owner = Owner;
			FinishSpawningActor(Acid);
			SpawnTime = Time::GameTimeSeconds;

			SpawnedCount++;
			if(SpawnedCount >= Settings.DoorAcidAmount)
				DeactivateBehaviour();
		}
	}
}