class UIslandJetpackShieldotronTiltCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	//default TickGroup = EHazeTickGroup::BeforeMovement;

	AAIIslandJetpackShieldotron JetpackShieldotron;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackShieldotron = Cast<AAIIslandJetpackShieldotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Degrees = Math::GetMappedRangeValueClamped(FVector2D(20, 600), FVector2D(0, 10), JetpackShieldotron.ActorVelocity.Size2D());		
		JetpackShieldotron.Mesh.SetWorldRotation(FRotator::MakeFromXZ(JetpackShieldotron.ActorForwardVector, JetpackShieldotron.ActorUpVector.RotateTowards(JetpackShieldotron.ActorVelocity.GetSafeNormal(), Degrees)));
		JetpackShieldotron.ForceFieldComp.SetWorldRotation(FRotator::MakeFromXZ(JetpackShieldotron.ActorForwardVector, JetpackShieldotron.ActorUpVector.RotateTowards(JetpackShieldotron.ActorVelocity.GetSafeNormal(), Degrees)));
	}
};