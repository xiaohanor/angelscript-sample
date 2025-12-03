class USummitDecimatorSpikeBombRotateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"Rotate");

	default TickGroup = EHazeTickGroup::Movement;
	
	UHazeActorRespawnableComponent RespawnComp;
	AAISummitDecimatorSpikeBomb SpikeBomb;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		SpikeBomb = Cast<AAISummitDecimatorSpikeBomb>(Owner);		
	}

	UFUNCTION()
	private void Reset()
	{
		SpikeBomb.MeshMetal.SetRelativeRotation(FRotator::ZeroRotator);
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
	void TickActive(float DeltaTime)
	{
		float RotationSpeed = 720;
		SpikeBomb.MeshMetal.AddLocalRotation(FRotator(0, RotationSpeed, 0) * DeltaTime);
	}
};