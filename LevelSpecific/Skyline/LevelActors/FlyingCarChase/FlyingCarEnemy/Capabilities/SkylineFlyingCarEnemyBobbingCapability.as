class USkylineFlyingCarEnemyBobbingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineFlyingCarEnemy FlyingCarEnemy;
	
	float BobHeight = 150.0;
	float BobSpeed = 2.0;
	private float BobOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);

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
		BobOffset = Math::RandRange(0.1, 3);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FlyingCarEnemy.VisualRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
	}
};