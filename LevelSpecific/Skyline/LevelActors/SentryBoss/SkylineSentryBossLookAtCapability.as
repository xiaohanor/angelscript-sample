class USkylineSentryBossLookAtCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASKylineSentryBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASKylineSentryBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.Target == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.Target == nullptr)
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

	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = Boss.Target.ActorLocation - Boss.ActorLocation;

		FQuat Rotation = FQuat::Slerp(Boss.ActorQuat, FQuat::MakeFromZ(ToTarget), 5 * DeltaTime);
		Boss.ActorRotation = Rotation.Rotator();
		//Boss.AddActorLocalRotation(FRotator(0, 20 * DeltaTime, 0));
	}	


};