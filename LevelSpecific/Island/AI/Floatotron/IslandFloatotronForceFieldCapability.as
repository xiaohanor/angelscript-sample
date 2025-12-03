
class UIslandFloatotronForceFieldCapability : UHazeCapability
{
	UIslandRedBlueImpactCounterResponseComponent ResponseComp;

	UIslandForceFieldComponent ForceFieldComp;
	UIslandRedBlueTargetableComponent TargetableComp;
	UHazeSkeletalMeshComponentBase CharacterMeshComp;
	UIslandFloatotronSettings Settings;	
	FVector LocalBreachLocation;

	float ImpactTiming = 0.25;
	float RedImpactTime;
	float BlueImpactTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ResponseComp = UIslandRedBlueImpactCounterResponseComponent::GetOrCreate(Owner);
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		ForceFieldComp = UIslandForceFieldComponent::GetOrCreate(Owner);		
		CharacterMeshComp = Cast<AHazeCharacter>(Owner).Mesh;
		Settings = UIslandFloatotronSettings::GetSettings(Owner);

		ForceFieldComp.InitializeVisuals(CharacterMeshComp);
		ForceFieldComp.AddComponentVisualsBlocker(this);
		
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");

		IslandForceField::ResetForceField(ForceFieldComp.CurrentType, TargetableComp, ResponseComp, this);
		ForceFieldComp.Reset();
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!IsActive())
			return;

		ForceFieldComp.Impact(Data.ImpactLocation);

		if(ForceFieldComp.CurrentType == EIslandForceFieldType::Both)
		{
			UIslandRedBlueWeaponUserComponent User = UIslandRedBlueWeaponUserComponent::Get(Data.Player);
			if(User.IsRedPlayer())
				RedImpactTime = Time::GetGameTimeSeconds();
			else
				BlueImpactTime = Time::GetGameTimeSeconds();

			if(RedImpactTime == 0)
				return;
			if(BlueImpactTime == 0)
				return;

			if(Math::Abs(RedImpactTime - BlueImpactTime) > ImpactTiming + (Network::PingRoundtripSeconds * 0.5) ) // more generous timing window on networked
				return;
		}

		ForceFieldComp.TakeDamage(Settings.ForceFieldDefaultDamage * Data.ImpactDamageMultiplier, Data.ImpactLocation, Instigator = Data.Player);
	}

	UFUNCTION()
	private void OnRespawn()
	{		
		IslandForceField::ResetForceField(ForceFieldComp.CurrentType, TargetableComp, ResponseComp, this);
		ForceFieldComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ForceFieldComp.IsDepleted())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ForceFieldComp.IsDepleted())
			return true	;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		ForceFieldComp.RemoveComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ForceFieldComp.TriggerBurstEffect();
		ForceFieldComp.AddComponentVisualsBlocker(this);
		if (TargetableComp != nullptr)
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
		
		ResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		ResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		ForceFieldComp.CopyPoseFromSkeletalComponent(CharacterMeshComp);

		ForceFieldComp.Replenish(Settings.ReplenishAmountPerSecond * DeltaTime);

		// Adjust force field material based on integrity
		ForceFieldComp.UpdateVisuals(DeltaTime);
		
	}
}