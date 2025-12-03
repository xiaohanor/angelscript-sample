
class UIslandFakePunchotronForceFieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterPhysics;

	UIslandForceFieldComponent ForceFieldComp;
	UHazeSkeletalMeshComponentBase CharacterMeshComp;

	UIslandRedBlueReflectComponent BulletReflectComp;

	default CapabilityTags.Add(n"IslandForceField");
	
	float RedImpactTime;
	float BlueImpactTime;

	float RespawnCooldownTimer;

	AIslandFakePunchotron FakePunchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		FakePunchotron = Cast<AIslandFakePunchotron>(Owner);

		CharacterMeshComp = FakePunchotron.SkelMesh;		
		ForceFieldComp.InitializeVisuals(CharacterMeshComp);
		ForceFieldComp.AddComponentVisualsBlocker(this);

		BulletReflectComp = UIslandRedBlueReflectComponent::GetOrCreate(Owner);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets until a shield activates.

		ForceFieldComp.SetLeaderPoseComponent(CharacterMeshComp);

		ForceFieldComp.Reset();
		ForceFieldComp.TakeDamage(1.0, Owner.ActorLocation, Owner);
		ForceFieldComp.SetIntegrity(0.0);
		ForceFieldComp.UpdateVisuals(0.1); // fake deltatime
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsCapabilityTagBlocked(n"IslandForceField"))
			return false;
		if (!ForceFieldComp.IsEnabled())
			return false;
		if (!FakePunchotron.bIsForceFieldActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FakePunchotron.bIsForceFieldActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		ForceFieldComp.AddComponentVisualsBlocker(this);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets.
	}

	bool bHasStartedReplenishing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < FakePunchotron.ForceFieldActivationDelay)
		 	return;
		if (!bHasStartedReplenishing)
		{
			bHasStartedReplenishing = true;
			ForceFieldComp.SetIntegrity(0.01);
			ForceFieldComp.RemoveComponentVisualsBlocker(this);
			BulletReflectComp.RemoveReflectBlockerForBothPlayers(Owner); // Start reflecting bullets if previously blocked.
		}
		
		ForceFieldComp.Replenish(FakePunchotron.ForceFieldActivationAlphaPerSecond * DeltaTime);

		ForceFieldComp.UpdateVisuals(DeltaTime);
	}

}