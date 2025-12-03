
class UIslandOverseerDoorHoldBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UAnimInstanceIslandOverseer AnimInstance;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;
	UIslandOverseerDoorComponent DoorComp;
	UBasicAIHealthComponent HealthComp;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerTakeDamageComponent DamageComp;

	bool bReclosed;
	float DefeatedDuration;
	float DefeatedTime;
	bool bOpenTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Overseer.Mesh.AnimInstance);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		DamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(Owner);

		auto Response = UIslandRedBlueImpactResponseComponent::Get(Owner);
		Response.OnImpactEvent.AddUFunction(this, n"Impact");

		DefeatedDuration = AnimInstance.DoorCutHeadDefeated.Sequence.PlayLength;
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		if(!IsActive())
			return;
		UIslandOverseerEventHandler::Trigger_OnRecloseTakeDamage(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bReclosed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(DefeatedTime > 0 && Time::GetGameTimeSince(DefeatedTime) > DefeatedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		VisorComp.bDisabled = true;
		bReclosed = true;
		DoorComp.CutHeadState = EIslandOverseerCutHeadState::Decapitate;
		Overseer.HeadPlayerCollision.CollisionProfileName = CollisionProfile::NoCollision;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bReclosed)
		{
			if(!bOpenTargets && DefeatedTime > SMALL_NUMBER && Time::GetGameTimeSince(DefeatedTime) > DefeatedDuration / 2)
			{
				bOpenTargets = true;
				DoorComp.EnableDoorTargets();
			}
			return;
		}

		if(!HealthComp.IsDead())
			return;

		bReclosed = true;
		Owner.BlockCapabilities(n"Attack", this);
		VisorComp.Close();
		Overseer.OnDoorDefeated.Broadcast();
		DoorComp.CutHeadState = EIslandOverseerCutHeadState::Defeated;
		DefeatedTime = Time::GameTimeSeconds;
		Overseer.HeadPlayerCollision.CollisionProfileName = CollisionProfile::BlockOnlyPlayerCharacter;
	}
}